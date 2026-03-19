# AGENTS.md

Instructions for AI agents working in this repository.

## Project Overview

`engineering-leaders` is a Claude Code plugin providing a virtual engineering
leadership team. It ships eight leadership agents (Chief Architect, Product
Owner, UX Strategist, Agile Coach, DevOps Lead, Engineering Manager, QA Lead,
Tech Lead) and fifteen skills covering the full SDLC: requirement refinement,
story/epic/ADR/runbook authoring, retrospectives, postmortems, and more.

The plugin is installed into other projects. Development work happens here;
consumer projects install it from the marketplace or a local path.

## Repository Layout

```
agents/     One .md file per agent (frontmatter + body)
skills/     One subdirectory per skill, each containing SKILL.md
hooks/      Plugin-level Claude Code hooks
tests/      Manual test scenarios (scenarios.md)
```

## Authoring Conventions

Full conventions are documented in `CLAUDE.md`. Key rules for agents:

**Agents (`agents/<name>.md`)**

- Frontmatter fields: `name`, `description`, `model`, `color`, `memory: project`
- `description` must include trigger phrases and delegation relationships
- Names use kebab-case; colors are fixed per role (see `CLAUDE.md`)
- Body sections: Jurisdiction, Delegation, Key Knowledge, Memory Protocol

**Skills (`skills/<name>/SKILL.md`)**

- Frontmatter: `name`, `description`, and optionally `context: fork`
- Use `$ARGUMENTS` for parameterization
- Use `context: fork` for skills that produce heavy output
- Data files for a skill live in subdirectories of its skill directory

**Agent vs. Skill**

- Needs to learn and decide over time → agent
- Executes a fixed procedure → skill
- Agents invoke skills with `/skill-name`; skills do not invoke agents

**Onboarding model**

- `/onboard` — shared project context, writes to `.claude/agent-memory/engineering-leaders/PROJECT.md`
- `/onboard-<agent>` — per-agent context on top of the shared layer

## Testing

Tests are manual scenarios in `tests/scenarios.md`. To run them:

1. Install the plugin in a test project
2. Invoke the named agent with the prompt from each scenario
3. Score each expected behavior as pass/fail

There is no automated test runner.

## PR Workflow

Before opening a PR, run the PR Review Toolkit and address findings:

```
/pr-review-toolkit:review-pr
```

Then commit, push, and open the PR.

## Non-Interactive Shell Commands

Always use non-interactive flags to avoid hanging on confirmation prompts.
Shell commands like `cp`, `mv`, and `rm` may be aliased to `-i` (interactive)
mode on some systems.

```bash
cp -f source dest     # NOT: cp source dest
mv -f source dest     # NOT: mv source dest
rm -f file            # NOT: rm file
rm -rf directory      # NOT: rm -r directory
```

Other commands that may prompt:

- `scp` — use `-o BatchMode=yes`
- `ssh` — use `-o BatchMode=yes`
- `apt-get` — use `-y`
- `brew` — set `HOMEBREW_NO_AUTO_UPDATE=1`
