# Plan-Implementation Skill

## ADDED Requirements

### Requirement: Post-Phase-2 outcome capture

The `/plan-implementation` skill SHALL append one row per
specialist to the `## Routing Outcomes` section of the Tech Lead's
memory file after Phase 2 synthesis completes successfully. The
append step runs only on the success path: when Phase 2 produced
output that the skill could parse into specialist subsections. The
skill MUST NOT append rows on the no-match path (no specialists
consulted) or the parse-failure path (Phase 1 output could not be
parsed against the expected contract).

Each row MUST contain values for `Date`, `Story Slug`,
`Specialist`, `Value`, and `Note` as defined in the
`routing-outcome-capture` capability. The story slug MUST be
derived using the documented order: front-matter `slug` field,
then filename without extension, then the first heading
slugified, then `unknown-slug` as a fallback.

The append step MUST NOT modify the Phase 2 synthesis content
returned to the caller; the synthesis is returned to the user as
before, with the append occurring as a side effect.

#### Scenario: Success path appends one row per specialist

- **WHEN** `/plan-implementation` completes Phase 2 synthesis with
  three specialists, each carrying a `**Routing Value:**` line
- **THEN** the skill appends three rows to the
  `## Routing Outcomes` section in the Tech Lead's memory file,
  one per specialist, each row containing the five documented
  columns

#### Scenario: No-match path appends nothing

- **WHEN** `/plan-implementation` takes the no-match path because
  Phase 1 produced no consultation requests
- **THEN** the skill does not append any row to
  `## Routing Outcomes`, because there is nothing to grade

#### Scenario: Parse-failure path appends nothing

- **WHEN** `/plan-implementation` takes the parse-failure path
  because Phase 1 output lacked the required anchors
- **THEN** the skill does not append any row to
  `## Routing Outcomes`, because Phase 2 did not run

### Requirement: Parse failures in the append step are non-fatal

The skill SHALL treat failures inside the outcome-append step as
non-fatal. If the Tech Lead's Phase 2 output lacks a
`**Routing Value:**` line for one or more specialists, or the
value is not in the fixed vocabulary, the skill MUST:

- Emit a one-line notice in its output identifying the affected
  specialists.
- Append rows for specialists whose values parsed successfully.
- Skip appending for specialists whose values failed to parse.
- Return the full Phase 2 synthesis to the caller unchanged.

A failure to write to the memory file (for example, because the
file is read-only) MUST NOT prevent the skill from returning the
Phase 2 synthesis. The write failure is surfaced as a notice, and
the plan still reaches the user.

#### Scenario: Partial parse failure surfaces a notice

- **WHEN** Phase 2 output contains `**Routing Value:**` lines for
  two of three specialists, with the third specialist's line
  missing
- **THEN** the skill appends two rows (for the parseable
  specialists), surfaces a notice naming the third specialist as
  unparseable, and returns the full Phase 2 synthesis to the
  caller

#### Scenario: Write failure does not discard the plan

- **WHEN** the Tech Lead's memory file cannot be written during
  the append step
- **THEN** the skill surfaces a notice identifying the write
  failure and still returns the Phase 2 synthesis to the caller

### Requirement: Append step creates the section when missing

The skill SHALL create the `## Routing Outcomes` section on first
append when the section does not exist in the memory file. The
created section MUST consist of:

- A `## Routing Outcomes` heading.
- The documented column header row
  `| Date | Story Slug | Specialist | Value | Note |`.
- The markdown-table separator row.
- One row per specialist with parsed values.

The skill MUST NOT reorder existing sections in the memory file
when creating the outcomes section; the new section is appended
at the end of the file or after the last existing
top-level-`##` section, whichever is consistent with the file's
current structure.

#### Scenario: First append creates header and separator

- **WHEN** the memory file exists and contains
  `## Registered Specialists` and `## Project Code Area Overrides`
  but no `## Routing Outcomes` section
- **THEN** the skill appends the `## Routing Outcomes` heading,
  the column header row, and the separator row, followed by one
  row per graded specialist

#### Scenario: Subsequent append does not duplicate the header

- **WHEN** the memory file already contains a
  `## Routing Outcomes` section with previous rows
- **THEN** the skill appends new rows after the existing rows, and
  does not duplicate the section header, column header row, or
  separator row
