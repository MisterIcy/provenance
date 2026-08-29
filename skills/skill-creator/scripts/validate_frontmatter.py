#!/usr/bin/env python3
"""Validate a SKILL.md file's frontmatter against the agentskills.io spec and
Claude Code's documented extension fields.

Requires PyYAML (pip install pyyaml) to parse the frontmatter block.

Two modes:

  CLI mode (explicit call, e.g. from the skill-creator workflow):
      validate_frontmatter.py path/to/SKILL.md
    Prints a full human-readable report (errors + warnings) to stdout.
    Exit 0 if no errors, 1 if any error was found.

  Hook mode (no arguments — registered as a PostToolUse hook on Edit|Write):
    Reads the hook's JSON payload from stdin, extracts tool_input.file_path,
    and silently exits 0 unless that path is a SKILL.md file. On a SKILL.md
    file it emits a JSON hookSpecificOutput.additionalContext report and:
      - exits 2 with a stderr summary if any error was found (PostToolUse
        doesn't block on exit 2 since the edit already happened, but Claude
        Code shows the stderr to Claude so it can self-correct)
      - exits 0 otherwise (warnings still surface via additionalContext,
        without the noisier exit-2 path)
"""

import json
import os
import re
import sys

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_NAME = 64
MAX_DESCRIPTION = 1024
MAX_COMBINED_LISTING = 1536
MAX_COMPATIBILITY = 500

SPEC_FIELDS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}

CC_EXTENSION_FIELDS = {
    "when_to_use", "argument-hint", "arguments", "disable-model-invocation",
    "user-invocable", "disallowed-tools", "model", "effort", "context",
    "agent", "background", "hooks", "paths", "shell",
}

KNOWN_FIELDS = SPEC_FIELDS | CC_EXTENSION_FIELDS

BOOLISH = {"true", "false", "yes", "no", "on", "off", "1", "0"}
VALID_EFFORT = {"low", "medium", "high", "xhigh", "max"}
VALID_SHELL = {"bash", "powershell"}
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
    """Return (raw_yaml_text, error) without importing yaml yet."""
    if not text.startswith("---"):
        return None, "File does not start with '---' — no frontmatter block detected (Claude Code will treat the whole file as body content with no description to match on)."
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
    except Exception as e:  # yaml.YAMLError plus anything else yaml raises
        return None, f"Frontmatter is not valid YAML: {e}"
    if data is None:
        data = {}
    if not isinstance(data, dict):
        return None, "Frontmatter must be a YAML mapping (key: value pairs), not a list or scalar."
    return data, None


def is_boolish(v):
    if isinstance(v, bool):
        return True
    if isinstance(v, str):
        return v.strip().lower() in BOOLISH
    return False


def is_string_or_list_of_strings(v):
    if isinstance(v, str):
        return True
    if isinstance(v, list):
        return all(isinstance(x, str) for x in v)
    return False


def validate(data, skill_dir_name, report):
    # name
    name = data.get("name")
    if name is None:
        report.warn("`name` is missing. Claude Code falls back to the directory name, but the open agentskills.io spec requires it explicitly for portability.")
    else:
        if not isinstance(name, str):
            report.error(f"`name` must be a string, got {type(name).__name__}.")
        else:
            if not (1 <= len(name) <= MAX_NAME):
                report.error(f"`name` must be 1-{MAX_NAME} characters, got {len(name)}.")
            if not NAME_RE.match(name):
                report.error("`name` must be lowercase unicode alphanumerics and single hyphens only, no leading/trailing/double hyphen (e.g. `pdf-processing`).")
            if skill_dir_name is not None and name != skill_dir_name:
                report.error(f"`name` ({name!r}) must match the parent directory name exactly ({skill_dir_name!r}).")

    # description
    description = data.get("description")
    if description is None or (isinstance(description, str) and not description.strip()):
        report.error("`description` is missing or empty. It's how Claude decides when to activate the skill.")
    elif not isinstance(description, str):
        report.error(f"`description` must be a string, got {type(description).__name__}.")
    elif len(description) > MAX_DESCRIPTION:
        report.error(f"`description` must be at most {MAX_DESCRIPTION} characters, got {len(description)}.")

    when_to_use = data.get("when_to_use")
    if when_to_use is not None:
        if not isinstance(when_to_use, str):
            report.error(f"`when_to_use` must be a string, got {type(when_to_use).__name__}.")
        elif isinstance(description, str):
            combined = len(description) + len(when_to_use)
            if combined > MAX_COMBINED_LISTING:
                report.warn(f"`description` + `when_to_use` is {combined} chars; Claude Code truncates the combined text at {MAX_COMBINED_LISTING} in the skill listing. Front-load the key use case.")

    # license
    license_ = data.get("license")
    if license_ is not None and not isinstance(license_, str):
        report.error(f"`license` must be a string, got {type(license_).__name__}.")

    # compatibility
    compatibility = data.get("compatibility")
    if compatibility is not None:
        if not isinstance(compatibility, str):
            report.error(f"`compatibility` must be a string, got {type(compatibility).__name__}.")
        elif len(compatibility) > MAX_COMPATIBILITY:
            report.error(f"`compatibility` must be at most {MAX_COMPATIBILITY} characters, got {len(compatibility)}.")

    # metadata
    metadata = data.get("metadata")
    if metadata is not None:
        if not isinstance(metadata, dict):
            report.error("`metadata` must be a YAML mapping; Claude Code silently drops it otherwise.")
        else:
            for k, v in metadata.items():
                if isinstance(v, (dict, list)):
                    report.warn(f"`metadata.{k}` is not a flat scalar value — keep `metadata` a flat string-to-string map.")

    # allowed-tools / disallowed-tools
    for field in ("allowed-tools", "disallowed-tools"):
        val = data.get(field)
        if val is not None and not is_string_or_list_of_strings(val):
            report.error(f"`{field}` must be a space/comma-separated string or a YAML list of strings.")

    # boolean-ish fields
    for field in ("disable-model-invocation", "user-invocable"):
        val = data.get(field)
        if val is not None and not is_boolish(val):
            report.error(f"`{field}` must be a boolean-ish value (true/false/yes/no/on/off/1/0), got {val!r}.")

    # context / agent / background
    context = data.get("context")
    if context is not None and context != "fork":
        report.warn(f"`context: {context!r}` — the only documented value is `fork`.")
    if data.get("agent") is not None and context != "fork":
        report.warn("`agent` is set but `context: fork` isn't — `agent` only applies when the skill runs in a forked subagent.")
    background = data.get("background")
    if background is not None:
        if not is_boolish(background):
            report.error(f"`background` must be a boolean-ish value, got {background!r}.")
        if context != "fork":
            report.warn("`background` is set but `context: fork` isn't — `background` only applies with `context: fork`.")

    # effort
    effort = data.get("effort")
    if effort is not None and effort not in VALID_EFFORT:
        report.error(f"`effort` must be one of {sorted(VALID_EFFORT)}, got {effort!r}.")

    # shell
    shell = data.get("shell")
    if shell is not None and shell not in VALID_SHELL:
        report.error(f"`shell` must be one of {sorted(VALID_SHELL)}, got {shell!r}.")

    # arguments / paths
    for field in ("arguments", "paths"):
        val = data.get(field)
        if val is not None and not is_string_or_list_of_strings(val):
            report.error(f"`{field}` must be a string or a YAML list of strings.")

    # hooks (light structural check — not a full hook-schema validator)
    hooks = data.get("hooks")
    if hooks is not None:
        if not isinstance(hooks, dict):
            report.error("`hooks` must be a mapping of event name -> list of matcher entries.")
        else:
            for event_name, entries in hooks.items():
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

    # unknown keys
    for key in data:
        if key not in KNOWN_FIELDS:
            report.warn(f"Unknown frontmatter key `{key}` — typo, or should it be under `metadata:` instead?")

    # portability note
    extras_used = sorted(k for k in data if k in CC_EXTENSION_FIELDS)
    if extras_used:
        report.info(f"Uses Claude Code-only field(s): {', '.join(extras_used)}. Fine if this skill is Claude-Code-only; remove them if it must also work on claude.ai / the Skills API / other agentskills.io clients.")


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

    skill_dir_name = os.path.basename(os.path.dirname(os.path.abspath(path))) or None
    validate(data, skill_dir_name, report)
    return report


def run_cli(path):
    report = validate_file(path)
    print(report.render())
    sys.exit(0 if report.ok else 1)


def run_hook():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # malformed hook payload — fail open, never break the edit

    file_path = (payload.get("tool_input") or {}).get("file_path")
    if not file_path or os.path.basename(file_path) != "SKILL.md":
        sys.exit(0)

    report = validate_file(file_path)
    if not report.errors and not report.warnings:
        sys.exit(0)

    context = f"skill-creator frontmatter check for {file_path}:\n{report.render()}"
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
