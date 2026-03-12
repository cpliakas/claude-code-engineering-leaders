# engineering-leaders

A Claude Code plugin providing engineering leadership agents — the virtual leadership team that refines requirements, sets technical direction, and governs delivery.

## Authoring Conventions

### Markdown Body

- Always add a blank line between a heading (or bold-text header like `**Triggers:**`) and the following list or paragraph. Omitting the blank line violates MD022/MD032 and can cause rendering issues.

### Agents

- One markdown file per agent in `agents/`
- Follow the agent definition template: frontmatter (name, description, model, memory) + body (jurisdiction, delegation, key knowledge, memory protocol)
- Descriptions must include trigger phrases AND delegation relationships
- All agents use `memory: project` — they learn per-project
- Agent names use kebab-case
- Agent colors are assigned by role to ensure visual distinction in the Claude Code UI:

  | Agent | Color | Rationale |
  |-------|-------|-----------|
  | chief-architect | blue | Strategic authority, long-term thinking |
  | product-owner | yellow | Planning and prioritization (sticky-note energy) |
  | ux-strategist | magenta | Creative, user-empathy, experience focus |
  | agile-coach | green | Process health, go/no-go signals |
  | devops-lead | cyan | Infrastructure, operational tooling |
  | engineering-manager | orange | Meta-observation, systemic feedback |
  | qa-lead | red | Quality gates, risk signals |
  | tech-lead | purple | Tactical orchestration, convention ownership |

### Skills

- One directory per skill in `skills/<skill-name>/`
- Must contain `SKILL.md` with YAML frontmatter
- Skills are opinionated procedures with clear inputs, process steps, and outputs
- Use `$ARGUMENTS` for parameterization
- Use `context: fork` for skills that produce a lot of output (keeps main context clean)
- Skills can bundle data files in subdirectories — reference them via Glob/Read relative to the skill directory

### Agent vs Skill Decision

- If it needs to learn and decide → agent
- If it needs to execute a procedure → skill
- Agents use skills; skills don't use agents
- Agents reference skills with the `/` prefix (e.g., `/write-runbook`) in their markdown — Claude invokes the skill autonomously when the agent's instructions call for it

### Onboarding Skills

The plugin uses a two-layer onboarding model:

**Layer 1 — Shared context (`/onboard`):** Gathers project-wide context that
all agents benefit from (project overview, tech stack, team structure, SDLC
process). Also runs specialist discovery to populate the Tech Lead routing
table. Writes to `.claude/agent-memory/engineering-leaders/PROJECT.md`.

**Layer 2 — Per-agent context (`/onboard-<agent>`):** Gathers agent-specific
context on top of the shared layer. Each agent that needs project-specific
configuration gets its own companion onboarding skill. The `product-owner` agent
is the reference implementation.

**Interview discipline:** Both layers follow the same conventions:

- One question at a time; wait for the answer before asking the next
- Multiple-choice options wherever the answer set is bounded
- Every question is skippable — partial context is better than no context
- Write to memory after collecting answers, not incrementally

**Per-agent onboarding skill checklist:**

1. Read shared context from `PROJECT.md` first; handle gracefully if missing
2. Introduce the skill before asking anything
3. Ask agent-specific questions one at a time (issue tracker, norms, current
   state — whatever that agent needs)
4. Write to the agent's project memory:
   `.claude/agent-memory/engineering-leaders-<agent>/MEMORY.md`
5. Include a `## Shared Project Context` pointer back to `PROJECT.md`
6. Present a confirmation summary of what was written

**Naming convention:** `onboard-<agent-name>` (e.g., `onboard-tech-lead`,
`onboard-qa-lead`). Place in `skills/onboard-<agent-name>/SKILL.md`.

### Pull Request Workflow

Before opening a PR:

1. Run the PR Review Toolkit (`pr-review-toolkit:review-pr`) against the staged changes
2. Address any findings
3. Then commit, push, and open the PR

### Plugin Versioning

- The `version` field in `marketplace.json` tracks the current release version (in the plugin entry under `plugins[]`)
- Do not duplicate the version in `plugin.json` — for relative-path marketplace plugins, the marketplace entry is the single source of truth
- Tag releases with `v<version>` (e.g., `v0.10.0`) when cutting a version
