# Tasks

## 1. Update the `tech-lead-routing` capability spec

- [x] 1.1 Document the optional `target_type` field on registered entries in
      `openspec/specs/tech-lead-routing/spec.md`, including the five valid
      values (`subagent`, `skill`, `doc`, `human`, `external-agent`) and the
      `subagent` default when the field is omitted
- [x] 1.2 Document the semantic of the `<path-or-slug>` token per target
      type (agent file path for `subagent`, skill slug for `skill`, file
      path for `doc`, contact identifier for `human`, namespaced slug for
      `external-agent`)
- [x] 1.3 Document the extended Phase 1 output anchors per target type
      (`**Target Type:**`, `**Agent:**`, `**Skill:**`, `**Doc:**`,
      `**Contact:**`, `**Prompt:**`)
- [x] 1.4 Update the Invariants section so "every override row targets a
      registered specialist" and "Phase 1 output format is unchanged" are
      replaced with the target-type-aware invariants (overrides still target
      registered entries regardless of type; Phase 1 output gains an
      additive `**Target Type:**` anchor)
- [x] 1.5 Update the Acceptance Criteria so registering a `doc`, `skill`,
      `human`, or `external-agent` target and matching it during Phase 1
      produces the correct per-type anchors

## 2. Update the Tech Lead agent definition

- [x] 2.1 Update the Phase 1 routing procedure in `agents/tech-lead.md` to
      read the target-type field (if present) when loading registered
      specialists and to skip the agent-file read for non-`subagent` and
      non-`external-agent` target types
- [x] 2.2 Update the Phase 1 output template so each `### <Name>` subsection
      includes a `**Target Type:**` line immediately after the heading, with
      value drawn from the five-string vocabulary
- [x] 2.3 Update the Phase 1 output template to emit the per-type anchor
      (`**Agent:**`, `**Skill:**`, `**Doc:**`, `**Contact:**`) after
      `**Target Type:**` and before `**Prompt:**`
- [x] 2.4 Update the Parseable Phase 1 Output Contract subsection to
      document the new `**Target Type:**`, `**Skill:**`, `**Doc:**`, and
      `**Contact:**` anchors as additive, and to note that parsers MAY
      ignore requests they cannot dispatch
- [x] 2.5 Cross-reference the README's handling-patterns section from the
      agent definition so the two stay aligned

## 3. Update the `/add-specialist` skill

- [x] 3.1 Extend argument parsing in `skills/add-specialist/SKILL.md` to
      recognize an explicit target type via `--target-type=<value>` flag
      and via a second positional token matching the fixed vocabulary
- [x] 3.2 Document the per-type validation (skill slug check via Glob of
      `skills/<slug>/SKILL.md`; `doc` path existence check via Glob;
      `external-agent` namespace-separator check; no check for `human`)
- [x] 3.3 Document that all validation failures are warnings, not errors,
      mirroring the existing duplicate and redundancy warning pattern
- [x] 3.4 Update the memory-file write format so non-`subagent` entries
      write the target-type suffix; `subagent` entries (explicit or
      defaulted) write the legacy format unchanged for back-compat
- [x] 3.5 Update the skill's Output section so the confirmation summary
      shows the target type for non-`subagent` registrations and
      cross-references the README handling pattern

## 4. Author README handling-patterns section

- [x] 4.1 Add a section to the top-level `README.md` titled "Routing
      Target Types" that names the five types and documents the caller-
      side dispatch semantics for each
- [x] 4.2 Include one concrete example per target type, drawn from realistic
      engineering scenarios (for example, `/write-runbook` as a `skill`
      target; an ADR file as a `doc` target; a named security reviewer as a
      `human` target; a namespaced plugin agent as an `external-agent`
      target)
- [x] 4.3 Document that `doc` and `human` targets are non-dispatchable in
      the automated flow: the plan pauses or notes the dependency and the
      user owns the handoff
- [x] 4.4 Cross-reference the Tech Lead example and the `/add-specialist`
      example so readers find the handling guidance from both entry points
- [x] 4.5 State explicitly that entries without a declared target type
      default to `subagent` and existing projects require no migration

## 5. Validate `/plan-implementation` compatibility

- [x] 5.1 Read `skills/plan-implementation/SKILL.md` and confirm its Phase 1
      parser matches only the anchors documented in the existing contract
      (`## Consultation Requests`, `### <Name>`, `**Agent:**`, `**Prompt:**`,
      `## Next Step`)
- [x] 5.2 Confirm the new `**Target Type:**` line and the per-type anchors
      (`**Skill:**`, `**Doc:**`, `**Contact:**`) do not fall between
      existing anchors in a way that would confuse the parser
- [x] 5.3 Confirm the skill's current behavior on a consultation request
      without `**Agent:**` is to surface the request rather than spawn a
      sub-agent, so `skill`, `doc`, and `human` targets are handled
      gracefully without skill changes
- [x] 5.4 Document in the capability spec that `/plan-implementation`
      dispatch for non-`subagent` target types is a deliberate follow-up

## 6. Internal consistency review

- [x] 6.1 Re-read the updated `agents/tech-lead.md` and confirm the Phase 1
      output template and the Parseable Phase 1 Output Contract subsection
      are consistent with the spec
- [x] 6.2 Re-read the updated `README.md` and confirm the handling patterns
      match the per-type anchors in the agent definition and the spec
- [x] 6.3 Re-read the updated `openspec/specs/tech-lead-routing/spec.md`
      and confirm the Invariants and Acceptance Criteria reflect the
      target-type extension
- [x] 6.4 Confirm no text changes were made to
      `skills/plan-implementation/SKILL.md`
- [x] 6.5 Confirm no text changes were made to
      `skills/refinement-review/SKILL.md`

## 7. Manual verification

- [x] 7.1 Register a `skill` target via `/add-specialist <slug> skill` and
      confirm the memory file gets a target-type suffix and the Tech Lead's
      Phase 1 output emits `**Target Type:** skill` and `**Skill:** <slug>`
      on a matching issue
- [x] 7.2 Register a `doc` target pointing at an existing markdown file and
      confirm `/add-specialist` validates the path via Glob, writes the
      entry, and the Tech Lead's Phase 1 output emits `**Target Type:** doc`
      and `**Doc:** <path>` on a matching issue
- [x] 7.3 Register a `human` target and confirm the Phase 1 output emits
      `**Target Type:** human` and `**Contact:** <name-or-role>` on a
      matching issue
- [x] 7.4 Register an `external-agent` target with a namespaced slug and
      confirm the Phase 1 output emits `**Target Type:** external-agent`
      and `**Agent:** <plugin:agent>` on a matching issue
- [x] 7.5 Register a legacy entry (no target type) and confirm routing
      still works, the entry writes in legacy format, and the Phase 1
      output emits `**Target Type:** subagent`
- [x] 7.6 Run `/plan-implementation` on a story whose routing matches a
      `skill` target and confirm the skill does not crash; the unspawnable
      request is surfaced to the user rather than silently dropped
