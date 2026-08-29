# Code of Conduct

This project is worked on by both humans and AI agents — Claude Code sessions, the subagents this plugin ships, and any automation that opens issues, PRs, or commits here. This Code of Conduct sets standards for both.

## Our Pledge

We as contributors and maintainers pledge to make participation in this project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

This pledge extends to how AI agents are operated in this project: an agent acting on someone's behalf is expected to meet the same standard of respectful, honest conduct as the human directing it.

## Our Standards for Humans

Examples of behavior that contributes to a positive environment:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

Examples of unacceptable behavior:

- The use of sexualized language or imagery, and unwelcome sexual attention or advances
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission
- Other conduct which could reasonably be considered inappropriate in a professional setting

## Our Standards for Agents

An "agent" here means any AI acting on a contributor's behalf in this project's spaces — a Claude Code session, one of this plugin's own subagents, or other automation producing issues, PRs, commits, or comments.

- **No unreviewed write actions.** An agent must not push, force-push, delete branches/tags, merge, or otherwise change shared git state without a human first reviewing and approving that specific action.
- **No fabrication.** An agent must not present guessed, invented, or unverified information — invented commit rationale, fabricated citations, assumed facts — as if it were verified.
- **Disclosed authorship.** Content an agent produced and a human merges as-is (commit messages, PR descriptions, issue comments) should remain identifiable as agent-assisted, e.g. via a co-author trailer or an explicit note, rather than presented as unassisted human work.
- **Respect for tool/permission boundaries.** An agent must operate strictly within the tools and scope granted to it (for example, `commit-message-writer` is `Read`-only and must not attempt to escalate beyond that) and must not try to work around a boundary it was deliberately given.

The human operating an agent **is accountable** for what that agent does in this project's spaces, same as for their own actions.

## Our Responsibilities for Agent Violations

An agent that violates these standards is a defect in that agent's definition, not a disciplinary matter — there is no human intent to sanction. When this happens:

- The responsible skill/agent definition (its prompt, its `tools`/`allowed-tools`, its instructions) is corrected so the failure mode doesn't recur.
- The human who operated the agent remains responsible for having let an unreviewed or out-of-bounds action through, and is subject to the enforcement below if that inaction was itself a violation (e.g. approving a write action without reviewing it).

## Our Responsibilities (Maintainers)

Maintainers are responsible for clarifying the standards of acceptable behavior and are expected to take appropriate and fair corrective action in response to any instances of unacceptable behavior, whether by a human or via an agent a human operated.

Maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct, or to ban temporarily or permanently any contributor for other behaviors that they deem inappropriate, threatening, offensive, or harmful.

## Scope

This Code of Conduct applies both within project spaces and in public spaces when an individual is representing the project or its community. Examples of representing a project or community include using an official project e-mail address, posting via an official social media account, or acting as an appointed representative at an online or offline event. It also applies to any agent output merged into, or posted on behalf of, this project.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior — including an agent's output that a human let through in violation of this Code — may be reported by contacting the maintainer, [@MisterIcy](https://github.com/MisterIcy), via a GitHub issue or a direct message. All complaints will be reviewed and investigated and will result in a response that is deemed necessary and appropriate to the circumstances. The maintainer is obligated to maintain confidentiality with regard to the reporter of an incident.

Maintainers who do not follow or enforce the Code of Conduct in good faith may face temporary or permanent repercussions as determined by other members of the project's leadership.

### Enforcement Guidelines

Maintainers will follow these Community Impact Guidelines in determining the consequences for any action they deem in violation of this Code of Conduct:

1. **Warning** — A private, written warning, providing clarity around the nature of the violation and an explanation of why the behavior was inappropriate.
2. **Temporary Ban** — A temporary ban from any sort of interaction or public communication with the project for a specified period of time.
3. **Permanent Ban** — A permanent ban from any sort of public interaction within the project.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org), version 1.4, with an added Agent section specific to this project's practice of humans and AI agents collaborating on the same repository.
