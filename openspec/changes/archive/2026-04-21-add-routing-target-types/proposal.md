# Change Proposal: Routing Target Types

## Why

The Tech Lead's routing table implicitly assumes every registered entry is a
Claude Code sub-agent. The agent definition at `agents/tech-lead.md` and the
`tech-lead-routing` capability spec both model a registered specialist as an
agent name paired with a path to an agent markdown file. The `/add-specialist`
skill writes that single shape into
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`, and the Tech
Lead's Phase 1 consultation requests emit only `**Agent:**` with a kebab-case
slug. The caller (or the `/plan-implementation` skill) then dispatches that
slug through the Agent tool as a sub-agent.

In real projects, routing decisions are not always to a sub-agent. Some
consultations are better served by:

- A **skill** that produces a deterministic artifact (for example, a
  `/write-runbook` invocation for an operational question).
- A **document** the user should read before proceeding (an ADR, a convention
  file, a runbook path).
- A **human** whose judgment is load-bearing (security reviewer, compliance
  owner, infrastructure owner).
- **Another plugin's agent** (a specialist from a separate marketplace plugin,
  referenced by a namespaced slug).

Today these decisions either get shoehorned into sub-agent targets (which is
unnatural and produces routing that names an agent that does not exist in the
local registry) or drop out of the routing model entirely (so the Tech Lead
cannot emit them as consultation requests in Phase 1, and the caller never
sees them as structured routing outputs). Projects with compliance or security
gates therefore encode those gates as ad-hoc reminders in issue bodies rather
than as first-class routing entries.

## What Changes

- Extend the routing table so every registered entry MAY declare a target
  type. The five supported target types are `subagent`, `skill`, `doc`,
  `human`, and `external-agent`. Entries that omit the field default to
  `subagent` so existing memory files continue to work without edits.
- Extend the Tech Lead's Phase 1 consultation request format so each
  `### <Name>` subsection carries a `**Target Type:**` line immediately after
  the subsection heading. The existing `**Prompt:**` anchor is retained
  verbatim. The existing `**Agent:**` anchor is retained for `subagent` and
  `external-agent` entries, and is replaced by `**Skill:**`, `**Doc:**`, or
  `**Contact:**` for the other three types.
- Extend the `/add-specialist` skill to accept an explicit target type so
  users can register skills, docs, humans, and external-plugin agents without
  hand-editing the memory file. When no target type is provided, the skill
  continues to register a `subagent` entry as today.
- Document the caller-side handling pattern for each target type in the
  top-level `README.md` so the Phase 1 output is actionable:
  - `subagent`: spawn via the Agent tool (current behavior).
  - `skill`: the caller invokes the named skill with the emitted prompt.
  - `doc`: the output references a path the user should read; the plan notes
    the dependency.
  - `human`: the plan is paused with an explicit escalation notice naming the
    person or role.
  - `external-agent`: namespaced agent reference (for example,
    `plugin-x:agent-y`) dispatched via the Agent tool.
- Update the `tech-lead-routing` capability spec to include the new optional
  field on registered entries and the new per-target-type Phase 1 anchors.
- Do not change the `/plan-implementation` skill in this proposal. The skill's
  parser continues to match the existing anchors, and the new `**Target
  Type:**` line is an additive anchor that parsers MAY ignore. Target-type
  dispatch in the skill is a follow-up change.

## Capabilities

### New Capabilities

- `routing-target-types`: documented target-type extension to the Tech Lead's
  routing table. Covers the schema addition, `/add-specialist` input,
  per-target-type Phase 1 anchors, and caller-side handling patterns for each
  of the five supported target types.

### Modified Capabilities

<!-- The `tech-lead-routing` capability gains an optional `target_type` field
on every registered entry and gains new per-target-type anchors
(`**Target Type:**`, `**Skill:**`, `**Doc:**`, `**Contact:**`) alongside the
existing `**Agent:**` anchor. Entries that omit the field default to
`subagent` so the capability's existing routing behavior and parser contract
are preserved. -->

## Impact

- **Users:** Can register routing entries that point at skills, docs, humans,
  or external-plugin agents without shoehorning them as sub-agents. Projects
  with compliance, security, or infrastructure gates can encode those gates
  in routing rather than as ad-hoc reminders.
- **Tech Lead agent:** Phase 1 output differentiates consultation requests by
  target type. The `**Agent:**` anchor is preserved for `subagent` and
  `external-agent` entries. `**Skill:**`, `**Doc:**`, and `**Contact:**`
  replace the `**Agent:**` anchor for the remaining three types. A single
  `**Target Type:**` line appears on every consultation request regardless of
  type, so a reader (or a future parser) can branch on a single key.
- **`/add-specialist` skill:** Accepts an explicit target type. Back-compat
  behavior is preserved: omitting the target type still registers a
  `subagent` entry and writes the legacy row format. Target-specific
  validation is added (for example, a `skill` target type requires a slug
  that resolves to a known skill; a `doc` target type requires a path).
- **`/plan-implementation` skill:** No behavior change in this proposal. The
  skill continues to parse `**Agent:**` and `**Prompt:**` for existing
  entries. When a consultation request has a non-subagent target type, the
  current skill surfaces the request to the user rather than silently
  dropping it. Full target-type dispatch is a follow-up change.
- **`tech-lead-routing` capability spec:** Gains an optional `target_type`
  field on registered entries and documents the per-target-type Phase 1
  anchors. The default of `subagent` preserves existing behavior.
- **README:** Gains a documented handling pattern for each of the five target
  types, cross-referenced from the Tech Lead example and the
  `/add-specialist` section.
- **Token cost:** Minor. Phase 1 output gains one line per consultation
  request (the `**Target Type:**` anchor). No new LLM calls.
- **Existing projects:** No migration required. Any registered-specialists
  entry without an explicit target type is treated as `subagent` at routing
  time. The audit skill may later surface orphan or mis-typed rows.
- **Non-goals:** Automatic integration with ticket systems for human
  escalation (the notice is in-plan only); automatic content extraction from
  document references (the user reads the doc, the plan does not inline its
  content); changes to how skills themselves work; cross-plugin routing
  discovery (external-agent entries are declared explicitly).
