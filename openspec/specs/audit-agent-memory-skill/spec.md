# Audit Agent Memory Skill

## Purpose

Provide a read-only, advisory skill that inspects an agent's project memory
directory for bloat, stale state, dead links, and oversized files, then
reports findings with suggested (non-destructive) remediation steps.
## Requirements
### Requirement: Skill exists and is user-invokable

The plugin SHALL provide a user-invokable skill at
`skills/audit-agent-memory/SKILL.md` that accepts one argument: the
agent name. The skill's frontmatter MUST declare:

- `name: audit-agent-memory`
- `user-invokable: true`
- `argument-hint` that names the single `<agent-name>` parameter
- `allowed-tools` limited to `Read`, `Glob`, and `Grep`
- A `description` field naming at least the triggering phrases "audit
  memory", "agent memory hygiene", and "bloated memory"

The skill MUST NOT declare write-capable tools in `allowed-tools`
(for example, `Write`, `Edit`, `Bash`).

#### Scenario: Frontmatter declares read-only tool surface

- **WHEN** a reader opens `skills/audit-agent-memory/SKILL.md` and
  inspects the frontmatter
- **THEN** the `allowed-tools` list contains exactly `Read`, `Glob`,
  and `Grep` and does not contain any write-capable tool

#### Scenario: Skill exposes the agent-name argument

- **WHEN** a caller runs `/audit-agent-memory` without an argument
- **THEN** the skill reports a friendly usage message naming the
  `<agent-name>` argument and exits without reading any file

#### Scenario: Frontmatter triggering phrases are present

- **WHEN** a reader inspects the skill's `description` field
- **THEN** the field names at least "audit memory", "agent memory
  hygiene", and "bloated memory" so that `/`-invocation and agent
  routing can match

### Requirement: Skill reads the agent's project memory directory

The skill SHALL derive the memory directory path from the supplied
agent name as
`.claude/agent-memory/engineering-leaders-<agent-name>/`. It SHALL
read `MEMORY.md` at the root of that directory and glob the directory
for additional `*.md` files referenced by or adjacent to the index.

If the directory does not exist, the skill SHALL emit a single-line
friendly message naming the missing path and exit without further
checks.

#### Scenario: Missing memory directory exits cleanly

- **GIVEN** an agent whose project memory directory does not exist
- **WHEN** the caller runs `/audit-agent-memory <agent-name>`
- **THEN** the skill prints a one-line message naming the missing
  directory and exits without attempting further checks

#### Scenario: Existing memory directory is read in full

- **GIVEN** an agent whose project memory directory contains
  `MEMORY.md` and one or more additional `*.md` files
- **WHEN** the caller runs `/audit-agent-memory <agent-name>`
- **THEN** the skill reads `MEMORY.md` and globs the directory for
  all `*.md` files before running any check

### Requirement: Four named checks with visible heuristics

The skill SHALL run four named checks on each inspected file. The
check names and heuristics MUST be documented inline in the skill
body so a user who disputes a finding can inspect the rule:

1. **State-like content.** Triggers on any of: dated phrases drawn
   from a named vocabulary list (for example, "as of", "last
   quarter", "this sprint"), three or more enumerated file paths in
   a row, three or more enumerated issue-tracker IDs matching a
   prefix-hyphen-digits pattern, or a table whose column headings
   include work-item vocabulary (for example, "owner", "due",
   "status").
2. **Strategy-like content (negative check).** Triggers on any of: a
   "Why" rationale block, a named invariant or principle, a routing
   rule, a named policy, or a definition. Files that trigger check 1
   AND check 2 MUST be reported at "mixed" severity rather than
   "state".
3. **Dead links.** Triggers when a `*.md` file in the directory is
   not referenced from `MEMORY.md`.
4. **Size.** Triggers on two bands: a single-file band when a file's
   estimated token count (bytes divided by four) exceeds roughly
   four thousand, and a directory band when the directory's total
   estimated token count exceeds roughly ten thousand.

Each finding MUST carry:

- The file path (or directory for the directory-level size
  finding).
- The check name that triggered.
- A one-line rationale that quotes the triggering phrase, count, or
  threshold.
- A recommended action phrased as a suggestion the user can confirm
  or dismiss.

#### Scenario: State-like check reports the quoted trigger

- **GIVEN** a memory file containing the phrase "as of Q3 2025" and
  three file-path enumerations
- **WHEN** the skill runs the state-like check against it
- **THEN** the finding quotes "as of Q3 2025" and the count of
  enumerated paths and names the file in the finding output

#### Scenario: Mixed severity when state and strategy both trigger

- **GIVEN** a memory file that contains both an enumerated set of
  file paths and a named invariant with a Why-rationale block
- **WHEN** the skill runs the state and strategy checks against it
- **THEN** the finding is reported at severity "mixed" rather than
  "state"

#### Scenario: Dead-link detection names the orphan file

- **GIVEN** a directory that contains `MEMORY.md` referencing
  `routing.md` and a second file `old-phase-tracker.md` that
  `MEMORY.md` does not reference
- **WHEN** the skill runs the dead-link check
- **THEN** the findings name `old-phase-tracker.md` as an orphan and
  do not name `routing.md`

#### Scenario: Directory size check quotes the threshold

- **GIVEN** a memory directory whose total estimated token count
  exceeds the documented threshold
- **WHEN** the skill runs the size check
- **THEN** the finding quotes both the observed estimate and the
  documented threshold

### Requirement: Skill is read-only and advisory

The skill SHALL NOT modify any file. It MUST NOT delete, move, edit,
or rewrite memory files or the `MEMORY.md` index. All output is a
printed report; all suggested actions are phrased as options the
user confirms or dismisses.

#### Scenario: No file is modified during a run

- **WHEN** the skill runs against any memory directory
- **THEN** file modification timestamps in the memory directory are
  unchanged after the run completes

#### Scenario: Recommendations are phrased as options

- **WHEN** the skill emits its `## Recommendations` section
- **THEN** each recommendation uses suggestive vocabulary (for
  example, "consider", "if the content is no longer current") rather
  than directive vocabulary (for example, "delete", "remove")

### Requirement: Fixed report structure

The skill's output SHALL use a fixed markdown structure in the
following order:

1. `## Summary` with a one-line total-size estimate and a count of
   findings per check.
2. `## Findings` grouped by check, each finding rendered as a
   bulleted item containing the file path, the triggering rationale,
   and the recommended action.
3. `## Recommendations` summarizing suggested next steps across the
   findings, phrased as options.
4. `## Next Step` with a single sentence pointing the user at the
   highest-priority recommendation.

#### Scenario: Report sections appear in the documented order

- **WHEN** the skill emits its report
- **THEN** the four section headings appear in the order `##
  Summary`, `## Findings`, `## Recommendations`, `## Next Step`

#### Scenario: Findings section groups by check name

- **WHEN** the skill emits the `## Findings` section
- **THEN** findings are grouped under subheadings matching the four
  check names (state-like, mixed, dead links, size), omitting
  subheadings for which no finding was produced

### Requirement: README documents the skill

The plugin SHALL document the skill in the top-level `README.md`
alongside the existing `/audit-routing-table` skill. The README
entry MUST:

- Name the skill `/audit-agent-memory` verbatim.
- Describe it in one paragraph and state in one sentence when to run
  it (for example, periodic hygiene, before re-onboarding, when an
  agent feels bloated).
- Cross-reference `/audit-routing-table` as a complementary audit.
- State that the skill is read-only and advisory.

#### Scenario: README names the skill and its trigger

- **WHEN** a reader searches `README.md` for `audit-agent-memory`
- **THEN** the search finds a section that names the skill, a
  "when to use it" sentence, and a cross-reference to
  `audit-routing-table`

#### Scenario: README states the advisory posture

- **WHEN** a reader reads the README entry for the skill
- **THEN** the entry states that the skill does not modify any file
  and that the user confirms each recommendation

