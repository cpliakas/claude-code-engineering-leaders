# Engineering Leaders

A Claude Code plugin that provides the **leadership layer** for AI-assisted development. While most agent plugins focus on writing code, this one focuses on what happens *before and after* code gets written: refining requirements, structuring technical decisions, governing delivery, and surfacing systemic issues.

Humans decide what to build and why. These agents help refine that intent into artifacts that are ready for implementation.

## How This Complements Other Plugins

The Claude Code ecosystem has excellent implementation-focused agent collections and workflow plugins:

- [wshobson/agents](https://github.com/wshobson/agents): curated agents for coding, testing, and infrastructure tasks
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents): 127+ specialized implementation agents across 10 categories
- [affaan-m/everything-claude-code](https://github.com/AffaanM/everything-claude-code): comprehensive Claude Code resource collection
- [obra/superpowers](https://github.com/obra/superpowers): structured development workflow with TDD discipline, brainstorming gates, and verification before completion

Engineering Leaders fills a different role. Those collections provide agents that write code and enforce execution discipline. This plugin provides advisory agents that ensure the right work gets built the right way before implementation begins.

Without leadership context, implementation agents optimize for technical completeness rather than business fit. They may reach for distributed systems when a monolith would serve the project better, introduce patterns a small team cannot maintain, or apply architectural sophistication that outpaces what the project actually needs. These are the ivory tower failure modes: technically impressive, but misaligned with business constraints. Engineering Leaders counters this by ensuring stories are right-sized, architectural decisions are grounded in explicit trade-offs, and technical choices are made with awareness of the team's capacity and the project's current phase. The goal is not the most elegant solution: it is the right solution at the right time, delivered consistently.

```
┌─────────────────────────────────────────────────────┐
│  Leadership Layer (this plugin)                      │
│  Refines human intent into implementation-ready      │
│  artifacts                                           │
│                                                      │
│  product-owner · chief-architect · tech-lead         │
│  qa-lead · devops-lead · agile-coach · EM · UX       │
└────────────────────────┬────────────────────────────┘
                         │ tech-lead orchestrates:
                         │ reads the implementation plan,
                         │ consults the specialist routing
                         │ table, and engages the right
                         │ agents for each domain
                         ▼
┌─────────────────────────────────────────────────────┐
│  Implementation Layer (other plugins / agents)       │
│  Executes the plan — specialists engaged by          │
│  tech-lead based on code area and signal matching    │
│                                                      │
│  backend-developer · terraform-engineer              │
│  test-automator · docker-expert · react-specialist   │
└─────────────────────────────────────────────────────┘
```

## Quick Start

Add the marketplace to your Claude Code project, then install the plugin:

```
/plugin marketplace add cpliakas/claude-code-engineering-leaders
/plugin install engineering-leaders
```

## Setting Up for Your Project

After installation, run the onboarding skill to configure the plugin for your specific project:

```
/onboard
```

This runs a guided interview — one question at a time — that captures the context every agent needs to give you useful, project-specific advice rather than generic guidance. It covers:

- **Project overview:** what you're building, your business domain, current phase
- **Tech stack:** languages, frameworks, key infrastructure
- **Team:** size, disciplines, SDLC process
- **Key constraints:** compliance, performance targets, architectural boundaries
- **Specialist agents:** any domain specialists from other plugins the Tech Lead should route to during implementation planning

Onboarding writes to `.claude/agent-memory/engineering-leaders/PROJECT.md` — a shared context file that all eight agents read automatically.

## Working Examples

These examples show real prompts for common engineering leadership workflows. Each one is designed to be used as-is or adapted to your project.

### Refine a Feature with the Product Owner

**Scenario:** You have an idea for adding CSV export to the audit log UI and want to validate scope and priority before writing the story.

> `@product-owner Can you help me refine an enhancement? We want to add CSV export to the audit log page so compliance teams can pull reports without needing database access. Does this fit the current phase, and can you write a story for it?`

The `product-owner` checks the enhancement against the current roadmap phase, verifies that the audit log data layer is in place as a prerequisite, and either proceeds or recommends deferral with rationale. When ready, it authors a user story via `/write-story`, triggers an inline INVEST review from `agile-coach`, and presents a polished story with sequencing advice. If the export format decision touches a one-way door (schema or API contract), it recommends looping in `chief-architect` before the story enters the sprint.

---

### Run a Post-Mortem with the DevOps Lead

**Scenario:** The v2.4.0 release caused a spike in 500 errors on the checkout flow and had to be rolled back within 20 minutes.

> `@devops-lead The v2.4.0 release we pushed on Tuesday caused 500 errors on the checkout flow and we had to roll back. Can you run a blameless post-mortem?`

The `devops-lead` invokes `/conduct-postmortem` with the incident description, producing a structured document covering what happened, the contributing factors, the response timeline, and concrete action items. It applies rollback-first doctrine to evaluate whether the team's response sequence was correct, flags any monitoring or runbook gaps the incident exposed, and proposes follow-up operational improvements. If the postmortem reveals a convention or pattern gap, it flags the `tech-lead` for follow-up.

---

### Run a Retrospective with the Agile Coach

**Scenario:** Your team just wrapped a sprint that included authentication, profile settings, and a first pass at role-based access control. Some stories felt too big and there were scope surprises at the end.

> `@agile-coach We just wrapped the auth sprint. We shipped login, profile settings, and basic RBAC, but a few stories ran long and we had some last-minute scope surprises. Can you run a retrospective so we can figure out what worked and where we need to improve?`

The `agile-coach` invokes `/facilitate-retrospective` with the sprint summary, producing a Derby-Larsen five-phase retrospective document with blameless framing. It surfaces what went well, what needs improvement (story sizing, scope boundary discipline), and generates SMART action items with clear owners. Action items that belong in the backlog are handed off to `product-owner` for sequencing, so nothing falls through the cracks.

---

### Scan Code Churn, Then Route Tech Debt Through the Tech Lead

**Scenario:** The payments module has been touched in nearly every PR this month and you want to know whether it is a signal worth acting on.

> `@engineering-manager The payments module keeps showing up in every PR. Can you run a code churn analysis and tell me if we have a hotspot problem?`

The `engineering-manager` invokes `/analyze-code-churn` scoped to the payments module, classifies the changes by type (feature additions, defect fixes, rework cycles), and identifies hotspot files by severity. If it finds thrashing or temporal coupling signals, it produces structured tech debt proposals with supporting evidence and routes them to `product-owner` for priority review. When the churn reveals a convention or ownership gap, it flags the `tech-lead`, who then engages the appropriate domain specialist to file targeted tech debt stories.

---

### Per-Agent Setup

After running `/onboard`, configure individual agents with their own onboarding skills for deeper project-specific context:

| Skill | Agent | What It Captures |
|---|---|---|
| `/onboard-product-owner` | `product-owner` | Issue tracker, current phase, backlog norms, team sizing and DoD conventions |

Additional per-agent onboarding skills will be added as the pattern matures. You can always invoke agents without onboarding — they degrade gracefully and will prompt you to run the relevant skill when project-specific context would improve their advice.

## Agents and Skills

| Type  | Name                       | Description                                                                                |
| ----- | -------------------------- | ------------------------------------------------------------------------------------------ |
| Agent | `chief-architect`          | Strategic technical advisor for architecture decisions, trade-offs, and ADRs               |
| Agent | `product-owner`            | Roadmap keeper that advises on sequencing, priorities, and phase transitions                |
| Agent | `tech-lead`                | Tactical orchestrator for implementation plans, specialist routing, and convention ownership |
| Agent | `engineering-manager`      | SDLC meta-observer for tech debt scans, convention health, and code churn analysis         |
| Agent | `devops-lead`              | Infrastructure strategy lead for CI/CD design, deployment doctrine, and incident response  |
| Agent | `qa-lead`                  | QA strategy lead for test architecture, coverage gaps, and risk-based prioritization       |
| Agent | `agile-coach`              | Peer coach for story quality review and retrospective facilitation                         |
| Agent | `ux-strategist`            | Strategic UX advisor for experience coherence, persona guidance, and behavioral consistency |
| Skill | `/onboard`                 | Guided project setup: shared context interview for all agents + Tech Lead specialist discovery |
| Skill | `/onboard-product-owner`   | Configure the Product Owner with issue tracker, backlog norms, and current roadmap state |
| Skill | `/write-epic`              | Write an epic specification with structured metadata compatible with GitHub Issues and Jira |
| Skill | `/write-story`             | Write a user story with acceptance criteria and INVEST validation                          |
| Skill | `/write-bug`               | Scaffold a RIMGEN-validated bug report with reproduction steps, severity, and priority     |
| Skill | `/write-spike`             | Produce a structured findings document for a topic too uncertain to story-write directly   |
| Skill | `/refine-story`            | Score a story draft against INVEST and agile coaching principles                           |
| Skill | `/decompose-requirement`   | Decompose an epic into stories, or a story into subtasks, with structured metadata         |
| Skill | `/facilitate-retrospective` | Facilitate a structured retrospective using the Derby-Larsen five-phase framework         |
| Skill | `/conduct-postmortem`      | Conduct a blameless postmortem for an incident or failed/aborted release                   |
| Skill | `/write-adr`               | Produce an Architecture Decision Record in MADR format                                     |
| Skill | `/write-runbook`           | Generate a structured operational runbook for incident response or maintenance             |
| Skill | `/plan-test-strategy`      | Produce a test strategy with highest-impact tests by type and layer                        |
| Skill | `/analyze-code-churn`      | Analyze code churn and thrash patterns with hotspot detection and rework classification    |

## Architecture

### Agents vs Skills

|                    | Agent                                      | Skill                           |
| ------------------ | ------------------------------------------ | ------------------------------- |
| **What**           | A specialist persona with domain expertise | A repeatable procedure / SOP    |
| **Memory**         | Yes, learns across sessions                | No, runs the same way each time |
| **Judgment**       | Yes, decides _how_ to approach problems    | No, follows a defined process   |
| **Think of it as** | An IC you hired                            | A runbook in a wiki             |

**Rule of thumb**: If it needs to _learn and decide_, it's an agent. If it needs to _execute a procedure_, it's a skill.

### Agent Hierarchy

Agents form a digital leadership team with clear delegation chains. The `tech-lead` acts as tactical orchestrator during implementation, routing to domain specialists as needed. Strategic agents like `chief-architect` and `product-owner` set direction, while operational agents like `devops-lead`, `qa-lead`, and `engineering-manager` govern their respective domains.

### Handoff Patterns

Each leadership agent produces artifacts that feed directly into implementation:

| Leadership Agent | Produces | Useful Input For |
|---|---|---|
| **product-owner** | Prioritized story with AC | Any implementation agent scoped to the story |
| **chief-architect** | ADR selecting an approach | Domain specialist who implements the chosen pattern |
| **tech-lead** | Implementation plan with steps | Developers executing each step |
| **devops-lead** | Pipeline design, deployment strategy | `terraform-engineer`, `docker-expert`, `deployment-engineer` |
| **qa-lead** | Test strategy by type and layer | `test-automator`, `qa-expert` |
| **ux-strategist** | Persona guidance, behavioral spec | `ui-designer`, `frontend-developer` |
| **agile-coach** | Refined story, retro action items | `product-owner` (backlog updates), implementation agents |
| **engineering-manager** | Debt proposals, health reports | Human decision-maker, then implementation agents for approved work |

### Example Workflow

1. **product-owner** sequences a feature and produces a story via `/write-story`
2. **chief-architect** evaluates the approach and records an ADR via `/write-adr`
3. **tech-lead** breaks the story into an implementation plan and routes to domain specialists
4. **qa-lead** produces a test strategy via `/plan-test-strategy`
5. **devops-lead** designs the deployment approach
6. Implementation agents (yours or from other plugins) execute the plan
7. **engineering-manager** scans the resulting PRs for deferred debt

### Memory

All agents use `memory: project`. The agent definition is shared via the plugin, but each project maintains its own memory in `.claude/agent-memory/`. Generic learnings stay in the agent definition; project-specific learnings stay in project memory.

## Repository Structure

```
claude-code-engineering-leaders/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CLAUDE.md
├── hooks/
│   └── markdownlint-check.sh
├── agents/
│   ├── chief-architect.md
│   ├── product-owner.md
│   ├── tech-lead.md
│   ├── engineering-manager.md
│   ├── devops-lead.md
│   ├── qa-lead.md
│   ├── agile-coach.md
│   └── ux-strategist.md
└── skills/
    ├── onboard/SKILL.md
    ├── onboard-product-owner/SKILL.md
    ├── write-epic/SKILL.md
    ├── write-story/SKILL.md
    ├── write-bug/SKILL.md
    ├── write-spike/SKILL.md
    ├── refine-story/SKILL.md
    ├── decompose-requirement/SKILL.md
    ├── facilitate-retrospective/SKILL.md
    ├── conduct-postmortem/SKILL.md
    ├── write-adr/SKILL.md
    ├── write-runbook/SKILL.md
    ├── plan-test-strategy/SKILL.md
    └── analyze-code-churn/SKILL.md
```

## License

MIT
