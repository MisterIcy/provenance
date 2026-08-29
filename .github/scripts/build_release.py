#!/usr/bin/env python3
"""Build a Keep-a-Changelog entry and release notes from PRs merged into a milestone.

Reads merged-PR data (as produced by `gh pr list --json number,title,url,author,labels`)
from PRS_JSON_PATH, groups PR titles by Conventional Commits type, rewrites CHANGELOG.md
in place, and writes plain release notes to NOTES_OUT_PATH for `gh release create`.
"""
import json
import os
import re
import sys
from datetime import date

VERSION = os.environ["RELEASE_VERSION"]  # e.g. "0.2.0" (no leading v)
REPO = os.environ["GITHUB_REPOSITORY"]  # e.g. "MisterIcy/provenance"
PRS_JSON_PATH = os.environ["PRS_JSON_PATH"]
CHANGELOG_PATH = os.environ.get("CHANGELOG_PATH", "CHANGELOG.md")
NOTES_OUT_PATH = os.environ["NOTES_OUT_PATH"]

TAG = f"v{VERSION}"

CONVENTIONAL_RE = re.compile(
    r"^(?P<type>\w+)(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?:\s*(?P<desc>.+)$"
)

# Conventional commit type -> Keep a Changelog category. Types absent from this
# map (chore, ci, test, style, build, ...) are treated as not user-facing and
# excluded from the changelog, though they still appear in the release notes' PR list.
TYPE_TO_CATEGORY = {
    "feat": "Added",
    "fix": "Fixed",
    "perf": "Changed",
    "refactor": "Changed",
    "docs": "Changed",
    "revert": "Changed",
}

CATEGORY_ORDER = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"]


def load_prs():
    with open(PRS_JSON_PATH) as f:
        return json.load(f)


def categorize(prs):
    buckets = {c: [] for c in CATEGORY_ORDER}
    for pr in prs:
        title = pr["title"].strip()
        match = CONVENTIONAL_RE.match(title)
        breaking = any(l["name"].lower() == "breaking" for l in pr.get("labels", []))
        if match:
            ctype = match.group("type").lower()
            desc = match.group("desc").strip()
            scope = match.group("scope")
            breaking = breaking or bool(match.group("breaking"))
            category = TYPE_TO_CATEGORY.get(ctype)
            if category is None:
                continue
            entry = desc[0].upper() + desc[1:] if desc else title
            if scope:
                entry = f"**{scope}:** {entry}"
        else:
            category = "Changed"
            entry = title

        suffix = f" ([#{pr['number']}]({pr['url']}))"
        if breaking:
            entry = f"**BREAKING:** {entry}"
        buckets[category].append(entry + suffix)
    return buckets


def render_changelog_section(buckets):
    lines = [f"## [{VERSION}] - {date.today().isoformat()}", ""]
    any_entries = False
    for category in CATEGORY_ORDER:
        entries = buckets[category]
        if not entries:
            continue
        any_entries = True
        lines.append(f"### {category}")
        lines.extend(f"- {entry}" for entry in entries)
        lines.append("")
    if not any_entries:
        lines.append("_No notable changes recorded for this release._")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def update_changelog(section_text):
    with open(CHANGELOG_PATH) as f:
        lines = f.readlines()

    header_re = re.compile(r"^## \[Unreleased\]\s*$")
    next_header_re = re.compile(r"^## \[")

    start = next((i for i, l in enumerate(lines) if header_re.match(l)), None)
    if start is None:
        raise SystemExit("Could not find an '## [Unreleased]' section in CHANGELOG.md")

    end = next(
        (i for i in range(start + 1, len(lines)) if next_header_re.match(lines[i])),
        len(lines),
    )
    unreleased_body = "".join(lines[start + 1 : end]).strip("\n")

    new_unreleased = "## [Unreleased]\n\n"
    insertion = f"{new_unreleased}{section_text}\n"
    if unreleased_body:
        # Preserve any hand-written Unreleased notes ahead of the generated section.
        insertion = f"{new_unreleased}{unreleased_body}\n\n{section_text}\n"

    content = "".join(lines[:start]) + insertion + "".join(lines[end:])
    content = strip_compare_links(content)
    content += render_compare_links(content)

    with open(CHANGELOG_PATH, "w") as f:
        f.write(content)


LINK_RE = re.compile(r"^\[(Unreleased|[0-9][^\]]*)\]:\s*\S+$", re.MULTILINE)


def strip_compare_links(content):
    return LINK_RE.sub("", content).rstrip("\n") + "\n"


def render_compare_links(content):
    versions = re.findall(r"^## \[([0-9][^\]]*)\]", content, re.MULTILINE)
    lines = ["\n"]
    if versions:
        lines.append(f"[Unreleased]: https://github.com/{REPO}/compare/v{versions[0]}...HEAD\n")
    else:
        lines.append(f"[Unreleased]: https://github.com/{REPO}/commits/main\n")
    for i, v in enumerate(versions):
        if i + 1 < len(versions):
            prev = versions[i + 1]
            lines.append(f"[{v}]: https://github.com/{REPO}/compare/v{prev}...v{v}\n")
        else:
            lines.append(f"[{v}]: https://github.com/{REPO}/releases/tag/v{v}\n")
    return "".join(lines)


def write_release_notes(section_text, prs):
    body = section_text.split("\n", 1)[1].lstrip("\n")  # drop the "## [x.y.z] - date" heading
    with open(NOTES_OUT_PATH, "w") as f:
        f.write(body)
        if not prs:
            return
        f.write("\n\n**All merged PRs in this release**\n\n")
        for pr in prs:
            f.write(f"- {pr['title']} (#{pr['number']}) by @{pr['author']['login']}\n")


def main():
    prs = load_prs()
    buckets = categorize(prs)
    section_text = render_changelog_section(buckets)
    update_changelog(section_text)
    write_release_notes(section_text, prs)


if __name__ == "__main__":
    main()
