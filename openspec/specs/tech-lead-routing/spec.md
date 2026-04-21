# Spec: Tech Lead Specialist Routing

## Identity

- **Owner agent:** `tech-lead`
- **Consumers:** `/plan-implementation`, `/conduct-postmortem`,
  `/facilitate-retrospective`, any caller that invokes the Tech Lead for
  routing
- **Memory file:** `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`

## Purpose

Define how the Tech Lead selects specialist agents to consult during Phase 1
of the two-phase consultation protocol. The routing model uses agent
descriptions as the source of truth for trigger vocabulary and a thin
project-local overrides table for code-area and project-specific signals.

## Memory File Sections

### `## Registered Specialists`

A markdown list. Every registered specialist is a candidate for routing. The
list contains no trigger metadata.

Entry format:

```markdown
- `<agent-name>` — `<path-or-slug>` — `target-type: <type>`
```

The third token (`target-type: <type>`) is **optional**. When omitted, the
entry is treated as `subagent` at routing time and the legacy two-token format
is preserved so existing memory files round-trip unchanged.

- `<agent-name>` is the kebab-case name that matches the agent's `name`
  frontmatter field.
- `<path-or-slug>` carries a type-specific value:
  - `subagent`: path to the agent file (`agents/<agent-name>.md` when omitted).
  - `skill`: the skill slug (e.g., `write-runbook`).
  - `doc`: the file path to read (e.g., `docs/security-review.md`).
  - `human`: the contact identifier (a name, role, or email address).
  - `external-agent`: the namespaced agent slug (e.g., `plugin-x:agent-y`).
- `<type>` is one of five fixed strings: `subagent`, `skill`, `doc`, `human`,
  `external-agent`. Any other value is treated as `subagent` with a routing
  warning. Entries without the third token default to `subagent`.

`subagent` entries (explicit or defaulted) MUST be written in the legacy
two-token format (`- \`<name>\` — \`<path>\``) so that existing memory files
round-trip cleanly. Non-`subagent` entries MUST include the `target-type`
suffix.

Invariants:

- Every specialist referenced in `## Project Code Area Overrides` must appear
  in this list.
- The Tech Lead does not invent routing for agents not in this list. Missing
  domain coverage is surfaced as a gap, not an invented consultation request.

### `## Routing Outcomes`

An append-only markdown table tracking per-specialist routing value for every
plan that ran through `/plan-implementation`. Full schema is defined in the
`routing-outcome-capture` capability spec at
`openspec/specs/routing-outcome-capture/spec.md`.

The section coexists with `## Registered Specialists` and
`## Project Code Area Overrides`. It is created by `/plan-implementation` on
the first successful Phase 2 append and must not be created or overwritten by
other skills.

Invariants:

- The routing procedure does not read `## Routing Outcomes` when computing
  Phase 1 match candidates. Routing decisions are driven by description match
  and override match only. Outcome history informs the user via
  `/audit-routing-quality`; it does not alter the routing decision itself.
- Only `/plan-implementation` (append rows after Phase 2 synthesis) and
  `/audit-routing-quality` (user-confirmed roll-up when row count exceeds 200)
  may modify this section. `/audit-routing-table`, `/add-specialist`, `/onboard`,
  and all other skills must leave the section untouched.

### `## Project Code Area Overrides`

A two-column markdown table. Each row identifies a project-local signal that
should route to a registered specialist regardless of description match.

Row format:

```markdown
| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
| `<signal>`         | <agent-name>    |
```

- Signals that look like file paths or globs are backtick-delimited; plain
  keywords are not.
- Signals should be project-local — file globs, repo-specific module names,
  internal terminology not found in any agent description.
- Duplicating trigger vocabulary from an agent description into this table is
  discouraged; the audit skill flags redundant rows.

## Routing Procedure

### Step 1 — Load Registered Specialists

Read `## Registered Specialists`. If the section is missing or empty, emit the
no-specialists notice documented in the "Registered Specialists" subsection of
`agents/tech-lead.md` (Your Knowledge Sources) and produce Phase 1 output with
zero consultation requests.

### Step 2 — Load Agent Descriptions

For each entry in `## Registered Specialists`, read the target type from the
entry (defaulting to `subagent` when the third token is absent).

- For `subagent` and `external-agent` entries: read the referenced agent or
  plugin file to extract the `description` field from its frontmatter block.
  Concatenate multi-line descriptions (the plugin's convention uses
  pipe-quoted YAML scalars).
- For `skill`, `doc`, and `human` entries: skip the agent-file read. The
  path-or-slug token carries the target value directly; no description
  extraction is needed.

If an agent file for a `subagent` or `external-agent` entry is not readable
(missing, unreadable, or malformed frontmatter), skip the specialist and
record a routing warning. The warning is surfaced under
`## Preliminary Constraints` as:
`Routing warning: could not read agent file for \`<agent-name>\` at \`<path>\`.`

### Step 3 — Build Match Candidate Set

A specialist is a match candidate if any condition holds:

- **Description match.** A case-insensitive substring of any trigger phrase,
  example-context phrase, or jurisdiction keyword extracted from the agent's
  `description` appears in the issue text.
- **Override match.** The issue text, any file paths the issue mentions, or
  any file the issue scope would edit matches a row in `## Project Code Area
  Overrides` whose target is this specialist. Glob matching uses standard
  shell glob semantics; plain-keyword overrides use case-insensitive
  substring match.
- **Non-subagent type.** `skill`, `doc`, and `human` entries carry no agent
  description to match against; they are unconditionally included in the
  match candidate set regardless of issue text.

A specialist matched by more than one mechanism appears once in the match
candidate set.

### Step 4 — Emit Phase 1 Output

Produce Phase 1 output in the format documented at `agents/tech-lead.md`. The
output gains one additive line per consultation request:

- `## Engagement Depth`
- `## Engagement Tier`
- `## Consultation Requests` with one `### <Specialist Name>` subsection per
  match candidate. Each subsection MUST contain, in order:
  1. `**Target Type:** <type>`, immediately after the heading; one of the
     five fixed strings (`subagent`, `skill`, `doc`, `human`,
     `external-agent`).
  2. The per-type dispatch anchor:
     - `subagent`: `**Agent:** \`<local-kebab-slug>\``
     - `external-agent`: `**Agent:** \`<plugin:agent>\``
     - `skill`: `**Skill:** <skill-slug>`
     - `doc`: `` **Doc:** `<file-path>` ``
     - `human`: `**Contact:** <name-or-role>`
  3. `**Prompt:**` blockquote (unchanged; preserved across all types).
- `## Preliminary Constraints`: includes routing warnings from Step 2 and any
  unknown-type warnings for entries whose declared type is not in the five-
  string vocabulary.
- `## Next Step`

### Step 5 — Gap Handling

If the Tech Lead's own assessment of the issue identifies a relevant domain
that no registered specialist covers, the gap is surfaced as follows:

- During Phase 1: as a bullet in `## Preliminary Constraints` noting the gap
  and recommending that the user register a specialist.
- During Phase 2: as a bullet in `## Escalation Flags` when the gap is
  load-bearing for the plan.

The Tech Lead never invents a consultation request for an unregistered agent.

## Invariants

- Trigger vocabulary lives in agent descriptions. The routing memory file
  does not contain trigger vocabulary.
- Every override row targets a registered specialist regardless of the
  specialist's target type. Orphan rows are audit findings, not routing
  inputs; the Tech Lead skips them at runtime.
- The existing Phase 1 parsing anchors (`**Agent:**`, `**Prompt:**`,
  `## Consultation Requests`, `## Next Step`) are preserved unchanged. The
  new `**Target Type:**` line and per-type anchors (`**Skill:**`, `**Doc:**`,
  `**Contact:**`) are additive. Existing parsers (notably
  `/plan-implementation`) continue to work; parsers MAY ignore anchors they
  do not recognize.
- Specialist descriptions are read at routing time, not cached across
  invocations. The Tech Lead always sees the current description content.
- Specialists with unreadable agent files (for `subagent` and
  `external-agent` entries) produce a visible warning in Phase 1 output;
  they are never silently dropped.
- `subagent` entries (explicit or defaulted) are written in the legacy
  two-token format; the `target-type` suffix is never written for `subagent`
  entries so existing memory files round-trip unchanged.

## Non-Requirements

- Keyword extraction from descriptions does not need to be semantic or
  NLP-based. Case-insensitive substring matching against the raw description
  body is sufficient.
- The routing memory file does not need a version field. Migration from the
  previous format is human-driven via `/audit-routing-table`.
- The Tech Lead does not need to deduplicate across description and override
  matches beyond producing a single consultation request per specialist.

## Acceptance Criteria

- [ ] Registering a new specialist with `/add-specialist <name>` makes the
      Tech Lead consult that specialist on an issue whose text matches the
      specialist's description, without any additional table edits.
- [ ] Adding a project-local override with `/add-specialist <name>
      "<override>"` causes the Tech Lead to consult the specialist on an
      issue that references the override signal even when the issue text
      does not match the agent description.
- [ ] An override row pointing at an unregistered specialist does not
      produce a consultation request at runtime. `/audit-routing-table`
      flags the row as orphan.
- [ ] A registered specialist whose agent file cannot be read is skipped at
      routing time with a warning in `## Preliminary Constraints`, and the
      remaining specialists still route correctly.
- [ ] Running `/plan-implementation` on the same issue before and after the
      migration produces Phase 1 output in the same format (same anchors,
      same consultation-request shape), so the skill's parser continues to
      work.
- [ ] `/audit-routing-table` reports orphan overrides, broken pointers,
      redundant overrides, and thin descriptions with recommended actions
      for each finding.
- [ ] Registering a `skill` target via `/add-specialist <name> skill
      <slug>` causes the Tech Lead's Phase 1 output to emit
      `**Target Type:** skill` and `**Skill:** <slug>` on a matching issue.
- [ ] Registering a `doc` target via `/add-specialist <name> doc <path>`
      causes the Tech Lead's Phase 1 output to emit `**Target Type:** doc`
      and `` **Doc:** `<path>` `` on a matching issue.
- [ ] Registering a `human` target causes the Tech Lead's Phase 1 output to
      emit `**Target Type:** human` and `**Contact:** <name-or-role>`.
- [ ] Registering an `external-agent` target with a namespaced slug causes
      the Phase 1 output to emit `**Target Type:** external-agent` and
      `**Agent:** <plugin:agent>`.
- [ ] A legacy entry (no target-type suffix) is treated as `subagent` at
      routing time and the Phase 1 output emits `**Target Type:** subagent`.
- [ ] `/plan-implementation` is not modified by this change. Consultation
      requests whose target type is `skill`, `doc`, or `human` do not carry
      `**Agent:**`; the current parser surfaces them to the user rather
      than dispatching via the Agent tool.
- [ ] `skills/refinement-review/SKILL.md` is not modified by this change.
## Requirements
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

