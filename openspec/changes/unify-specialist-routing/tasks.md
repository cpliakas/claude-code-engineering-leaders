# Tasks: Unify Specialist Routing Around Agent Descriptions

## 1. Tech Lead Memory Format

- [ ] 1.1 Update the Tech Lead agent definition (`agents/tech-lead.md`) to read
      `## Registered Specialists` and `## Project Code Area Overrides` instead
      of the current `## Specialist Routing Table` section.
- [ ] 1.2 Document the new sections' format and invariants in the Tech Lead
      agent file's "Your Knowledge Sources" block.
- [ ] 1.3 Replace the "no routing table matches" language in the Tech Lead
      with language aligned to the new model (matches come from description
      plus overrides).
- [ ] 1.4 Keep the Phase 1 output format documented at `agents/tech-lead.md`
      (`## Consultation Requests`, `### <specialist>`, `**Agent:**`,
      `**Prompt:**`, `## Next Step`) unchanged.

## 2. Routing Procedure

- [ ] 2.1 Document the matching procedure (read registered list, read each
      referenced agent file, substring-match against description, overlay
      overrides) in the Tech Lead agent file, under Implementation Planning,
      Incident Analysis Consultation, and Retrospective Consultation response
      modes.
- [ ] 2.2 Document the file-read failure behavior (skip specialist, surface
      warning in Phase 1 output) as a routing invariant.
- [ ] 2.3 Document the "unregistered specialist gap" behavior (surface a gap
      in Implementation Constraints or Escalation Flags; never invent a
      consultation request for an unregistered agent).

## 3. `/add-specialist` Skill

- [ ] 3.1 Update the skill's input parsing: first argument is the agent name;
      remaining arguments are project-local code-area overrides. Trigger
      phrases are no longer a documented input form.
- [ ] 3.2 Implement the "register only" path: with a single argument, add the
      agent to `## Registered Specialists` and make no changes to the
      overrides table.
- [ ] 3.3 Implement the "register plus overrides" path: with additional
      arguments, append rows to `## Project Code Area Overrides`.
- [ ] 3.4 Implement the duplicate-with-description warning: for each override
      argument, check whether the string appears in the target agent's
      description and warn the user before writing the row.
- [ ] 3.5 Preserve backward compatibility: trigger-keyword-style arguments
      still work but emit a warning suggesting the keyword belongs in the
      agent description.
- [ ] 3.6 Update the skill's output summary to reflect the two new sections.

## 4. `/onboard` Skill

- [ ] 4.1 Remove the per-specialist signal question in Step 4 (Specialist
      Discovery). Ask only for agent names.
- [ ] 4.2 For each named agent, invoke `/add-specialist <name>` with no
      overrides.
- [ ] 4.3 Update the Step 5 summary message to mention
      `/audit-routing-table` as a follow-up hygiene step.
- [ ] 4.4 Update the "update specific sections" path to account for the new
      memory file shape.

## 5. `/audit-routing-table` Skill (new)

- [ ] 5.1 Create `skills/audit-routing-table/` with `SKILL.md` scaffold:
      frontmatter (`name`, `description`, `user-invokable: true`,
      `argument-hint`, `allowed-tools: Read, Glob, Grep`).
- [ ] 5.2 Implement the orphan-overrides check (override rows referencing a
      specialist not in `## Registered Specialists`).
- [ ] 5.3 Implement the broken-pointer check (registered specialist whose
      referenced agent file cannot be read).
- [ ] 5.4 Implement the redundant-overrides check (override signal substring
      found in target agent's description).
- [ ] 5.5 Implement the thin-description check (agent description under the
      word-count threshold).
- [ ] 5.6 Output a structured report: each finding with explanation and
      recommended action. No auto-fix.

## 6. Migration Guidance

- [ ] 6.1 Document the manual migration path in the change's `design.md` and
      in a `MIGRATION.md` under the skill directory (or equivalent) for
      existing projects.
- [ ] 6.2 Note that `/audit-routing-table` doubles as a migration helper for
      projects converting from the old routing table format.

## 7. Testing and Validation

- [ ] 7.1 Manual test: register a new specialist with `/add-specialist
      <name>`; confirm the Tech Lead produces consultation requests for issues
      whose text matches the agent's description phrases.
- [ ] 7.2 Manual test: register a specialist and add a project-local override
      (`/add-specialist payments-specialist "src/payments/**"`); confirm the
      Tech Lead emits a consultation request for an issue that references
      `src/payments/` even when the issue text does not mention payments.
- [ ] 7.3 Manual test: delete a registered specialist's agent file; confirm
      Phase 1 output surfaces the read-failure warning and the remaining
      specialists still route correctly.
- [ ] 7.4 Manual test: run `/audit-routing-table` on a project with an orphan
      override, a broken pointer, a redundant override, and a thin-description
      specialist; confirm all four are flagged with correct recommendations.
- [ ] 7.5 Regression test: run `/plan-implementation` on an issue that would
      previously have matched routing-table entries; confirm the Phase 1
      output is still parseable and Phase 2 synthesis still runs.

## 8. Documentation

- [ ] 8.1 Update `agents/tech-lead.md`'s "Your Knowledge Sources" section and
      "Response Modes" to reflect the new routing model.
- [ ] 8.2 Update `skills/add-specialist/SKILL.md` to describe the new input
      contract and the duplicate-trigger warning.
- [ ] 8.3 Update `skills/onboard/SKILL.md` for the simplified Step 4 flow.
- [ ] 8.4 Add a README-level pointer to `/audit-routing-table` alongside the
      other routing-related skills.

## 9. Release

- [ ] 9.1 Run the PR Review Toolkit (`pr-review-toolkit:review-pr`) against
      the staged changes per CLAUDE.md.
- [ ] 9.2 Address any review findings.
- [ ] 9.3 Bump the plugin version in `marketplace.json` per the versioning
      convention.
- [ ] 9.4 Commit, push, open PR.
