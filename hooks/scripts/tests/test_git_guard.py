#!/usr/bin/env python3
"""Regression tests for hooks/scripts/git_guard.py.

Run directly: python3 hooks/scripts/tests/test_git_guard.py
Or via unittest discovery: python3 -m unittest discover -s hooks/scripts/tests
"""
import json
import os
import subprocess
import sys
import unittest

GUARD = os.path.join(os.path.dirname(__file__), "..", "git_guard.py")

sys.path.insert(0, os.path.dirname(GUARD))
import git_guard  # noqa: E402


def invokes(command, subcommand):
    return git_guard.command_invokes(command, subcommand)


def run_guard(command, subcommand="push", option_env_var="TEST_OPT", env=None):
    payload = json.dumps({"tool_input": {"command": command}})
    full_env = dict(os.environ)
    full_env.pop(option_env_var, None)
    if env:
        full_env.update(env)
    result = subprocess.run(
        [sys.executable, GUARD, subcommand, option_env_var],
        input=payload,
        capture_output=True,
        text=True,
        env=full_env,
    )
    return result


class CommandInvokesTests(unittest.TestCase):
    def test_plain_git_push_matches(self):
        self.assertTrue(invokes("git push origin main", "push"))

    def test_plain_git_commit_matches(self):
        self.assertTrue(invokes("git commit -m 'msg'", "commit"))

    def test_unrelated_command_does_not_match(self):
        self.assertFalse(invokes("echo hello world", "push"))
        self.assertFalse(invokes("git status", "push"))

    def test_global_options_before_subcommand(self):
        self.assertTrue(invokes("git -C repo -c user.name=x push", "push"))
        self.assertTrue(invokes("git --git-dir=/x/.git push", "push"))

    def test_compound_commands(self):
        self.assertTrue(invokes("echo hi && git push", "push"))
        self.assertTrue(invokes("git push; echo done", "push"))
        self.assertTrue(invokes("some_cmd | git push", "push"))

    def test_double_dash_stops_option_scan(self):
        # `--` only terminates git's own option parsing; the subcommand
        # that follows it is still "push".
        self.assertTrue(invokes("git -- push", "push"))

    def test_env_assignment_prefix(self):
        self.assertTrue(invokes("FOO=bar git push", "push"))

    def test_unbalanced_quotes_fail_conservative(self):
        self.assertTrue(invokes("git status \"unterminated", "push"))
        self.assertTrue(invokes("git status \"unterminated", "commit"))

    def test_docker_command_with_backslash_line_continuation_does_not_match(self):
        # Regression: a multi-line command using bash's trailing-backslash
        # line continuation must not be mistaken for a git push/commit just
        # because splitting it on raw newlines breaks shlex tokenization.
        command = (
            'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/app -w /app '
            'ghcr.io/carthage-software/mago:1.47.4 lint \\\n'
            '  libraries/Efront/Domain/JobDispatch/JobSettlementService.php \\\n'
            '  tests/Integration/Domain/JobDispatch/JobSettlementServiceTest.php '
            '2>&1 | tail -40'
        )
        self.assertFalse(invokes(command, "push"))
        self.assertFalse(invokes(command, "commit"))

    def test_line_continuation_still_detects_real_git_push(self):
        command = 'git \\\n  push origin main'
        self.assertTrue(invokes(command, "push"))


class MainCliTests(unittest.TestCase):
    def test_non_git_command_produces_no_output(self):
        result = run_guard("echo hello")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "")

    def test_git_push_asks_when_option_off(self):
        result = run_guard("git push origin main")
        self.assertEqual(result.returncode, 0)
        payload = json.loads(result.stdout)
        self.assertEqual(
            payload["hookSpecificOutput"]["permissionDecision"], "ask"
        )

    def test_git_push_allows_when_option_on(self):
        result = run_guard("git push origin main", env={"TEST_OPT": "true"})
        payload = json.loads(result.stdout)
        self.assertEqual(
            payload["hookSpecificOutput"]["permissionDecision"], "allow"
        )

    def test_docker_multiline_command_produces_no_output(self):
        command = (
            'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/app -w /app '
            'ghcr.io/carthage-software/mago:1.47.4 lint \\\n'
            '  libraries/Efront/Domain/JobDispatch/JobSettlementService.php \\\n'
            '  tests/Integration/Domain/JobDispatch/JobSettlementServiceTest.php '
            '2>&1 | tail -40'
        )
        result = run_guard(command, subcommand="push")
        self.assertEqual(result.stdout.strip(), "")
        result = run_guard(command, subcommand="commit")
        self.assertEqual(result.stdout.strip(), "")


if __name__ == "__main__":
    unittest.main()
