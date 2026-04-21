# Routing Outcome Capture

## ADDED Requirements

### Requirement: Phase 2 output carries a per-specialist routing value

The Tech Lead's Phase 2 synthesis output SHALL include a parseable
`**Routing Value:**` line inside every `### <Specialist Name>`
subsection under `## Specialist Consultations`. The value MUST be one
of the fixed strings `high`, `medium`, `low`, or `none`. The line MUST
appear once per specialist subsection and MUST NOT appear outside a
specialist subsection.

An optional `**Routing Note:**` line MAY appear on the line immediately
following `**Routing Value:**`. The note is a single line of free text,
no longer than one sentence, that explains why the value was chosen.
The rubric strongly recommends populating the note whenever the value
is `low` or `none`.

All existing Phase 2 anchors (`## Engagement Depth`,
`## Specialist Consultations`, `## Escalation Flags`,
`## Implementation Constraints`, `## Recommended Approach`) remain in
place unchanged so that existing readers of the Phase 2 contract
continue to work.

#### Scenario: Value line appears per specialist

- **WHEN** the Tech Lead produces Phase 2 output for a story that
  involved three specialists
- **THEN** each of the three `### <Specialist Name>` subsections under
  `## Specialist Consultations` contains exactly one
  `**Routing Value:**` line, and the value on each line is one of
  `high`, `medium`, `low`, or `none`

#### Scenario: Note line is optional and single-sentence

- **WHEN** the Tech Lead produces Phase 2 output that grades a
  specialist as `none` with a short explanatory note
- **THEN** a `**Routing Note:**` line appears immediately after the
  `**Routing Value:**` line, the note is a single sentence, and the
  rest of the specialist subsection continues as documented

#### Scenario: Existing anchors preserved

- **WHEN** any consumer parses a Phase 2 output for the anchors
  `## Specialist Consultations`, `## Escalation Flags`,
  `## Implementation Constraints`, and `## Recommended Approach`
- **THEN** all four anchors are present in the documented order, and
  the new `**Routing Value:**` line does not appear outside the
  `## Specialist Consultations` subsections

### Requirement: Routing value grading rubric

The plugin SHALL document a grading rubric that defines what each
value (`high`, `medium`, `low`, `none`) means, so the Tech Lead's
grading is reasonably consistent across runs. The rubric MUST cover
at minimum:

- `high`: the specialist's response materially shifted the plan
  (introduced or rejected a named trade-off, contradicted a default,
  or unblocked a specific decision the synthesis adopted).
- `medium`: the specialist's response added concrete constraints or
  trade-offs the plan incorporated, without shifting overall
  direction.
- `low`: the specialist's response confirmed existing direction or
  added context only, without changing the plan's substance.
- `none`: the specialist explicitly disclaimed relevance, returned
  an empty or error response, or returned content that did not
  apply to the story at all.

The rubric MUST include a "grade down when in doubt" convention
that biases toward the lower of two candidate values when the
synthesis has no clear signal either way. The rubric MUST state
that the signal is about routing fit (trigger conditions over- or
under-matching), not about specialist output quality.

#### Scenario: Rubric documented in the capability spec

- **WHEN** a reader inspects the `routing-outcome-capture`
  capability's spec
- **THEN** the rubric lists all four values with the semantics
  above, the "grade down when in doubt" convention, and the
  routing-fit-not-quality scope note

#### Scenario: Agent definition references the rubric

- **WHEN** a reader inspects `agents/tech-lead.md`
- **THEN** the agent definition references the rubric's location in
  the capability spec rather than duplicating the rubric inline, so
  the two documents cannot drift apart

### Requirement: Routing Outcomes memory section schema

The Tech Lead's project memory file SHALL include a
`## Routing Outcomes` section once any outcome row has been
appended. The memory file path is
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`.
The section is a markdown table with exactly five columns in this
order:

```markdown
| Date | Story Slug | Specialist | Value | Note |
|------|------------|------------|-------|------|
```

- `Date` is an ISO-8601 date (`YYYY-MM-DD`) captured at the moment
  the row is appended.
- `Story Slug` is a slug derived from the input story that drove the
  plan. The derivation order is: front-matter `slug` field, then
  filename without extension, then the first heading slugified. If
  no candidate is resolvable, the slug is `unknown-slug`.
- `Specialist` is the agent slug (for example `qa-lead`).
- `Value` is one of `high`, `medium`, `low`, `none`.
- `Note` is the single-sentence note from `**Routing Note:**`, or
  empty.

The section is append-only during plans. Rows are never edited in
place; they are only added by `/plan-implementation` after Phase 2
synthesis and, for roll-up, by `/audit-routing-quality` when the
user explicitly confirms.

#### Scenario: Section schema matches the contract

- **WHEN** a row is appended to an empty or missing section
- **THEN** the section header is `## Routing Outcomes`, the column
  header row lists `Date | Story Slug | Specialist | Value | Note` in
  that order, and the separator row matches the markdown-table
  convention

#### Scenario: Append-only semantics

- **WHEN** `/plan-implementation` appends rows during a plan
- **THEN** the skill only adds rows; no existing row is modified or
  removed by the skill

#### Scenario: Rows include all five columns

- **WHEN** an outcome row is written for any specialist
- **THEN** the row contains values for `Date`, `Story Slug`,
  `Specialist`, `Value`, and `Note`, with `Note` left empty when
  the source Phase 2 subsection had no `**Routing Note:**` line

### Requirement: Outcome capture does not block plans

The Tech Lead and `/plan-implementation` MUST NOT allow outcome
capture to block, delay, or discard a Phase 2 synthesis. If the
Tech Lead cannot grade a specialist (for example, it judges the
response is too ambiguous to grade), the value `none` with a
descriptive note is emitted rather than omitting the line. If
`/plan-implementation` cannot parse a `**Routing Value:**` line,
the skill surfaces a notice and returns the full Phase 2 output
unchanged.

#### Scenario: Ambiguous response still grades

- **WHEN** the Tech Lead synthesizes a plan where one specialist's
  response was present but its applicability is unclear
- **THEN** the corresponding `**Routing Value:**` line still emits
  one of the four fixed values, accompanied by a
  `**Routing Note:**` line explaining the ambiguity

#### Scenario: Parse failure surfaces a notice

- **WHEN** `/plan-implementation` cannot parse the
  `**Routing Value:**` line for one or more specialists
- **THEN** the skill's output includes a one-line notice naming the
  affected specialists, the Phase 2 synthesis is returned to the
  caller, and no outcome row is appended for the unparseable
  specialists
