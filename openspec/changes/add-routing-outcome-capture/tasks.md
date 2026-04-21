# Tasks

## 1. Document the grading rubric

- [ ] 1.1 Add a "Routing Value Grading Rubric" subsection to the
      `routing-outcome-capture` spec in
      `openspec/specs/routing-outcome-capture/spec.md` once the
      change is archived, capturing the four values (`high`,
      `medium`, `low`, `none`) with the documented semantics
- [ ] 1.2 Include the "grade down when in doubt" convention and
      the explicit scope note that the signal is about routing
      fit, not specialist output quality
- [ ] 1.3 Cross-check the rubric wording against the existing
      Tech Lead convention vocabulary in `agents/tech-lead.md` and
      adjust terminology so the rubric reads as a continuation of
      the Tech Lead's voice rather than a new document

## 2. Extend the Tech Lead agent definition

- [ ] 2.1 Add a "Routing Value Grading" subsection to
      `agents/tech-lead.md` inside the Implementation Planning
      response mode, positioned inside the Phase 2 synthesis
      procedure
- [ ] 2.2 Document that each `### <Specialist Name>` subsection
      under `## Specialist Consultations` MUST end with a
      `**Routing Value:**` line whose value is one of `high`,
      `medium`, `low`, `none`
- [ ] 2.3 Document the optional `**Routing Note:**` line that MAY
      follow `**Routing Value:**`, including the recommendation to
      always populate the note for `low` and `none` grades
- [ ] 2.4 Reference the grading rubric in the
      `routing-outcome-capture` capability spec rather than
      duplicating the rubric content in the agent file
- [ ] 2.5 Update the Parseable Phase 2 Output Contract (or
      equivalent synthesis-output contract) to list
      `**Routing Value:**` as a required per-specialist anchor and
      `**Routing Note:**` as an optional anchor
- [ ] 2.6 Add a worked example specialist subsection to the agent
      file showing the `**Routing Value:**` and `**Routing Note:**`
      lines in context so the format is unambiguous

## 3. Document the Routing Outcomes memory section

- [ ] 3.1 Update `openspec/specs/tech-lead-routing/spec.md` (once
      the change is archived) to document `## Routing Outcomes` as
      a recognized memory section with the schema defined in the
      `routing-outcome-capture` capability
- [ ] 3.2 Add invariants documenting that the Tech Lead routing
      procedure does not read `## Routing Outcomes` when computing
      match candidates
- [ ] 3.3 Add invariants documenting that only
      `/plan-implementation` (append) and `/audit-routing-quality`
      (user-confirmed roll-up) may modify the section

## 4. Extend `/plan-implementation`

- [ ] 4.1 Edit `skills/plan-implementation/SKILL.md` to add a
      post-Phase-2 step: parse each `### <Specialist Name>`
      subsection under `## Specialist Consultations` to extract
      the `**Routing Value:**` line and optional
      `**Routing Note:**` line
- [ ] 4.2 Document the slug-derivation order in the skill
      (front-matter `slug`, then filename, then first heading
      slugified, then `unknown-slug`)
- [ ] 4.3 Document the append-only write to
      `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`
      including creating the `## Routing Outcomes` section on first
      write with the documented header and separator rows
- [ ] 4.4 Document non-fatal handling for parse failures (skip
      unparseable specialists, surface a one-line notice, continue)
      and write failures (surface a notice, return the Phase 2
      synthesis unchanged)
- [ ] 4.5 Document that the append step runs only on the Phase-2
      success path; the no-match and parse-failure paths write
      nothing

## 5. Create the `/audit-routing-quality` skill

- [ ] 5.1 Create `skills/audit-routing-quality/SKILL.md` with YAML
      frontmatter (`name`, `description`, `user-invokable: true`,
      `argument-hint: ""`, `allowed-tools: Read, Glob, Grep, Edit`)
- [ ] 5.2 Document the skill's purpose, how it complements (and
      does not replace) `/audit-routing-table`, and when to run it
- [ ] 5.3 Document the read-and-aggregate step that parses
      `## Routing Outcomes` into per-specialist counts and
      narrowing-signal scores
- [ ] 5.4 Document the recommendation section, including the
      minimum consultation threshold (default five), the
      narrowing-signal threshold (default fifty percent `low` or
      `none`), and the specific narrowing actions the skill
      suggests
- [ ] 5.5 Document the user-confirmed roll-up flow at 200 rows,
      including the exact summary-row format with the `ROLLUP`
      marker and aggregated counts
- [ ] 5.6 Document the report structure (summary paragraph,
      narrowing recommendations, below-threshold specialists, next
      actions) and the deterministic ordering rules
- [ ] 5.7 Document graceful degradation for missing memory file
      and missing `## Routing Outcomes` section
- [ ] 5.8 Register the skill in `marketplace.json` so it is
      discoverable alongside `/audit-routing-table`

## 6. Public-voice updates

- [ ] 6.1 Add a "Audit Routing Quality" section to the top-level
      `README.md` that distinguishes the skill from
      `/audit-routing-table` and lists the kinds of findings it
      surfaces
- [ ] 6.2 Update the `agents/tech-lead.md` key-knowledge bullets
      or equivalent surface to mention the `## Routing Outcomes`
      memory section and the grading rubric
- [ ] 6.3 Cross-reference `/audit-routing-quality` from the
      existing `/plan-implementation` documentation so users see
      the feedback loop between consulting specialists and
      tightening routing

## 7. Validate contract compatibility

- [ ] 7.1 Confirm that existing Phase 2 output parsers use only
      the existing anchors (`## Specialist Consultations`,
      `### <Specialist Name>`, `**Agent:**`, `**Prompt:**`,
      `## Escalation Flags`, `## Implementation Constraints`,
      `## Recommended Approach`) and are not confused by the new
      `**Routing Value:**` line
- [ ] 7.2 Confirm `/audit-routing-table` leaves the
      `## Routing Outcomes` section untouched and does not include
      outcome rows in any finding
- [ ] 7.3 Confirm `/onboard` and `/add-specialist` preserve the
      `## Routing Outcomes` section verbatim

## 8. Internal consistency review

- [ ] 8.1 Re-read `agents/tech-lead.md` and confirm the grading
      rubric reference is a pointer, not a duplicate
- [ ] 8.2 Re-read `skills/plan-implementation/SKILL.md` and
      confirm the append step is documented as non-fatal on all
      failure paths
- [ ] 8.3 Re-read `skills/audit-routing-quality/SKILL.md` and
      confirm the skill is advisory, never auto-editing
      `## Registered Specialists` or `## Project Code Area
      Overrides`
- [ ] 8.4 Confirm no text changes were made to
      `skills/audit-routing-table/SKILL.md` aside from any
      cross-reference bullet added to distinguish the two skills

## 9. Manual verification

- [ ] 9.1 Dry-run `/plan-implementation` on a story that routes to
      three specialists and confirm Phase 2 output carries a
      `**Routing Value:**` line in each specialist subsection,
      confirm three rows appear in `## Routing Outcomes`, and
      confirm the story slug is derived correctly
- [ ] 9.2 Dry-run `/plan-implementation` on a story that routes to
      no specialists (no-match path) and confirm no rows are
      appended to `## Routing Outcomes`
- [ ] 9.3 Dry-run `/plan-implementation` with a Tech Lead output
      that lacks `**Routing Value:**` for one specialist and
      confirm the skill surfaces the documented notice, appends
      rows for the parseable specialists, and returns the Phase 2
      synthesis unchanged
- [ ] 9.4 Dry-run `/audit-routing-quality` against a memory file
      with fifteen outcome rows spanning three specialists and
      confirm the report includes aggregate counts, narrowing
      recommendations (or a below-threshold entry), and next
      actions
- [ ] 9.5 Dry-run `/audit-routing-quality` against a memory file
      with 250 rows and confirm the roll-up is offered, declining
      leaves the table untouched, and confirming produces summary
      rows in the documented format
- [ ] 9.6 Dry-run `/audit-routing-quality` against a memory file
      with no `## Routing Outcomes` section and confirm the
      documented "No routing outcome history recorded yet." notice
      is emitted without error
