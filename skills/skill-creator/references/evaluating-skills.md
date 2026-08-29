# Evaluating skill output quality

Source: https://agentskills.io/skill-creation/evaluating-skills — condensed. Re-fetch the source if this drifts.

Optional, but the recommended way to check a new or changed skill actually improves outcomes rather than just looking right on one manual try.

## Test cases: `evals/evals.json`

Each skill's own `evals/evals.json` holds test cases:

```json
{
  "skill_name": "my-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "a realistic user message, in their voice",
      "expected_output": "human-readable description of what success looks like",
      "files": ["evals/files/some-input.csv"],
      "assertions": [
        "objectively verifiable statement about the output",
        "another one"
      ]
    }
  ]
}
```

- Start with 2-3 cases; expand later.
- Vary phrasing (casual vs. precise) and cover at least one edge case (malformed input, ambiguous request).
- Use realistic, specific prompts — "process this data" tests nothing.
- Write `prompt` + `expected_output` first; add `assertions` only after seeing a first run's actual output — don't guess pass/fail checks blind.
- Good assertion: specific, countable, checkable from the output alone ("the output includes a bar chart image file"). Weak: vague ("the output is good") or brittle (exact wording match).
- Not everything needs an assertion — style/polish/"feels right" is better caught by human review than forced into a pass/fail check.

## Running an eval loop

Run each test case twice: **with the skill** and **without it** (or against a previous version, for regressions). Isolate each run — fresh context, no leftover state — so it only follows what `SKILL.md` says. In Claude Code, a subagent per run gives this isolation naturally.

Workspace layout (sibling to the skill, not inside it):

```
<skill>-workspace/iteration-1/
├── eval-<case-slug>/
│   ├── with_skill/{outputs/, timing.json, grading.json}
│   └── without_skill/{outputs/, timing.json, grading.json}
└── benchmark.json
```

- `timing.json`: `{"total_tokens": N, "duration_ms": N}` — capture immediately, it isn't persisted elsewhere.
- `grading.json`: each assertion graded PASS/FAIL with concrete evidence (quote/reference the output, not an opinion). Use a verification script for mechanically-checkable assertions (valid JSON, file exists, exit code) — more reliable and reusable than LLM judgment for those.
- `benchmark.json`: aggregate pass rate / time / tokens per configuration, plus the `with_skill` − `without_skill` delta — what the skill costs vs. what it buys.

## Iterating

1. Grade every case; note failed assertions, add human `feedback.json` per case for anything not objectively checkable.
2. Look for assertions that always pass (useless, remove) or always fail (broken assertion or genuinely hard case) in both configurations — those aren't testing the skill.
3. Feed failed assertions + human feedback + execution transcripts + current `SKILL.md` to an LLM and ask for proposed changes. Prefer reasoning-based instructions ("do X because Y") over rigid rules, and keep the skill lean — don't patch narrowly for one test case.
4. Re-run in a new `iteration-<N+1>/`, re-grade, re-review. Stop when feedback is consistently empty or gains plateau.
