# Tech Lead Routing

## ADDED Requirements

### Requirement: Routing Outcomes section in Tech Lead memory

The Tech Lead's memory file SHALL include a `## Routing Outcomes`
section once any row has been appended by `/plan-implementation` or
the user. The section coexists with the existing
`## Registered Specialists` and `## Project Code Area Overrides`
sections and MUST NOT replace them. Row schema, append semantics,
and the grading rubric are defined in the `routing-outcome-capture`
capability.

The routing procedure documented elsewhere in this capability
(description loading, match candidate set, Phase 1 output) is
unchanged by the presence or absence of the outcomes section. In
particular, the Tech Lead MUST NOT consult the `## Routing
Outcomes` section when computing Phase 1 match candidates: routing
decisions remain driven by description match and override match
only. Outcome history informs the user (via `/audit-routing-quality`)
and the rubric (during Phase 2 synthesis), not the routing decision
itself.

#### Scenario: Outcomes section coexists with routing sections

- **WHEN** the Tech Lead reads its memory file during routing
- **THEN** the presence of a `## Routing Outcomes` section does not
  prevent `## Registered Specialists` or `## Project Code Area
  Overrides` from being parsed, and Phase 1 routing proceeds
  exactly as documented without outcome data

#### Scenario: Outcomes do not feed the routing decision

- **WHEN** a specialist has ten recorded outcomes with value `none`
  in `## Routing Outcomes`
- **THEN** the Tech Lead's Phase 1 routing still emits a
  consultation request for that specialist if description match or
  override match holds, because the outcomes section does not
  alter the routing decision

#### Scenario: Outcomes section survives /add-specialist edits

- **WHEN** the user runs `/add-specialist` or manually edits
  `## Registered Specialists`
- **THEN** the `## Routing Outcomes` section is preserved verbatim
  in the memory file

### Requirement: Routing Outcomes section is append-only outside the audit skill

The `## Routing Outcomes` section SHALL be modified only through
two documented paths: (a) append-only row addition by
`/plan-implementation` after Phase 2 synthesis, and (b)
user-confirmed roll-up by `/audit-routing-quality` when the row
count exceeds the documented retention threshold. Any other
modification, including edits by `/audit-routing-table`,
`/add-specialist`, `/onboard`, or other skills, is prohibited.

#### Scenario: Structural audit does not touch outcomes

- **WHEN** `/audit-routing-table` runs against a memory file that
  contains a `## Routing Outcomes` section
- **THEN** the skill reads only `## Registered Specialists` and
  `## Project Code Area Overrides`, leaves the
  `## Routing Outcomes` section untouched, and does not include
  outcome rows in any finding

#### Scenario: Onboarding does not touch outcomes

- **WHEN** `/onboard` runs and writes memory
- **THEN** the `## Routing Outcomes` section, if present, is
  preserved verbatim; no outcome rows are added, removed, or
  reordered by the onboarding flow

### Requirement: Missing outcomes section degrades gracefully

The Tech Lead's routing and all outcome-consuming integrations SHALL
tolerate a missing `## Routing Outcomes` section without error.
Specifically:

- The routing procedure continues to produce Phase 1 output
  normally whether the section is present or absent.
- `/plan-implementation` creates the section on first append when
  it is missing.
- `/audit-routing-quality` emits the documented
  "No routing outcome history recorded yet." notice when the
  section is missing or empty.

#### Scenario: Missing section does not block routing

- **WHEN** a project has never run `/plan-implementation` and the
  memory file contains no `## Routing Outcomes` section
- **THEN** the Tech Lead's Phase 1 routing works exactly as before,
  and no warning or error is surfaced about the missing section

#### Scenario: First append creates the section

- **WHEN** `/plan-implementation` completes Phase 2 for the first
  time on a project whose memory file lacks a
  `## Routing Outcomes` section
- **THEN** the skill appends the section header, separator row,
  and one outcome row per specialist to the memory file
