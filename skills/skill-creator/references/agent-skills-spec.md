# Agent Skills specification (open standard, agentskills.io)

Source: https://agentskills.io/specification — condensed and reorganized for authoring use. Re-fetch the source if this drifts.

## Directory structure

A skill is a directory containing, at minimum, a `SKILL.md` file:

```text
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/           # Optional: executable code
├── references/        # Optional: documentation
├── assets/             # Optional: templates, resources
└── ...                 # Any additional files or directories
```

## `SKILL.md` format

YAML frontmatter, then Markdown body.

### Frontmatter fields

| Field           | Required | Constraints |
| --------------- | -------- | ----------- |
| `name`          | Yes | Max 64 chars. Lowercase unicode letters, numbers, hyphens only. No leading/trailing hyphen. No consecutive hyphens. Must match the parent directory name. |
| `description`   | Yes | Max 1024 chars, non-empty. Must describe what the skill does *and* when to use it. |
| `license`       | No | License name or reference to a bundled license file. |
| `compatibility` | No | Max 500 chars. Environment requirements (product, system packages, network access). Most skills don't need this. |
| `metadata`      | No | Map of string → string. Arbitrary extra data. Use unique-ish key names to avoid collisions. |
| `allowed-tools` | No | Space-separated string of pre-approved tools. Experimental; support varies by client. |

These six fields are the entire portable surface. Anything else is a client extension (see `claude-code-extensions.md` for Claude Code's).

#### `name` — exact rules
- 1–64 characters
- unicode lowercase alphanumeric (`a-z`, `0-9`) and hyphens (`-`) only
- must not start or end with `-`
- must not contain `--`
- must equal the parent directory name exactly

Valid: `pdf-processing`, `data-analysis`, `code-review`
Invalid: `PDF-Processing` (case), `-pdf` (leading hyphen), `pdf--processing` (consecutive hyphens)

#### `description` — exact rules
- 1–1024 characters
- should state both *what* the skill does and *when* to use it
- should include concrete keywords a task-matcher would key on

Good: "Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction."
Poor: "Helps with PDFs."

#### `license`
Keep short — a license name, or "see LICENSE.txt".

#### `compatibility`
Only add if the skill has real environment requirements, e.g.:
- `Designed for Claude Code (or similar products)`
- `Requires git, docker, jq, and access to the internet`
- `Requires Python 3.14+ and uv`

#### `metadata`
```yaml
metadata:
  author: example-org
  version: "1.0"
```
Client-defined use; not acted on by the spec itself.

#### `allowed-tools`
```yaml
allowed-tools: Bash(git:*) Bash(jq:*) Read
```
Experimental — pre-approves specific tools so the skill doesn't trigger a permission prompt.

### Body content
No mandated format. Recommended sections: step-by-step instructions, input/output examples, common edge cases. The full body loads into context once the skill activates — so split anything long into `references/` and link to it rather than inlining it.

## Optional directories

### `scripts/`
Executable code the agent can run. Should be self-contained or clearly document dependencies, include helpful error messages, and handle edge cases gracefully. Language support depends on the client (Python/Bash/JS are common).

### `references/`
Additional docs loaded on demand — `REFERENCE.md`, `FORMS.md`, or domain-specific files (`finance.md`, `legal.md`). Keep each file focused; smaller files cost less context when loaded.

### `assets/`
Static resources: templates, images, data files/schemas.

## Progressive disclosure (why the structure matters)

1. **Metadata (~100 tokens)** — `name` + `description` loaded for *every* skill at startup, regardless of relevance.
2. **Instructions (<5000 tokens recommended)** — full `SKILL.md` body loaded only once the skill activates.
3. **Resources (as needed)** — files under `scripts/`, `references/`, `assets/` loaded only when the instructions tell the agent to load them.

Design consequence: a bloated `description` costs every session; a bloated `SKILL.md` body costs every activation; bloated reference files cost only when actually pulled in. Push detail as far down that chain as it will go.

**Keep `SKILL.md` under 500 lines.**

## File references

Use relative paths from the skill root:
```markdown
See [the reference guide](references/REFERENCE.md) for details.
Run the extraction script:
scripts/extract.py
```
Keep references one level deep from `SKILL.md` — avoid reference chains (a reference file that itself points to another reference file).

## Validation

Reference implementation: https://github.com/agentskills/agentskills/tree/main/skills-ref
```bash
skills-ref validate ./my-skill
```
Checks frontmatter validity and naming conventions. Not installed by default in this repo — treat `references/checklist.md` as the manual equivalent when the CLI isn't available.
