# Audit Routing Quality Skill

## ADDED Requirements

### Requirement: Skill identity and surface

The plugin SHALL provide a user-invokable skill named
`audit-routing-quality` located at
`skills/audit-routing-quality/SKILL.md`. The skill's allowed tools
MUST be limited to `Read`, `Glob`, `Grep`, and `Edit` (the last only
for the user-confirmed roll-up path). The skill MUST NOT depend on
any other agent or skill at runtime beyond reading the Tech Lead's
memory file.

The skill's argument hint MUST be empty (no arguments required).
The skill MUST be advertised in the plugin's top-level documentation
alongside `/audit-routing-table` so users can distinguish the two:
`/audit-routing-table` runs structural hygiene checks;
`/audit-routing-quality` runs outcome-based narrowing recommendations.

#### Scenario: Skill is registered and discoverable

- **WHEN** a user views available skills in the plugin
- **THEN** `audit-routing-quality` appears with a description that
  distinguishes it from `audit-routing-table`

#### Scenario: Allowed tools are limited

- **WHEN** a reader inspects `skills/audit-routing-quality/SKILL.md`
  frontmatter
- **THEN** `allowed-tools` lists only `Read`, `Glob`, `Grep`, `Edit`
  and the skill does not reference the `Agent` tool or any
  specialist-invocation primitives

### Requirement: Skill reads aggregated outcome history

The skill SHALL read the `## Routing Outcomes` table from
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md` and
aggregate the rows by specialist. For each specialist the skill MUST
compute at minimum:

- Total consultation count (row count).
- Count per value bucket (`high`, `medium`, `low`, `none`).
- A narrowing-signal score: the sum of `low` and `none` counts
  expressed both as an absolute count and as a percentage of total.
- The most recent five `Note` entries associated with `low` and
  `none` grades, if present, so the user can see representative
  reasons.

If the `## Routing Outcomes` section is missing or empty, the skill
MUST emit the notice "No routing outcome history recorded yet." and
exit without error. If the memory file does not exist, the skill
MUST emit the notice "No Tech Lead memory file found. Run /onboard
or /add-specialist to create one." and exit without error.

#### Scenario: Aggregates per specialist

- **WHEN** the memory file contains a `## Routing Outcomes` section
  with at least one row per specialist
- **THEN** the skill's report includes, for each specialist, the
  total count, the per-value counts, and the narrowing-signal score

#### Scenario: Missing section is handled

- **WHEN** the memory file exists but contains no
  `## Routing Outcomes` section
- **THEN** the skill emits the "No routing outcome history recorded
  yet." notice and exits without error

#### Scenario: Missing memory file is handled

- **WHEN** the memory file does not exist
- **THEN** the skill emits the documented "No Tech Lead memory file
  found" notice and exits without error

### Requirement: Skill recommends narrowing actions, never edits routing

The skill SHALL produce a report with one section per specialist
whose narrowing-signal score exceeds a configurable threshold
(default: fifty percent of total consultations are `low` or `none`,
with a minimum of five consultations recorded). For each
recommended narrowing, the report MUST include:

- The specialist name and observed counts.
- One or more suggested narrowing actions: tighten description
  vocabulary, remove redundant Code Area Overrides, consider
  deregistering, or add a negative-match pattern.
- The specific change the user would make (for example, "remove the
  `**Triggers:**` phrase `<phrase>` from the specialist's
  description" or "remove the override row `<row>` from
  `## Project Code Area Overrides`").

The skill MUST NOT modify the Tech Lead's memory file's
`## Registered Specialists` or `## Project Code Area Overrides`
sections, the specialist agent files, or any other file, as part of
generating its recommendations. The user applies recommendations by
hand or through other skills.

#### Scenario: High-signal specialist gets a recommendation

- **WHEN** a specialist has ten consultations with seven `none` or
  `low` values and three `medium` values
- **THEN** the skill's report includes a section for that
  specialist with counts, the narrowing-signal score, and one or
  more specific narrowing actions naming vocabulary or overrides to
  consider tightening

#### Scenario: Below-threshold specialist is skipped

- **WHEN** a specialist has three total consultations
- **THEN** the skill's report does not include a narrowing
  recommendation for that specialist, because the minimum
  consultation count has not been met

#### Scenario: Skill never edits routing tables without confirmation

- **WHEN** the skill generates recommendations
- **THEN** the Tech Lead's `## Registered Specialists` and
  `## Project Code Area Overrides` sections are unchanged, and the
  report advises the user of the exact edits to apply

### Requirement: User-confirmed retention roll-up at 200 rows

The skill SHALL offer a user-confirmed roll-up whenever the
`## Routing Outcomes` table contains more than 200 rows. Rows older
than the most-recent 50 are condensed into summary rows, one per
specialist, with aggregated counts per value bucket. The skill MUST
request explicit user confirmation before performing any roll-up.
If the user declines, the table remains unchanged.

Each roll-up summary row MUST carry the format:

```markdown
| <rolled-up-date-range> | ROLLUP | <specialist> | <value-counts> | summarized N rows |
```

where `<value-counts>` is the aggregated `high=X medium=Y low=Z
none=W` tally for the rolled rows and the `Note` column records
the source row count. Roll-up rows MUST sit above the preserved
recent rows in file order so the table reads oldest-to-newest.

#### Scenario: Roll-up is offered at the threshold

- **WHEN** the table contains 250 rows
- **THEN** the skill reports the current row count and offers a
  roll-up that would condense the oldest 200 rows (anything beyond
  the most-recent 50) into one summary row per specialist

#### Scenario: User declines the roll-up

- **WHEN** the user declines the roll-up offer
- **THEN** the skill leaves the `## Routing Outcomes` table
  unchanged and continues producing its narrowing recommendations
  from the full history

#### Scenario: Confirmed roll-up produces summary rows

- **WHEN** the user confirms the roll-up offer
- **THEN** the skill replaces the rolled rows with one summary row
  per specialist, preserves the most-recent 50 rows verbatim, and
  each summary row uses the documented `ROLLUP` format with
  aggregated counts

### Requirement: Report output is advisory and deterministic

The skill SHALL produce a markdown report as its final output. The
report MUST include at minimum these sections in this order:

1. A one-paragraph summary of the data (total rows, date range,
   specialist count).
2. A "Narrowing Recommendations" section with one subsection per
   flagged specialist.
3. A "Specialists Below Threshold" section listing specialists with
   insufficient data to recommend on.
4. A "Next Actions" footer summarizing what the user can do.

Running the skill twice against the same memory file and the same
threshold MUST produce reports with the same flagged specialists
and the same recommendations. The skill MUST NOT introduce
nondeterministic ordering (specialists are ordered by
narrowing-signal score descending, ties broken by total count
descending, ties broken by alphabetical specialist name).

#### Scenario: Report structure is stable

- **WHEN** the skill runs against a memory file with mixed
  specialists
- **THEN** the report contains the four named sections in order,
  and each flagged specialist has a named recommendation block

#### Scenario: Deterministic ordering

- **WHEN** the skill is run twice against the same memory file and
  the same threshold configuration
- **THEN** both runs produce the same set of flagged specialists,
  in the same order, with the same recommended actions
## Requirements
### Requirement: Skill identity and surface

The plugin SHALL provide a user-invokable skill named
`audit-routing-quality` located at
`skills/audit-routing-quality/SKILL.md`. The skill's allowed tools
MUST be limited to `Read`, `Glob`, `Grep`, and `Edit` (the last only
for the user-confirmed roll-up path). The skill MUST NOT depend on
any other agent or skill at runtime beyond reading the Tech Lead's
memory file.

The skill's argument hint MUST be empty (no arguments required).
The skill MUST be advertised in the plugin's top-level documentation
alongside `/audit-routing-table` so users can distinguish the two:
`/audit-routing-table` runs structural hygiene checks;
`/audit-routing-quality` runs outcome-based narrowing recommendations.

#### Scenario: Skill is registered and discoverable

- **WHEN** a user views available skills in the plugin
- **THEN** `audit-routing-quality` appears with a description that
  distinguishes it from `audit-routing-table`

#### Scenario: Allowed tools are limited

- **WHEN** a reader inspects `skills/audit-routing-quality/SKILL.md`
  frontmatter
- **THEN** `allowed-tools` lists only `Read`, `Glob`, `Grep`, `Edit`
  and the skill does not reference the `Agent` tool or any
  specialist-invocation primitives

### Requirement: Skill reads aggregated outcome history

The skill SHALL read the `## Routing Outcomes` table from
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md` and
aggregate the rows by specialist. For each specialist the skill MUST
compute at minimum:

- Total consultation count (row count).
- Count per value bucket (`high`, `medium`, `low`, `none`).
- A narrowing-signal score: the sum of `low` and `none` counts
  expressed both as an absolute count and as a percentage of total.
- The most recent five `Note` entries associated with `low` and
  `none` grades, if present, so the user can see representative
  reasons.

If the `## Routing Outcomes` section is missing or empty, the skill
MUST emit the notice "No routing outcome history recorded yet." and
exit without error. If the memory file does not exist, the skill
MUST emit the notice "No Tech Lead memory file found. Run /onboard
or /add-specialist to create one." and exit without error.

#### Scenario: Aggregates per specialist

- **WHEN** the memory file contains a `## Routing Outcomes` section
  with at least one row per specialist
- **THEN** the skill's report includes, for each specialist, the
  total count, the per-value counts, and the narrowing-signal score

#### Scenario: Missing section is handled

- **WHEN** the memory file exists but contains no
  `## Routing Outcomes` section
- **THEN** the skill emits the "No routing outcome history recorded
  yet." notice and exits without error

#### Scenario: Missing memory file is handled

- **WHEN** the memory file does not exist
- **THEN** the skill emits the documented "No Tech Lead memory file
  found" notice and exits without error

### Requirement: Skill recommends narrowing actions, never edits routing

The skill SHALL produce a report with one section per specialist
whose narrowing-signal score exceeds a configurable threshold
(default: fifty percent of total consultations are `low` or `none`,
with a minimum of five consultations recorded). For each
recommended narrowing, the report MUST include:

- The specialist name and observed counts.
- One or more suggested narrowing actions: tighten description
  vocabulary, remove redundant Code Area Overrides, consider
  deregistering, or add a negative-match pattern.
- The specific change the user would make (for example, "remove the
  `**Triggers:**` phrase `<phrase>` from the specialist's
  description" or "remove the override row `<row>` from
  `## Project Code Area Overrides`").

The skill MUST NOT modify the Tech Lead's memory file's
`## Registered Specialists` or `## Project Code Area Overrides`
sections, the specialist agent files, or any other file, as part of
generating its recommendations. The user applies recommendations by
hand or through other skills.

#### Scenario: High-signal specialist gets a recommendation

- **WHEN** a specialist has ten consultations with seven `none` or
  `low` values and three `medium` values
- **THEN** the skill's report includes a section for that
  specialist with counts, the narrowing-signal score, and one or
  more specific narrowing actions naming vocabulary or overrides to
  consider tightening

#### Scenario: Below-threshold specialist is skipped

- **WHEN** a specialist has three total consultations
- **THEN** the skill's report does not include a narrowing
  recommendation for that specialist, because the minimum
  consultation count has not been met

#### Scenario: Skill never edits routing tables without confirmation

- **WHEN** the skill generates recommendations
- **THEN** the Tech Lead's `## Registered Specialists` and
  `## Project Code Area Overrides` sections are unchanged, and the
  report advises the user of the exact edits to apply

### Requirement: User-confirmed retention roll-up at 200 rows

The skill SHALL offer a user-confirmed roll-up whenever the
`## Routing Outcomes` table contains more than 200 rows. Rows older
than the most-recent 50 are condensed into summary rows, one per
specialist, with aggregated counts per value bucket. The skill MUST
request explicit user confirmation before performing any roll-up.
If the user declines, the table remains unchanged.

Each roll-up summary row MUST carry the format:

```markdown
| <rolled-up-date-range> | ROLLUP | <specialist> | <value-counts> | summarized N rows |
```

where `<value-counts>` is the aggregated `high=X medium=Y low=Z
none=W` tally for the rolled rows and the `Note` column records
the source row count. Roll-up rows MUST sit above the preserved
recent rows in file order so the table reads oldest-to-newest.

#### Scenario: Roll-up is offered at the threshold

- **WHEN** the table contains 250 rows
- **THEN** the skill reports the current row count and offers a
  roll-up that would condense the oldest 200 rows (anything beyond
  the most-recent 50) into one summary row per specialist

#### Scenario: User declines the roll-up

- **WHEN** the user declines the roll-up offer
- **THEN** the skill leaves the `## Routing Outcomes` table
  unchanged and continues producing its narrowing recommendations
  from the full history

#### Scenario: Confirmed roll-up produces summary rows

- **WHEN** the user confirms the roll-up offer
- **THEN** the skill replaces the rolled rows with one summary row
  per specialist, preserves the most-recent 50 rows verbatim, and
  each summary row uses the documented `ROLLUP` format with
  aggregated counts

### Requirement: Report output is advisory and deterministic

The skill SHALL produce a markdown report as its final output. The
report MUST include at minimum these sections in this order:

1. A one-paragraph summary of the data (total rows, date range,
   specialist count).
2. A "Narrowing Recommendations" section with one subsection per
   flagged specialist.
3. A "Specialists Below Threshold" section listing specialists with
   insufficient data to recommend on.
4. A "Next Actions" footer summarizing what the user can do.

Running the skill twice against the same memory file and the same
threshold MUST produce reports with the same flagged specialists
and the same recommendations. The skill MUST NOT introduce
nondeterministic ordering (specialists are ordered by
narrowing-signal score descending, ties broken by total count
descending, ties broken by alphabetical specialist name).

#### Scenario: Report structure is stable

- **WHEN** the skill runs against a memory file with mixed
  specialists
- **THEN** the report contains the four named sections in order,
  and each flagged specialist has a named recommendation block

#### Scenario: Deterministic ordering

- **WHEN** the skill is run twice against the same memory file and
  the same threshold configuration
- **THEN** both runs produce the same set of flagged specialists,
  in the same order, with the same recommended actions

