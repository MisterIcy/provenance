# Conventional Commits cheat sheet

Condensed from the [Conventional Commits 1.0.0 spec](https://www.conventionalcommits.org/en/v1.0.0/). Every commit produced by this skill must follow this shape.

## Format

```
<type>[optional scope][!]: <subject>

[optional body]

[optional footer(s)]
```

## Header rules

- `type` — lowercase, one of the list below.
- `scope` — optional, lowercase, parenthesized, names the affected area (`(auth)`, `(parser)`, `(skills)`). Omit if the change isn't scoped to one area.
- `!` right after the type/scope — marks a breaking change (also requires a `BREAKING CHANGE:` footer).
- `subject` — imperative mood ("add", not "added"/"adds"), no trailing period, ideally ≤ 72 chars including the `type(scope): ` prefix.

## Types

| Type | Use for |
| --- | --- |
| `feat` | a new capability visible to users of the code |
| `fix` | a bug fix |
| `docs` | documentation only |
| `style` | formatting, whitespace, no logic change |
| `refactor` | code change that neither fixes a bug nor adds a feature |
| `perf` | a change that improves performance |
| `test` | adding or correcting tests |
| `build` | build system or external dependencies |
| `ci` | CI configuration/scripts |
| `chore` | maintenance that doesn't fit elsewhere (tooling, config) |
| `revert` | reverts a previous commit |

Pick the type that matches what the diff actually does, not what the ticket says.

## Body rules

- Blank line between subject and body.
- Wrap prose at ~72 columns.
- Explain *what changed and why*, not a line-by-line narration of the diff — the diff itself already shows "what"; the body earns its place by adding the "why" a reviewer can't get from the code.
- No filler ("this commit...", "in this change we..."), no marketing adjectives, no restating the subject line.
- Plain language a developer on this project would actually use — match the register of the codebase, not a press release.
- Multiple unrelated points → bullet list, one point each.

## Footers

- `BREAKING CHANGE: <description>` — required alongside `!` in the header.
- `Fixes #123`, `Refs #123` — issue references, only if the change is clearly tied to one (don't invent references).

## Examples

Good:
```
fix(parser): handle trailing commas in array literals

The tokenizer treated a trailing comma before `]` as a syntax error.
Skip a comma that is immediately followed by a closing bracket.
```

Bad (vague type, narrates the diff, filler):
```
chore: update stuff

This commit updates the parser.js file to fix an issue with commas.
```

## Splitting changes into commits

One commit = one reviewable idea. Split when:
- Files serve genuinely different purposes (e.g. a bug fix and an unrelated refactor).
- A behavior change and its test are fine together — tests for the same change stay with the change.
- Formatting-only churn should be its own `style`/`chore` commit, separate from logic changes, unless it's inseparable from the edit (e.g. a renamed variable touched every call site).

Don't split when:
- Files are mechanically coupled (an interface and its only implementation changing together).
- Splitting would leave an intermediate commit that doesn't build or doesn't make sense on its own.
