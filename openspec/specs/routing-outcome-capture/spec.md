# Spec: Routing Outcome Capture

## Identity

- **Owner agent:** `tech-lead`
- **Consumers:** `/plan-implementation` (append), `/audit-routing-quality` (read
  and user-confirmed roll-up)
- **Memory file:**
  `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`

## Purpose

Define the mechanism by which the Tech Lead records a per-specialist routing
value during Phase 2 synthesis, the schema of the `## Routing Outcomes` memory
section that persists those values, and the grading rubric that keeps the values
reasonably consistent across Tech Lead runs.

## Routing Value Grading Rubric

The per-specialist routing value uses a fixed four-value vocabulary. The value
is assigned by the Tech Lead during Phase 2 synthesis, after reading the
specialist's response. It reflects how much the specialist's response affected
the final plan.

### Values

| Value | Meaning |
|-------|---------|
| `high` | The specialist's response materially shifted the plan: it introduced or rejected a named trade-off that the synthesis adopted, contradicted a default the Tech Lead would have chosen, or unblocked a specific design decision. |
| `medium` | The specialist's response added concrete constraints or trade-offs the plan incorporated, without shifting overall direction. |
| `low` | The specialist's response confirmed existing direction or added context only, without changing the plan's substance. |
| `none` | The specialist explicitly disclaimed relevance, returned an empty or error response, or returned content that did not apply to the story at all. |

### Grade Down When in Doubt

When the synthesis has no clear signal either way between two candidate values,
choose the lower value. Specifically:

- If uncertain between `high` and `medium`, choose `medium`.
- If uncertain between `medium` and `low`, choose `low`.
- If uncertain between `low` and `none`, choose `none`.

This convention biases toward conservative grading. A specialist that is
consistently graded `low` under this convention is highly likely to actually be
over-routed.

### Scope: Routing Fit, Not Specialist Quality

The routing value measures whether the trigger conditions correctly matched the
story, not whether the specialist provided good advice. A specialist that gives
an excellent, well-reasoned response explaining why nothing in the story
requires their attention grades `none`. A specialist that gives a one-sentence
constraint that the plan adopts grades `high`. The grading signal belongs to
the routing table, not to the specialist's performance.

## `## Routing Outcomes` Section Schema

The Tech Lead's project memory file includes a `## Routing Outcomes` section
once any row has been appended. The section is an append-only markdown table
with exactly five columns in this order:

```markdown
| Date       | Story Slug          | Specialist    | Value  | Note                         |
|------------|---------------------|---------------|--------|------------------------------|
| 2026-04-21 | add-retry-logic     | qa-lead       | medium | Added flake-resistance notes |
| 2026-04-21 | add-retry-logic     | devops-lead   | none   | No runtime concerns          |
```

Column definitions:

- **`Date`**: ISO-8601 date (`YYYY-MM-DD`) captured at the moment the row is
  appended.
- **`Story Slug`**: a slug derived from the input story that drove the plan.
  Derivation order: front-matter `slug` field, then filename without extension,
  then first heading slugified, then `unknown-slug` as a fallback.
- **`Specialist`**: the agent slug (for example `qa-lead`).
- **`Value`**: one of `high`, `medium`, `low`, `none`.
- **`Note`**: the single-sentence note from the `**Routing Note:**` line in the
  Phase 2 output, or empty when the source subsection had no note line. The
  rubric strongly recommends populating the note for `low` and `none` grades.

## Append-Only Semantics

Rows in `## Routing Outcomes` are appended, never edited in place. The only
operations permitted on the section are:

1. **Row append**: by `/plan-implementation` after successful Phase 2
   synthesis.
2. **User-confirmed roll-up**: by `/audit-routing-quality` when the row count
   exceeds the documented retention threshold of 200 rows.

No other skill, agent, or automated process may modify the section. In
particular, `/audit-routing-table`, `/add-specialist`, and `/onboard` must
leave the section untouched when they run.

## Phase 2 Output Contract Extension

The Tech Lead's Phase 2 synthesis output includes two new per-specialist lines
inside each `### <Specialist Name>` subsection under `## Specialist
Consultations`:

- **`**Routing Value:**`** (required): one of `high`, `medium`, `low`, `none`.
  This line must appear once per specialist subsection and must not appear
  outside a specialist subsection.
- **`**Routing Note:**`** (optional): a single-sentence note explaining the
  value choice. Strongly recommended for `low` and `none` grades. When present,
  this line appears immediately after `**Routing Value:**`.

The existing Phase 2 anchors remain in place unchanged: `## Engagement Depth`,
`## Specialist Consultations`, `## Escalation Flags`,
`## Implementation Constraints`, `## Recommended Approach`.

## Retention Policy

When the `## Routing Outcomes` table exceeds 200 rows, `/audit-routing-quality`
offers the user a roll-up. Rows older than the most-recent 50 are condensed into
summary rows, one per specialist, with aggregated counts per value bucket. The
roll-up is user-confirmed; the skill never rewrites the table without explicit
permission.

Each roll-up summary row uses the format:

```markdown
| <rolled-up-date-range> | ROLLUP | <specialist> | <value-counts> | summarized N rows |
```

where `<value-counts>` is the aggregated `high=X medium=Y low=Z none=W` tally
for the rolled rows and the `Note` column records the source row count.
Roll-up rows sit above the preserved recent rows in file order so the table
reads oldest-to-newest.

## Non-Requirements

- The grading rubric is descriptive, not algorithmic. Different Tech Lead runs
  may grade similar stories differently; the "grade down when in doubt"
  convention counterweights this.
- Outcome history does not feed the routing decision. The Tech Lead does not
  consult `## Routing Outcomes` when computing Phase 1 match candidates.
- Cross-project aggregation is out of scope. Outcomes live in the Tech Lead's
  project-local memory only.
- Automated routing-table edits are out of scope. `/audit-routing-quality` is
  advisory only.
## Requirements
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

