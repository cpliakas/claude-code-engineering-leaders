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

### Plugin Versioning

- The `version` field in `plugin.json` tracks the current release version
- Tag releases with `v<version>` (e.g., `v0.10.0`) when cutting a version
