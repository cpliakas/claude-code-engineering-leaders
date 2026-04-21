# Routing Target Types

## ADDED Requirements

### Requirement: Five supported target types with a `subagent` default

The Tech Lead's routing model SHALL support five target types on every
registered entry: `subagent`, `skill`, `doc`, `human`, and `external-agent`.
An entry that does not declare a target type MUST be treated as `subagent`
at routing time, and the memory-file writer MUST preserve the legacy (no
suffix) row format for `subagent` entries so existing memory files
round-trip unchanged.

The five target types are defined as follows:

- `subagent`: a local Claude Code sub-agent resolved via
  `agents/<agent-name>.md` or the path declared on the entry. Dispatched by
  the caller via the Agent tool with a kebab-case slug.
- `skill`: a skill whose invocation produces the answer. Dispatched by the
  caller invoking the named skill with the emitted prompt.
- `doc`: a file path the user should read before the plan proceeds. Not
  dispatched; the plan notes the dependency.
- `human`: a named person or role whose judgment is required. Not
  dispatched; the plan is paused with an escalation notice.
- `external-agent`: a sub-agent in another installed plugin, referenced by
  a namespaced slug (for example, `plugin-x:agent-y`). Dispatched by the
  caller via the Agent tool with the namespaced slug.

#### Scenario: Legacy entry is treated as `subagent`

- **WHEN** the Tech Lead reads an entry in `## Registered Specialists` that
  has no declared target type
- **THEN** the entry is routed as if its target type were `subagent`, and
  the Phase 1 output emits `**Target Type:** subagent` on the resulting
  consultation request

#### Scenario: Declared target type overrides the default

- **WHEN** the Tech Lead reads an entry whose declared target type is
  `skill`, `doc`, `human`, or `external-agent`
- **THEN** the declared type is used for routing and the Phase 1 output
  reflects the declared type on the `**Target Type:**` line

#### Scenario: Unknown target type falls back with a warning

- **WHEN** the Tech Lead reads an entry whose declared target type is not
  one of the five supported values
- **THEN** the Tech Lead emits a routing warning under
  `## Preliminary Constraints` naming the entry and the invalid type, and
  treats the entry as `subagent` for the purposes of routing output

### Requirement: Phase 1 output emits a `**Target Type:**` anchor per request

The Tech Lead's Phase 1 output SHALL include a `**Target Type:**` line on
every `### <Name>` subsection under `## Consultation Requests`. The line
MUST appear immediately after the subsection heading and MUST carry one of
the five fixed strings from the previous requirement.

The `**Prompt:**` anchor and the blockquote-formatted prompt body MUST be
preserved verbatim across all target types so the existing
`/plan-implementation` parser continues to extract the prompt text.

The per-type dispatch anchor MUST appear between `**Target Type:**` and
`**Prompt:**`, shaped as follows:

- `subagent`: `**Agent:**` with the local kebab-case slug.
- `external-agent`: `**Agent:**` with the namespaced slug (for example,
  `plugin-x:agent-y`).
- `skill`: `**Skill:**` with the skill slug.
- `doc`: `**Doc:**` with the file path, backtick-delimited.
- `human`: `**Contact:**` with the name, role, or contact identifier.

#### Scenario: `subagent` request keeps the existing anchor shape

- **WHEN** the Tech Lead emits a Phase 1 consultation request for a
  `subagent` target
- **THEN** the request contains `**Target Type:** subagent`,
  `**Agent:** <local-kebab-slug>`, and the existing `**Prompt:**` blockquote
  in that order

#### Scenario: `skill` request carries `**Skill:**`

- **WHEN** the Tech Lead emits a Phase 1 consultation request for a
  `skill` target
- **THEN** the request contains `**Target Type:** skill`,
  `**Skill:** <skill-slug>`, and the existing `**Prompt:**` blockquote in
  that order; no `**Agent:**` line is emitted

#### Scenario: `doc` request carries `**Doc:**`

- **WHEN** the Tech Lead emits a Phase 1 consultation request for a
  `doc` target
- **THEN** the request contains `**Target Type:** doc`,
  `` **Doc:** `<file-path>` ``, and the existing `**Prompt:**` blockquote in
  that order; no `**Agent:**` line is emitted

#### Scenario: `human` request carries `**Contact:**`

- **WHEN** the Tech Lead emits a Phase 1 consultation request for a
  `human` target
- **THEN** the request contains `**Target Type:** human`,
  `**Contact:** <name-or-role>`, and the existing `**Prompt:**` blockquote
  in that order; no `**Agent:**` line is emitted

#### Scenario: `external-agent` request uses a namespaced slug

- **WHEN** the Tech Lead emits a Phase 1 consultation request for an
  `external-agent` target
- **THEN** the request contains `**Target Type:** external-agent`,
  `**Agent:** <plugin:agent>` with a namespace separator, and the existing
  `**Prompt:**` blockquote in that order

### Requirement: `/add-specialist` accepts a target-type argument

The `/add-specialist` skill SHALL accept an explicit target type via
either a `--target-type=<value>` flag or a second positional token matching
the five-string vocabulary. When no target type is provided, the skill MUST
register a `subagent` entry using the legacy row format so existing user
workflows are unchanged.

The skill MUST validate the per-type value (the path, slug, or contact)
with the following rules, treating each failure as a warning rather than a
hard error:

- `skill`: warn if `skills/<slug>/SKILL.md` is not present locally (the
  skill may live in an external plugin).
- `doc`: warn if the file path does not resolve via Glob.
- `human`: no format check.
- `external-agent`: warn if the slug does not contain a namespace
  separator (`:`).
- `subagent`: existing behavior (warn if the agent file is missing).

When validation warns, the skill MUST ask the user whether to continue and
MUST honor the answer.

#### Scenario: Explicit flag form registers a non-subagent entry

- **WHEN** the user invokes `/add-specialist <name> --target-type=doc
  <path>`
- **THEN** the skill validates the path via Glob, writes the entry with a
  `doc` target-type suffix in the memory file, and confirms the
  registration with a target-type-aware summary

#### Scenario: Positional form registers a non-subagent entry

- **WHEN** the user invokes `/add-specialist <name> skill <skill-slug>`
- **THEN** the skill recognizes `skill` as the target-type token, validates
  the skill slug, writes the entry with a `skill` target-type suffix, and
  confirms with a target-type-aware summary

#### Scenario: Omitted target type registers a legacy `subagent` entry

- **WHEN** the user invokes `/add-specialist <name>` without a target type
- **THEN** the skill writes the entry in the legacy row format (no
  target-type suffix), and the Tech Lead treats the entry as `subagent` at
  routing time

### Requirement: README documents handling patterns per target type

The top-level `README.md` SHALL include a section that documents the
caller-side dispatch pattern for each of the five target types. The section
MUST at minimum cover:

- How the caller dispatches a `subagent` request (via the Agent tool with a
  local kebab-case slug).
- How the caller invokes a `skill` request (via the named skill, with the
  emitted prompt as input; the skill's output feeds into Phase 2 like any
  specialist response).
- How the caller handles a `doc` request (cite the path in the plan's
  dependencies; the plan notes "Read `<path>` before starting"; no Phase 2
  feedback loop).
- How the caller handles a `human` request (pause the plan with an
  explicit escalation notice; the user owns the handoff; no automated Phase
  2 feedback loop).
- How the caller dispatches an `external-agent` request (via the Agent tool
  with the namespaced slug).

The section MUST state explicitly that entries without a declared target
type default to `subagent` and that existing projects require no migration.
The section MUST cross-reference the Tech Lead example and the
`/add-specialist` example.

#### Scenario: README lists all five handling patterns

- **WHEN** a reader opens the top-level `README.md` and navigates to the
  "Routing Target Types" section
- **THEN** the section names `subagent`, `skill`, `doc`, `human`, and
  `external-agent` and provides a paragraph per type describing the
  dispatch pattern

#### Scenario: README states the back-compat default

- **WHEN** a reader inspects the "Routing Target Types" section
- **THEN** the text states explicitly that an entry without a declared
  target type defaults to `subagent` and that existing memory files
  require no migration

#### Scenario: README cross-references the entry points

- **WHEN** a reader inspects the "Routing Target Types" section
- **THEN** the section links to or references the Tech Lead example and
  the `/add-specialist` example so handling guidance is reachable from
  both entry points

### Requirement: `/plan-implementation` is not modified in this change

The `/plan-implementation` skill SHALL NOT be modified by this change. Its
existing Phase 1 parser continues to match on `## Consultation Requests`,
`### <Name>`, `**Agent:**`, `**Prompt:**`, and `## Next Step`. The new
`**Target Type:**` line and the per-type anchors (`**Skill:**`, `**Doc:**`,
`**Contact:**`) are additive and MAY be ignored by the existing parser.

Consultation requests whose target type is `skill`, `doc`, or `human` do
NOT include `**Agent:**`. Because the current parser treats
`**Agent:**`-less requests as non-spawnable, those requests are naturally
surfaced to the user rather than silently dropped. Full target-type-aware
dispatch in `/plan-implementation` is a deliberate follow-up.

#### Scenario: Plan-implementation skill file is unchanged

- **WHEN** `skills/plan-implementation/SKILL.md` is diffed before and
  after the change
- **THEN** no lines are added, removed, or modified

#### Scenario: Non-subagent request is surfaced to the user

- **WHEN** `/plan-implementation` parses a Phase 1 output containing a
  consultation request whose target type is `skill`, `doc`, or `human`
- **THEN** the request is surfaced in the skill's output to the user
  rather than dispatched via the Agent tool

#### Scenario: Subagent and external-agent requests still dispatch

- **WHEN** `/plan-implementation` parses a Phase 1 output containing a
  consultation request whose target type is `subagent` or `external-agent`
- **THEN** the skill dispatches the request via the Agent tool using the
  slug on the `**Agent:**` line, matching its existing behavior

### Requirement: No changes to the refinement-review skill

The change MUST NOT modify `skills/refinement-review/SKILL.md`. Refinement-
layer target-type awareness is deliberately out of scope; any future
tier-aware or target-type-aware behavior in that skill is a separate
change.

#### Scenario: Refinement-review skill file is unchanged

- **WHEN** `skills/refinement-review/SKILL.md` is diffed before and after
  the change
- **THEN** no lines are added, removed, or modified
