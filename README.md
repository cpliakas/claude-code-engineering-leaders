# Engineering Leaders

A Claude Code plugin that provides the **leadership layer** for AI-assisted development. While most agent plugins focus on writing code, this one focuses on what happens *before and after* code gets written: [refining requirements](#refine-a-feature-with-the-product-owner), [structuring technical decisions](#plan-implementation-for-a-refined-story-with-the-tech-lead), [governing delivery](#run-a-post-mortem-with-the-devops-lead), and [surfacing systemic issues](#scan-code-churn-then-route-tech-debt-through-the-tech-lead).

Humans decide what to build and why. These agents help refine that intent into artifacts that are ready for implementation.

## How This Complements Other Plugins

The Claude Code ecosystem has excellent implementation-focused agent collections and workflow plugins:

- [wshobson/agents](https://github.com/wshobson/agents): curated agents for coding, testing, and infrastructure tasks
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents): 127+ specialized implementation agents across 10 categories
- [affaan-m/everything-claude-code](https://github.com/AffaanM/everything-claude-code): comprehensive Claude Code resource collection
- [obra/superpowers](https://github.com/obra/superpowers): structured development workflow with TDD discipline, brainstorming gates, and verification before completion

Engineering Leaders fills a different role. Those collections provide agents that write code and enforce execution discipline. This plugin provides advisory agents that ensure the right work gets built the right way before implementation begins.

Without leadership context, implementation agents optimize for technical completeness rather than business fit, and they can miss cross-cutting concerns that only surface when multiple specialists weigh in. Engineering Leaders counters both problems: it right-sizes stories, grounds architectural decisions in explicit trade-offs, and orchestrates specialist input so that implementation plans account for timing bugs, concurrency hazards, and convention gaps before code is written. The goal is the right solution at the right time, delivered at high quality.

## Working Examples

These examples show real prompts for common engineering leadership workflows. Each one is designed to be used as-is or adapted to your project.

### Refine a Feature with the Product Owner

**Scenario:** You have an idea for adding CSV export to the audit log UI and want to validate scope and priority before writing the story.

**Action:**

> `@agents/product-owner Can you help me refine an enhancement? We want to add CSV export to the audit log page so compliance teams can pull reports without needing database access. Does this fit the current phase, and can you write a story for it?`

The `product-owner` checks the enhancement against the current roadmap phase, verifies that the audit log data layer is in place as a prerequisite, and either proceeds or recommends deferral with rationale. When ready, it authors a user story via `/write-story`, triggers an inline INVEST review from `agile-coach`, and presents a polished story with sequencing advice. If the export format decision touches a one-way door (schema or API contract), it recommends looping in `chief-architect` before the story enters the sprint.

**Impact:** A vague feature idea becomes a prioritized, INVEST-validated story with sequencing advice and architectural guardrails before any code is written.

---

### Plan Implementation for a Refined Story with the Tech Lead

**Scenario:** You need to implement a refined story for hook-based state detection in a pipeline orchestrator. Instead of jumping straight to code, you ask the Tech Lead to plan the work.

**Action:**

> `@agents/tech-lead Plan the implementation for this refined story.`

**In a real-world situation,** the **Tech Lead** agent decomposed the problem, identified which domains were involved, and routed consultations to two specialists in parallel:

- **Claude Code Hooks Expert**, a custom subagent defined in the project's `.claude/agents/` directory, specializing in hook event semantics and lifecycle ordering
- **Golang Pro** from the [Voltagent plugin](https://github.com/VoltAgent/awesome-claude-code-subagents), a language specialist for idiomatic Go implementation, concurrency safety, and test patterns

The two specialists returned conflicting recommendations. The hooks expert argued that `PreToolUse` should cancel the idle timer *and* transition state, because long-running tools (30+ second builds) can cause spurious "idle" transitions on the dashboard. The Go specialist argued for timer cancellation only, keeping state transitions in `PostToolUse` to avoid duplicate events in the log.

The Tech Lead resolved the disagreement by siding with the hooks expert on the core question (the safety argument was stronger) while incorporating the Go specialist's concern by adding a guard: only emit a state-change event if the stage actually changed. Both specialists were right about different aspects of the problem.

**Impact:** Without this orchestration layer, the AI would have picked one approach and missed the other's constraint, producing code with either **a timing bug that causes spurious state transitions** or **an event log polluted with duplicate entries**. The Tech Lead caught both issues before a single line of code was written.

---

### Run a Post-Mortem with the DevOps Lead

**Scenario:** The v2.4.0 release caused a spike in 500 errors on the checkout flow and had to be rolled back within 20 minutes.

**Action:**

> `@agents/devops-lead The v2.4.0 release we pushed on Tuesday caused 500 errors on the checkout flow and we had to roll back. Can you run a blameless post-mortem?`

The `devops-lead` invokes `/conduct-postmortem` with the incident description, producing a structured document covering what happened, the contributing factors, the response timeline, and concrete action items. It applies rollback-first doctrine to evaluate whether the team's response sequence was correct, flags any monitoring or runbook gaps the incident exposed, and proposes follow-up operational improvements. If the postmortem reveals a convention or pattern gap, it flags the `tech-lead` for follow-up.

**Impact:** A release failure becomes a structured postmortem with concrete action items, monitoring gap analysis, and cross-agent follow-ups instead of an ad-hoc Slack thread.

---

### Run a Retrospective with the Agile Coach

**Scenario:** Your digital team just wrapped a sprint that included authentication, profile settings, and a first pass at role-based access control. Some stories felt too big and there were scope surprises at the end.

**Action:**

> `@agents/agile-coach We just wrapped the auth sprint. We shipped login, profile settings, and basic RBAC, but a few stories ran long and we had some last-minute scope surprises. Can you run a retrospective so we can figure out what worked and where we need to improve?`

The `agile-coach` invokes `/facilitate-retrospective` with the sprint summary, producing a Derby-Larsen five-phase retrospective document with blameless framing. It surfaces what went well, what needs improvement (story sizing, scope boundary discipline), and generates SMART action items with clear owners. Action items that belong in the backlog are handed off to `product-owner` for sequencing, so nothing falls through the cracks.

**Impact:** Sprint friction turns into SMART action items with owners, and backlog-worthy improvements are routed directly to the Product Owner so nothing falls through the cracks.

---

### Scan Code Churn, Then Route Tech Debt Through the Tech Lead

**Scenario:** The payments module has been touched in nearly every PR this month and you want to know whether it is a signal worth acting on.

**Action:**

> `@agents/engineering-manager The payments module keeps showing up in every PR. Can you run a code churn analysis and tell me if we have a hotspot problem?`

The `engineering-manager` invokes `/analyze-code-churn` scoped to the payments module, classifies the changes by type (feature additions, defect fixes, rework cycles), and identifies hotspot files by severity. If it finds thrashing or temporal coupling signals, it produces structured tech debt proposals with supporting evidence and routes them to `product-owner` for priority review. When the churn reveals a convention or ownership gap, it flags the `tech-lead`, who then engages the appropriate domain specialist to file targeted tech debt stories.

**Impact:** A gut feeling about a hotspot becomes an evidence-based tech debt proposal routed to the right agents for prioritization and action.

---

### Run a Pre-Implementation Refinement Review

**Scenario:** You've drafted a story for a new feature and want strategic
sign-off from the Product Owner, Chief Architect, and UX Strategist before
handing it to the Tech Lead for implementation planning.

**Action:**

> `/refinement-review As a compliance officer, I want to export the audit log as
> a CSV file so that I can provide records to auditors without needing database
> access. Acceptance criteria: ...`

`/refinement-review` invokes all three strategic peers in parallel. The Product
Owner evaluates scope fit and roadmap alignment. The Chief Architect flags any
one-way doors or cross-cutting implications. The UX Strategist checks persona
fit and whether the acceptance criteria describe user-observable outcomes. The
three responses are preserved verbatim in a consolidated report with an overall
readiness verdict: `ready`, `needs-revision`, or `blocked`. When peers
raises a concern or returns a non-ready verdict, the report surfaces those
concerns in an `## Objections` section, attributed to the named peer.

**Impact:** One command surfaces all three strategic perspectives before
implementation begins, preventing the "forgot to ask UX" failure mode and
catching one-way-door concerns while the story is still cheap to revise.

#### When to use `/refinement-review` vs. related skills

| Skill | Purpose | When to use |
|---|---|---|
| `/write-story` | Author a story from scratch | Before `/refinement-review`: draft the story first |
| `/refine-story` | Score the story's structure (INVEST, AC quality) | Complements `/refinement-review`; checks the story's own text for structural quality |
| `/refinement-review` | Strategic sign-off: is this the right thing to build? | After authoring; before `/plan-implementation` |
| `/plan-implementation` | Deconstruct the story into an implementation plan | After `/refinement-review` returns `ready` |

**Note:** Trivial stories that follow well-established patterns and carry no
architectural or persona-fit risk may legitimately skip `/refinement-review`.
Running three peer agents in parallel is more expensive than a single
consultation. Reserve the ceremony for stories where the investment is
justified by the complexity or risk.

---

## Tech Lead Orchestration Tiers

Not every implementation story requires the same level of Tech Lead involvement.
Use these three tiers to select the right level of orchestration before you
invoke the Tech Lead or run `/plan-implementation`. Tier selection happens
before invocation: choose the tier that fits the work, then engage at that level.

### Tier 1 — Direct specialist

**What it is:** Single-domain, established pattern. You already know which
specialist is relevant; no routing or synthesis is needed.

**When to use it:** The change touches one module with a well-understood
pattern, the story follows an approach you have implemented before in this
codebase, and there is no cross-cutting concern or one-way-door risk.

**Examples:**

- Renaming a function inside a single module and updating its callers in the
  same file.
- Adding a unit test that mirrors three existing tests in the same test file.
- Fixing a typo in user-visible copy.
- Tightening a constant value that only affects one domain.

For tier-1 work, invoke the relevant domain specialist directly (for example,
`@agents/golang-pro` or `@agents/react-specialist`). Skip the Tech Lead
entirely. If you invoke the Tech Lead anyway, it will name the single most
relevant specialist with a brief rationale and stop. It does not run Phase 1
routing or emit consultation requests.

### Tier 2 — Standard

**What it is:** Multi-file change within one domain, or an unfamiliar code area
where one or two specialists can provide the right level of guidance.

**When to use it:** The story touches multiple files but stays within one
domain, or you are working in a code area you have not edited before and want
specialist routing without full architectural review.

**Examples:**

- Adding a new API endpoint that spans handler, service, and repository layers
  within a single bounded context.
- Refactoring a module's internal interface in a way that affects multiple
  callers, all within the same domain.
- Implementing a feature in an unfamiliar service where you want the Tech Lead
  to identify the right specialist before you start.
- Adding observability instrumentation across several files in the same domain.

Invoke the Tech Lead via `@agents/tech-lead` or `/plan-implementation`. The
Tech Lead runs the full two-phase consultation protocol and must emit a
consultation request for every matched specialist. No exceptions.

### Tier 3 — Full (with Architect escalation)

**What it is:** Cross-domain change, new pattern introduction, schema
commitment, public API change, or any one-way-door signal. The Tech Lead runs
the full protocol and its Phase 2 synthesis names the Chief Architect as an
explicit escalation before implementation begins.

**When to use it:** The story touches more than one domain, introduces a
convention or pattern for the first time, commits to a data model or public
interface, or contains vocabulary that mirrors the Chief Architect's description
triggers (see the Signals Catalog below).

**Examples:**

- Adding multi-tenancy support that touches the API, database schema, and auth
  layers simultaneously.
- Introducing a new cross-cutting pattern (for example, an event envelope
  format) that will be used across multiple services.
- Adding a public API endpoint that commits to a request or response contract
  visible to external consumers.
- Migrating a database schema in a way that requires backward-compatible reads
  during the rollout window.

Invoke the Tech Lead via `@agents/tech-lead` or `/plan-implementation`. The
Tech Lead runs the full protocol. If a specialist surfaces a qualifying
one-way-door, schema, or public-API signal, its Phase 2 synthesis names
`chief-architect` in the Escalation Flags section, quotes the surfaced signal
verbatim, and recommends pausing for `@agents/chief-architect` consultation
before implementation begins. The user decides whether to engage the Architect;
the escalation is a recommendation, not a gate.

### Signals Catalog

Use the signals below to select a default tier when the right level of
orchestration is not already obvious. This catalog is guidance, not a gate:
an explicit tier stated in your invocation always wins.

> **If in doubt, escalate.** Defaulting to a lower tier to avoid overhead is
> the failure mode this catalog exists to prevent. When two signals point to
> different tiers, choose the higher tier. A fast "nothing here for me" from a
> specialist is cheap; a missed one-way-door discovered mid-implementation is
> not.

**Touched-file count bands:**

| Files touched | Default tier candidate |
|---|---|
| 1 file | Tier 1 |
| 2–5 files within one domain | Tier 2 |
| More than 5 files, or files across multiple domains | Tier 3 |

These are starting points. A one-file change that touches a public interface
still promotes to tier 3 via the one-way-door vocabulary signal below.

**Domain count:**

Count domains by cross-referencing the story's affected code areas against the
Tech Lead's registered specialist set and `## Project Code Area Overrides` in
project memory. A story that crosses a domain boundary, even with a small file
count, is a tier-2 candidate at minimum. Crossing two or more domain boundaries
promotes to tier 3.

**One-way-door vocabulary:**

If the story text or acceptance criteria contain any of the following keywords,
treat the story as a tier-3 candidate. These mirror the Chief Architect's own
invocation triggers (see `agents/chief-architect.md`): "new pattern", "touches
data models or public contracts", "spans multiple components", "one-way door",
"forward compatibility", "cross-cutting".

Specific vocabulary that triggers tier 3 promotion:

- `schema`, `migration`, `data model`
- `API contract`, `public interface`, `public API`
- `event envelope`, `wire format`, `serialization`
- `one-way door`, `irreversible`, `breaking change`
- `cross-cutting`, `spans multiple`, `across services`

**New-pattern vocabulary:**

If the story text contains any of the following, treat the story as a tier-2
candidate at minimum, and tier 3 if there is also cross-domain impact:

- `new pattern`, `introduce`, `first time`, `for the first time`
- `convention`, `establish`, `define the standard`

**Unfamiliar-area heuristic:**

If the story touches code you have not previously edited in this project, or if
the story's domain has no registered specialist in the Tech Lead's routing
table, escalate one tier above what the file-count band alone would indicate.
Tier 1 becomes tier 2; tier 2 becomes tier 3.

#### How tiers interact with `/plan-implementation` and `/refinement-review`

Tier selection is a pre-invocation concern: choose your tier before calling the
Tech Lead or running `/plan-implementation`.

- `/refinement-review` is a pre-implementation strategic review (Product Owner,
  Chief Architect, UX Strategist). It is independent of tier selection; any
  story that benefits from strategic sign-off can use it regardless of tier.
  Tier-3 stories are strong candidates for `/refinement-review` before Tech
  Lead involvement.
- `/plan-implementation` drives the full two-phase Tech Lead protocol
  automatically. Use it for tier-2 and tier-3 stories. For tier-1 stories,
  invoke the domain specialist directly instead.

See the
[Plan Implementation for a Refined Story with the Tech Lead](#plan-implementation-for-a-refined-story-with-the-tech-lead)
example above for a real-world illustration of the Tech Lead's two-phase
protocol in action.

---

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
- **Specialist agents:** any domain specialists from other plugins the Tech Lead should route to during implementation planning (one-step registration with `/add-specialist`)

Onboarding writes to `.claude/agent-memory/engineering-leaders/PROJECT.md` — a shared context file that all eight agents read automatically.

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
| Skill | `/refinement-review`       | Convene the PO, Architect, and UX Strategist in parallel on a story draft; produces a readiness verdict before implementation |
| Skill | `/refine-story`            | Score a story draft against INVEST and agile coaching principles                           |
| Skill | `/decompose-requirement`   | Decompose an epic into stories, or a story into subtasks, with structured metadata         |
| Skill | `/facilitate-retrospective` | Facilitate a structured retrospective using the Derby-Larsen five-phase framework         |
| Skill | `/conduct-postmortem`      | Conduct a blameless postmortem for an incident or failed/aborted release                   |
| Skill | `/write-adr`               | Produce an Architecture Decision Record in MADR format                                     |
| Skill | `/write-runbook`           | Generate a structured operational runbook for incident response or maintenance             |
| Skill | `/plan-test-strategy`      | Produce a test strategy with highest-impact tests by type and layer                        |
| Skill | `/analyze-code-churn`      | Analyze code churn and thrash patterns with hotspot detection and rework classification    |
| Skill | `/plan-implementation`     | Drive the Tech Lead's two-phase consultation end-to-end: routing, specialist fan-out, and synthesis |
| Skill | `/add-specialist`          | Register a specialist agent for Tech Lead routing (one step, no trigger-phrase copying)    |
| Skill | `/audit-routing-table`     | Audit Tech Lead routing health: orphan overrides, broken pointers, redundant rows, thin descriptions |

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

```
┌──────────────────────────────────────────────────────────┐
│                    Leadership Layer                      │
│                    (this plugin)                         │
│                                                          │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐  │
│  │  Strategy     │  │  Operations   │  │  Process     │  │
│  │               │  │               │  │              │  │
│  │  product-     │  │  devops-lead  │  │  agile-coach │  │
│  │  owner        │  │  qa-lead      │  │              │  │
│  │  chief-       │  │  engineering- │  │              │  │
│  │  architect    │  │  manager      │  │              │  │
│  │  ux-          │  │               │  │              │  │
│  │  strategist   │  │               │  │              │  │
│  └───────┬───────┘  └───────┬───────┘  └──────┬───────┘  │
│          │                  │                 │          │
│          └──────────┬───────┘─────────────────┘          │
│                     │                                    │
│              ┌──────┴───────┐                            │
│              │  tech-lead   │  Tactical orchestrator     │
│              │              │  Routes to specialists,    │
│              │              │  synthesizes input,        │
│              │              │  owns conventions          │
│              └──────┬───────┘                            │
└─────────────────────┼────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│                 Implementation Layer                     │
│                 (other plugins / agents)                 │
│                                                          │
│  Specialists engaged by tech-lead based on               │
│  code area and signal matching                           │
│                                                          │
│  backend-dev · terraform-engineer · test-automator       │
│  docker-expert · react-specialist · golang-pro · ...     │
└──────────────────────────────────────────────────────────┘
```

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
    ├── refinement-review/SKILL.md
    ├── decompose-requirement/SKILL.md
    ├── facilitate-retrospective/SKILL.md
    ├── conduct-postmortem/SKILL.md
    ├── write-adr/SKILL.md
    ├── write-runbook/SKILL.md
    ├── plan-test-strategy/SKILL.md
    ├── analyze-code-churn/SKILL.md
    ├── add-specialist/SKILL.md
    ├── audit-routing-table/
    │   ├── SKILL.md
    │   └── MIGRATION.md
    └── plan-implementation/
        ├── SKILL.md
        └── test-fixtures/
```

## License

MIT
