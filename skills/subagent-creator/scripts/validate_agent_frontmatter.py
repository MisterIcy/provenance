#!/usr/bin/env python3
"""Validate a subagent Markdown file's frontmatter against the documented
Claude Code sub-agent spec (https://code.claude.com/docs/en/sub-agents).

Requires PyYAML (pip install pyyaml).

Two modes:

  CLI mode (explicit call):
      validate_agent_frontmatter.py path/to/agent.md
    Prints a human-readable report to stdout. Exit 0 if no errors, 1 otherwise.

  Hook mode (no arguments — registered as a PostToolUse hook on Edit|Write):
    Reads the hook's JSON payload from stdin, extracts tool_input.file_path,
    and silently exits 0 unless that path looks like an agent definition
    (lives under an `agents/` directory and ends in `.md`). On a match it
    emits a JSON hookSpecificOutput.additionalContext report and:
      - exits 2 with a stderr summary if any error was found
      - exits 0 otherwise (warnings still surface via additionalContext)
"""

import json
import os
import re
import sys

NAME_RE = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
MAX_NAME = 100

KNOWN_FIELDS = {
    "name", "description", "tools", "disallowedTools", "model",
    "permissionMode", "maxTurns", "skills", "mcpServers", "hooks",
    "memory", "background", "effort", "isolation", "color",
    "initialPrompt", "experimental",
}

VALID_MODEL_ALIASES = {"sonnet", "opus", "haiku", "fable", "inherit"}
VALID_PERMISSION_MODES = {"default", "acceptEdits", "auto", "dontAsk", "bypassPermissions", "plan"}
VALID_MEMORY = {"user", "project", "local"}
VALID_EFFORT = {"low", "medium", "high", "xhigh", "max"}
VALID_COLOR = {"red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan"}
VALID_HOOK_EVENTS = {"PreToolUse", "PostToolUse", "Stop"}
VALID_HOOK_TYPES = {"command", "http", "mcp_tool", "prompt", "agent"}


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.infos = []

    def error(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)

    def info(self, msg):
        self.infos.append(msg)

    @property
    def ok(self):
        return not self.errors

    def render(self):
        lines = []
        for e in self.errors:
            lines.append(f"ERROR: {e}")
        for w in self.warnings:
            lines.append(f"WARN:  {w}")
        for i in self.infos:
            lines.append(f"INFO:  {i}")
        if not lines:
            lines.append("OK: frontmatter looks valid.")
        return "\n".join(lines)


def extract_frontmatter_block(text):
    if not text.startswith("---"):
        return None, "File does not start with '---' — no frontmatter block detected. Claude Code silently skips files like this (treated as plain docs, not an agent definition)."
    lines = text.split("\n")
    if lines[0].strip() != "---":
        return None, "First line must be exactly '---' to open the frontmatter block."
    end = None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end = i
            break
    if end is None:
        return None, "Unterminated frontmatter block: no closing '---' found."
    return "\n".join(lines[1:end]), None


def parse_frontmatter(text):
    raw, err = extract_frontmatter_block(text)
    if err:
        return None, err
    try:
        import yaml
    except ImportError:
        return None, "PyYAML is required to parse frontmatter but isn't installed. Run: pip install pyyaml"
    try:
        data = yaml.safe_load(raw)
    except Exception as e:
        return None, f"Frontmatter is not valid YAML: {e}"
    if data is None:
        data = {}
    if not isinstance(data, dict):
        return None, "Frontmatter must be a YAML mapping (key: value pairs), not a list or scalar."
    return data, None


def is_string_or_list_of_strings(v):
    if isinstance(v, str):
        return True
    if isinstance(v, list):
        return all(isinstance(x, str) for x in v)
    return False


def validate(data, report):
    # name — required; missing/invalid means Claude Code silently skips the file
    name = data.get("name")
    if name is None:
        report.error("`name` is missing. Claude Code silently skips agent files with no `name` (treated as plain documentation) — this agent will never load.")
    elif not isinstance(name, str):
        report.error(f"`name` must be a string, got {type(name).__name__}.")
    else:
        if name.startswith("-"):
            report.error("`name` cannot start with `-`.")
        if ":" in name:
            report.error("`name` cannot contain `:` — reserved for plugin-scoped identifiers (`plugin-name:agent-name`).")
        if not NAME_RE.match(name):
            report.error("`name` must be lowercase letters, digits, and single hyphens only (e.g. `code-reviewer`), no leading hyphen.")
        if len(name) > MAX_NAME:
            report.warn(f"`name` is unusually long ({len(name)} chars) — keep it short, it's used in @-mentions.")

    # description — required
    description = data.get("description")
    if description is None or (isinstance(description, str) and not description.strip()):
        report.error("`description` is missing or empty. Claude Code silently skips an agent file with a `name` but no `description` — this agent will never load, and even if it did, it's the only signal automatic delegation has.")
    elif not isinstance(description, str):
        report.error(f"`description` must be a string, got {type(description).__name__}.")
    else:
        lowered = description.lower()
        trigger_hints = ("use when", "use proactively", "use for", "use after", "use this", "invoked by", "invoked automatically", "not meant to be invoked directly")
        if not any(h in lowered for h in trigger_hints):
            report.warn("`description` doesn't contain an explicit trigger phrase (e.g. \"use when...\", \"use proactively...\"). Automatic delegation relies entirely on this field matching the task — vague descriptions mean the agent rarely fires.")

    # tools / disallowedTools
    tools = data.get("tools")
    disallowed_tools = data.get("disallowedTools")
    for field, val in (("tools", tools), ("disallowedTools", disallowed_tools)):
        if val is not None and not is_string_or_list_of_strings(val):
            report.error(f"`{field}` must be a comma-separated string or a YAML list of strings.")
    if tools is None and disallowed_tools is None:
        report.warn("Neither `tools` nor `disallowedTools` is set — this agent silently inherits every tool available to subagents. State the scope explicitly: an allowlist for a narrow-purpose agent, or at least `disallowedTools` to strip specific dangerous tools.")

    def tool_names(val):
        if val is None:
            return []
        if isinstance(val, str):
            return [t.strip() for t in re.split(r"[,\s]+", val) if t.strip()]
        return list(val)

    if any(t == "Agent" for t in tool_names(tools)):
        report.warn("`tools` grants a bare `Agent` — this allows spawning ANY subagent type. If this agent coordinates/delegates to other agents, scope it to `Agent(specific-name-1, specific-name-2)` instead.")

    # model
    model = data.get("model")
    if model is not None:
        if not isinstance(model, str):
            report.error(f"`model` must be a string, got {type(model).__name__}.")
        elif model not in VALID_MODEL_ALIASES and not model.startswith("claude-"):
            report.warn(f"`model: {model!r}` isn't a recognized alias ({sorted(VALID_MODEL_ALIASES)}) or a `claude-*` model ID — double check it's a valid model identifier.")
        elif model not in ("inherit",) and model in VALID_MODEL_ALIASES:
            pass
        elif model.startswith("claude-"):
            report.info(f"`model: {model!r}` pins a full model ID. Prefer an alias (`sonnet`/`opus`/`haiku`/`fable`) unless there's a specific reason to pin an exact model.")

    # permissionMode
    permission_mode = data.get("permissionMode")
    if permission_mode is not None and permission_mode not in VALID_PERMISSION_MODES:
        report.error(f"`permissionMode` must be one of {sorted(VALID_PERMISSION_MODES)}, got {permission_mode!r}.")

    # maxTurns
    max_turns = data.get("maxTurns")
    if max_turns is None:
        report.warn("`maxTurns` not set — the agent can run unbounded. Scale it to the job: 5 (one-shot), 10 (medium), 20+ (long/complex).")
    elif not isinstance(max_turns, int):
        report.error(f"`maxTurns` must be an integer, got {type(max_turns).__name__}.")

    # skills
    skills = data.get("skills")
    if skills is not None and not is_string_or_list_of_strings(skills):
        report.error("`skills` must be a list of skill name strings.")

    # memory — documented values are user/project/local; `false` (or omitted) disables persistent memory.
    # Always a deliberate, user-confirmed choice — never assumed. See workflow step 7.
    memory = data.get("memory")
    if memory is None:
        report.warn("`memory` not set. Don't assume no persistence is wanted — confirm with the user, then set `user`/`project`/`local`, or `false` once they've confirmed none is needed.")
    elif memory is not False and memory not in VALID_MEMORY:
        report.error(f"`memory` must be one of {sorted(VALID_MEMORY)}, or `false` to disable, got {memory!r}.")

    # background
    background = data.get("background")
    if background is not None and not isinstance(background, bool):
        report.error(f"`background` must be a boolean, got {type(background).__name__}.")

    # effort
    effort = data.get("effort")
    if effort is not None and effort not in VALID_EFFORT:
        report.error(f"`effort` must be one of {sorted(VALID_EFFORT)}, got {effort!r}.")

    # isolation
    isolation = data.get("isolation")
    if isolation is not None and isolation != "worktree":
        report.warn(f"`isolation: {isolation!r}` — the only documented value is `worktree`.")

    # color — used here as a required blast-radius signal, not purely cosmetic (see workflow step 6)
    color = data.get("color")
    if color is None:
        report.warn("`color` not set. Use it to signal blast radius: green=read-only, yellow=read+draft/write, red=destructive; blue/purple/orange/pink/cyan for special cases like coordinators.")
    elif color not in VALID_COLOR:
        report.warn(f"`color: {color!r}` isn't one of the documented values {sorted(VALID_COLOR)} — may render as default.")
    elif tools is not None:
        tool_set = set(tool_names(tools))
        has_destructive = bool(tool_set & {"Bash", "Write", "Edit", "PowerShell", "NotebookEdit"})
        if color == "green" and has_destructive:
            report.warn(f"`color: green` (read-only) but `tools` includes mutating tool(s) {sorted(tool_set & {'Bash', 'Write', 'Edit', 'PowerShell', 'NotebookEdit'})} — reconsider the color or the tool scope.")

    # mcpServers — light structural check
    mcp_servers = data.get("mcpServers")
    if mcp_servers is not None and not isinstance(mcp_servers, list):
        report.error("`mcpServers` must be a list of server name strings and/or inline server definition mappings.")

    # hooks
    hooks = data.get("hooks")
    if hooks is not None:
        if not isinstance(hooks, dict):
            report.error("`hooks` must be a mapping of event name -> list of matcher entries.")
        else:
            for event_name, entries in hooks.items():
                if event_name not in VALID_HOOK_EVENTS:
                    report.warn(f"`hooks.{event_name}` — subagents only support {sorted(VALID_HOOK_EVENTS)}.")
                if not isinstance(entries, list):
                    report.error(f"`hooks.{event_name}` must be a list.")
                    continue
                for entry in entries:
                    if not isinstance(entry, dict) or "hooks" not in entry:
                        report.error(f"`hooks.{event_name}` entries must be mappings with a `hooks` list.")
                        continue
                    for h in entry.get("hooks", []):
                        if not isinstance(h, dict) or h.get("type") not in VALID_HOOK_TYPES:
                            report.error(f"`hooks.{event_name}` handler is missing a valid `type` (one of {sorted(VALID_HOOK_TYPES)}).")
            report.info("`hooks` at project scope (`.claude/agents/`) requires workspace trust to take effect.")

    if data.get("mcpServers") is not None:
        report.info("`mcpServers` at project scope (`.claude/agents/`) requires workspace trust to take effect.")

    # unknown keys
    for key in data:
        if key not in KNOWN_FIELDS:
            report.warn(f"Unknown frontmatter key `{key}` — not part of the documented sub-agent spec. Typo?")


def validate_file(path):
    report = Report()
    if not os.path.isfile(path):
        report.error(f"File not found: {path}")
        return report
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except OSError as e:
        report.error(f"Could not read {path}: {e}")
        return report

    data, err = parse_frontmatter(text)
    if err:
        report.error(err)
        return report

    validate(data, report)
    return report


def run_cli(path):
    report = validate_file(path)
    print(report.render())
    sys.exit(0 if report.ok else 1)


def looks_like_agent_file(file_path):
    if not file_path.endswith(".md"):
        return False
    parts = file_path.replace(os.sep, "/").split("/")
    return "agents" in parts


def run_hook():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # malformed hook payload — fail open, never break the edit

    file_path = (payload.get("tool_input") or {}).get("file_path")
    if not file_path or not looks_like_agent_file(file_path):
        sys.exit(0)

    report = validate_file(file_path)
    if not report.errors and not report.warnings:
        sys.exit(0)

    context = f"subagent-creator frontmatter check for {file_path}:\n{report.render()}"
    print(json.dumps({"hookSpecificOutput": {"additionalContext": context}}))
    if report.errors:
        print(context, file=sys.stderr)
        sys.exit(2)
    sys.exit(0)


def main():
    if len(sys.argv) > 1:
        run_cli(sys.argv[1])
    else:
        run_hook()


if __name__ == "__main__":
    main()
