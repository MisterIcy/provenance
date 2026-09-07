#!/usr/bin/env python3
"""Shared PreToolUse gate for `git commit` / `git push`.

Reads the hook payload from stdin, tokenizes tool_input.command (handling
compound commands, quoting, and git global options like -C/-c), and decides
whether it invokes the given git subcommand. Fails open (exits 0, no output,
letting the normal permission flow apply) on a malformed/missing payload
instead of crashing the hook and blocking unrelated Bash calls. A command
string that itself fails to tokenize (e.g. unbalanced quotes) is treated as
a match instead, so the gate still asks rather than silently allowing.

Usage: git_guard.py <subcommand> <PLUGIN_OPTION_ENV_VAR>
"""
import json
import os
import re
import shlex
import sys

ENV_ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
CONTROL_OPERATORS = {";", "&", "&&", "||", "|", "(", ")"}
GLOBAL_OPTS_WITH_ARG = {
    "-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path",
}


def split_segments(line):
    lexer = shlex.shlex(line, posix=True, punctuation_chars="();<>|&")
    lexer.whitespace_split = True
    segment = []
    for token in lexer:
        if token in CONTROL_OPERATORS or token in {"<", ">"}:
            if segment:
                yield segment
            segment = []
        else:
            segment.append(token)
    if segment:
        yield segment


def find_subcommand(tokens):
    i, n = 0, len(tokens)
    while i < n and ENV_ASSIGNMENT.match(tokens[i]):
        i += 1
    if i >= n or os.path.basename(tokens[i]) != "git":
        return None
    i += 1
    while i < n:
        tok = tokens[i]
        if tok == "--":
            i += 1
            break
        if tok in GLOBAL_OPTS_WITH_ARG:
            i += 2
            continue
        if tok.startswith("-") and tok != "-":
            i += 1
            continue
        break
    return tokens[i] if i < n else None


def command_invokes(command_str, subcommand):
    for line in command_str.splitlines():
        try:
            segments = list(split_segments(line))
        except ValueError:
            # Unbalanced quotes etc. - be conservative and treat as a match
            # so the gate still asks rather than silently allowing.
            return True
        for segment in segments:
            if find_subcommand(segment) == subcommand:
                return True
    return False


def main():
    if len(sys.argv) != 3:
        return 0
    subcommand, option_env_var = sys.argv[1], sys.argv[2]

    try:
        payload = json.load(sys.stdin)
        command_str = payload.get("tool_input", {}).get("command", "")
    except Exception:
        return 0

    if not command_str or not isinstance(command_str, str):
        return 0

    try:
        matched = command_invokes(command_str, subcommand)
    except Exception:
        matched = True  # fail closed on the tokenizer, not on the payload

    if not matched:
        return 0

    plural = {"commit": "commits", "push": "pushes"}.get(subcommand, subcommand + "s")
    if os.environ.get(option_env_var, "false") == "true":
        decision, reason = "allow", f"{option_env_var} is enabled"
    else:
        decision, reason = "ask", f"{option_env_var} is off — {plural} require explicit approval"

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
