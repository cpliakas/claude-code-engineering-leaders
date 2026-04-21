# Re-Onboarding Drift Detection Skill

## ADDED Requirements

### Requirement: Skill exists and is user-invokable

The plugin SHALL provide a user-invokable skill at
`skills/re-onboard/SKILL.md`. The skill accepts one optional
positional argument naming a single agent; with no argument, the
skill audits every onboarded agent found in the project. The
skill's frontmatter MUST declare:

- `name: re-onboard`
- `user-invokable: true`
- `argument-hint` that names the optional `[agent-name]`
  parameter and indicates it is optional
- `allowed-tools` containing exactly `Read`, `Glob`, `Grep`,
  `Bash`, and `Edit`
- A `description` field naming at least the triggering phrases
  "re-onboard", "drift", "refresh project context", and
  "onboarding drift"

The skill MUST NOT declare `Write` in `allowed-tools`. All updates
are in-place edits to existing files.

#### Scenario: Frontmatter declares the documented tool surface

- **WHEN** a reader opens `skills/re-onboard/SKILL.md` and
  inspects the frontmatter
- **THEN** the `allowed-tools` list contains exactly `Read`,
  `Glob`, `Grep`, `Bash`, and `Edit` and does not contain `Write`

#### Scenario: Frontmatter names the optional argument

- **WHEN** a reader inspects the skill's `argument-hint` field
- **THEN** the hint names `[agent-name]` (with brackets or explicit
  "optional" wording) and does not require an argument

#### Scenario: Frontmatter triggering phrases are present

- **WHEN** a reader inspects the skill's `description` field
- **THEN** the field names at least "re-onboard", "drift",
  "refresh project context", and "onboarding drift" so that
  `/`-invocation and agent routing can match

### Requirement: Skill discovers onboarded agents from memory

The skill SHALL enumerate onboarded agents by globbing the
`.claude/agent-memory/engineering-leaders-<agent>/` directories
under the project root. Each directory found with a readable
`MEMORY.md` counts as an onboarded agent. When invoked with an
optional agent-name argument, the skill SHALL restrict the audit
to the single matching directory.

If no agent memory directories exist, the skill SHALL emit a
single-line friendly message indicating that no onboarded agents
were found and exit without further checks.

If the argument names an agent whose memory directory does not
exist, the skill SHALL emit a single-line friendly message naming
the missing directory and exit.

#### Scenario: Zero-argument invocation audits every onboarded agent

- **GIVEN** a project with two agent memory directories
  (`engineering-leaders-tech-lead` and
  `engineering-leaders-product-owner`), each containing
  `MEMORY.md`
- **WHEN** the caller runs `/re-onboard`
- **THEN** the skill audits both directories and the resulting
  report's `## Per-Agent Drift` section contains a subsection for
  each agent

#### Scenario: Agent-name argument narrows the audit

- **GIVEN** a project with two agent memory directories
- **WHEN** the caller runs `/re-onboard tech-lead`
- **THEN** the skill audits only the Tech Lead memory directory
  and the report's `## Per-Agent Drift` section contains exactly
  one agent subsection

#### Scenario: No onboarded agents found exits cleanly

- **GIVEN** a project with no `engineering-leaders-<agent>/`
  memory directories
- **WHEN** the caller runs `/re-onboard`
- **THEN** the skill prints a one-line message indicating no
  onboarded agents were found and exits without further checks

#### Scenario: Named agent with missing memory exits cleanly

- **GIVEN** a project with no memory directory for the named agent
- **WHEN** the caller runs `/re-onboard <agent-name>`
- **THEN** the skill prints a one-line message naming the missing
  directory and exits without further checks

### Requirement: Signal sources are limited to four documented
categories

The skill SHALL derive drift signals from exactly four local
signal sources, documented inline in the skill body:

1. **Filesystem path presence.** For every directory or file path
   claimed by memory (for example, an ADR directory or conventions
   directory), the skill verifies existence. If absent, the skill
   globs for plausible alternates using a documented candidate
   list and surfaces the candidates as suggestions.
2. **Specialist agent files.** For the Tech Lead's routing table,
   the skill enumerates files under `agents/` and compares against
   the specialists named in memory. Specialists present in memory
   but missing from `agents/`, and specialist files present in
   `agents/` but not named in memory, both surface.
3. **Git remote URL.** Where memory claims a hosting platform, the
   skill runs `git remote get-url origin` and classifies the
   hostname (for example, `github.com`, `gitlab.com`,
   `bitbucket.org`). Hostname classification mismatches surface.
4. **Tracker directory probes.** Where memory claims an issue
   tracker, the skill probes for the tracker's canonical
   footprint (for example, `.beads/` for Beads, `.github/` for
   GitHub-related usage). Missing expected footprints and
   unexpected new footprints both surface.

The skill MUST NOT call any network API, read credentials, or
require authentication. All signals derive from local files and
git state.

#### Scenario: Filesystem path miss surfaces plausible alternates

- **GIVEN** memory claims the ADR path is `docs/adr/` but only
  `docs/adrs/` exists on disk
- **WHEN** the skill runs the filesystem path check
- **THEN** the drift finding names the memory-claimed path, the
  missing-on-disk status, and lists `docs/adrs/` as a plausible
  alternate

#### Scenario: Specialist drift surfaces additions and removals

- **GIVEN** memory lists specialists `frontend-engineer` and
  `data-engineer` and the `agents/` directory contains
  `frontend-engineer.md` and `security-engineer.md`
- **WHEN** the skill runs the specialist check
- **THEN** the drift finding names `data-engineer` as present in
  memory but missing from `agents/`, and names `security-engineer`
  as present in `agents/` but not in memory

#### Scenario: Git remote mismatch surfaces hostname classification

- **GIVEN** memory claims the project is hosted on GitHub and
  `git remote get-url origin` returns a `gitlab.com` URL
- **WHEN** the skill runs the git remote check
- **THEN** the drift finding names the memory-claimed host, the
  observed hostname, and the hostname classification mismatch

#### Scenario: Tracker footprint mismatch surfaces

- **GIVEN** memory claims the tracker is Beads and no `.beads/`
  directory exists under the project root
- **WHEN** the skill runs the tracker probe
- **THEN** the drift finding names Beads as the memory-claimed
  tracker, the missing `.beads/` footprint, and surfaces any
  unexpected tracker directories found

#### Scenario: Skill makes no network calls

- **WHEN** the skill runs any of its four signal checks
- **THEN** no check issues a network request, reads a credential
  file, or requires authentication

### Requirement: Every drift finding is phrased as a question

The skill SHALL phrase every drift finding as a yes-or-no question
the user answers to confirm or dismiss an update to memory. Each
finding MUST carry:

- The memory-claimed value (quoted).
- The derived value or signal observation (quoted).
- A one-sentence question ending in a question mark.
- An optional free-text override so the user can supply a value
  different from the derived one.

The report MUST NOT present a derived value as a fact. Phrasing
such as "the path is now X" or "memory should say Y" is
prohibited; phrasing such as "memory says X, but Y looks present.
Does Y still look right?" is required.

#### Scenario: Finding includes memory value, derived value, and
question

- **WHEN** the skill emits a drift finding
- **THEN** the finding output includes the memory-claimed value,
  the derived value, and a sentence ending in a question mark

#### Scenario: Derived values are never presented as facts

- **WHEN** a reader scans any drift finding in the report
- **THEN** no finding contains the phrases "the path is now",
  "memory should say", or equivalent directive assertions about
  derived values

### Requirement: Confirmation is required before any memory edit

The skill SHALL NOT edit any memory file without an explicit user
confirmation per drifted item. The default confirmation flow is
one yes-or-no per item. A batch-accept option MAY be offered only
after the user has answered at least two individual items in the
current run.

If the user dismisses a finding, the skill MUST NOT edit the
corresponding memory file for that finding.

If the user accepts a finding, the skill SHALL edit the
corresponding memory file in place and MUST NOT create a new file
for the update.

#### Scenario: Dismissed finding leaves memory unchanged

- **GIVEN** a drift finding for a claimed value in a memory file
- **WHEN** the user dismisses the finding
- **THEN** the memory file's content for that value is unchanged
  after the skill completes

#### Scenario: Accepted finding updates the existing memory file

- **GIVEN** a drift finding the user accepts with the derived
  value
- **WHEN** the skill applies the update
- **THEN** the existing memory file is edited in place to contain
  the accepted value and no new file is created

#### Scenario: Batch accept is not offered at the start of the run

- **WHEN** the skill emits the first drift finding in a run
- **THEN** the confirmation flow for that finding does not include
  a batch-accept option

#### Scenario: Batch accept is offered only after at least two
individual confirmations

- **WHEN** the user has answered at least two individual drift
  findings in a run
- **THEN** subsequent findings MAY offer a batch-accept option

### Requirement: Shared context drift propagates to dependent
agents

Where drift is detected in
`.claude/agent-memory/engineering-leaders/PROJECT.md` (the Layer 1
shared context), the skill SHALL report the shared-context drift
once under a dedicated `## Shared Context` section and SHALL list
every per-agent memory that references `PROJECT.md` so the user
sees the blast radius in a single view.

When the user confirms a shared-context update, the skill SHALL
apply the update to `PROJECT.md` exactly once. It SHALL NOT
re-prompt the user per dependent agent memory for the same
shared-context item.

#### Scenario: Shared-context drift appears once with dependents
listed

- **GIVEN** drift detected in `PROJECT.md` and two per-agent
  memories that reference it
- **WHEN** the skill emits its report
- **THEN** the `## Shared Context` section contains exactly one
  drift entry for the item and lists both dependent agent memories

#### Scenario: Confirmed shared-context update prompts only once

- **GIVEN** a shared-context drift item and N dependent per-agent
  memories
- **WHEN** the user confirms the shared-context update
- **THEN** the skill applies the update to `PROJECT.md` once and
  does not emit N additional confirmations for the same item

### Requirement: Skill does not re-interrogate un-diffable content

The skill SHALL NOT prompt the user about onboarding content for
which no local signal source exists. Un-diffable content includes,
at minimum: team norms and review practices, persona preferences,
stakeholder relationships, philosophy, and free-text descriptions
of why a decision was made.

The skill MAY print a short reminder at the end of a run listing
un-diffable categories the user may wish to refresh manually via
a full onboarding skill, but MUST NOT ask drift questions about
them.

#### Scenario: Un-diffable categories do not produce drift
findings

- **GIVEN** memory contains team-norm content with no derivable
  signal
- **WHEN** the skill runs
- **THEN** the drift report contains no finding that references
  team-norm content

#### Scenario: Optional reminder lists un-diffable categories

- **WHEN** the skill emits its report
- **THEN** any reminder about un-diffable content appears as a
  plain list of category names with no per-item questions

### Requirement: Fixed report structure

The skill's output SHALL use a fixed markdown structure in the
following order:

1. `## Summary` with a count of drifted items per agent and a
   total.
2. `## Shared Context` with drift in `PROJECT.md` and the list of
   dependent agent memories, omitted if no shared-context drift
   was detected.
3. `## Per-Agent Drift` grouped by agent name, each agent's
   section listing drifted items, unchanged-notable items, and
   new items under named subsections.
4. `## Confirmation` listing each drift item as a numbered
   question the user answers.
5. `## Next Step` with a single-sentence call to action pointing
   at the highest-priority confirmation or suggesting a full
   `/onboard-<agent>` re-run when drift is extensive.

#### Scenario: Report sections appear in the documented order

- **WHEN** the skill emits its report
- **THEN** the section headings appear in the order `## Summary`,
  `## Shared Context` (when present), `## Per-Agent Drift`,
  `## Confirmation`, `## Next Step`

#### Scenario: Shared Context section is omitted when empty

- **GIVEN** no drift detected in `PROJECT.md`
- **WHEN** the skill emits its report
- **THEN** the `## Shared Context` heading is omitted and the
  `## Per-Agent Drift` section follows `## Summary` directly

#### Scenario: Next Step suggests full re-onboarding on extensive
drift

- **GIVEN** an agent whose drift findings cover more than half of
  the agent's onboarding-derived memory content
- **WHEN** the skill emits the `## Next Step` section
- **THEN** the call to action suggests the user re-run the
  corresponding `/onboard-<agent>` skill rather than confirm item
  by item

### Requirement: README documents the skill

The plugin SHALL document the skill in the top-level `README.md`
alongside the existing `/onboard` and audit skills. The README
entry MUST:

- Name the skill `/re-onboard` verbatim.
- Describe it in one paragraph and state in one sentence when to
  run it (for example, periodic cadence, after a structural
  project change, when an agent gives advice that feels out of
  date).
- Cross-reference `/onboard`, `/audit-routing-table`, and
  `/audit-agent-memory` so readers see the four skills as a
  family.
- State that the skill edits memory only after explicit user
  confirmation and does not replace a full `/onboard-<agent>`
  re-run.

#### Scenario: README names the skill and its trigger

- **WHEN** a reader searches `README.md` for `re-onboard`
- **THEN** the search finds a section that names the skill, a
  "when to use it" sentence, and cross-references to `/onboard`,
  `/audit-routing-table`, and `/audit-agent-memory`

#### Scenario: README states the confirmation posture

- **WHEN** a reader reads the README entry for the skill
- **THEN** the entry states that the skill edits memory only
  after explicit user confirmation and that the skill does not
  replace a full `/onboard-<agent>` re-run
## Requirements
### Requirement: Skill exists and is user-invokable

The plugin SHALL provide a user-invokable skill at
`skills/re-onboard/SKILL.md`. The skill accepts one optional
positional argument naming a single agent; with no argument, the
skill audits every onboarded agent found in the project. The
skill's frontmatter MUST declare:

- `name: re-onboard`
- `user-invokable: true`
- `argument-hint` that names the optional `[agent-name]`
  parameter and indicates it is optional
- `allowed-tools` containing exactly `Read`, `Glob`, `Grep`,
  `Bash`, and `Edit`
- A `description` field naming at least the triggering phrases
  "re-onboard", "drift", "refresh project context", and
  "onboarding drift"

The skill MUST NOT declare `Write` in `allowed-tools`. All updates
are in-place edits to existing files.

#### Scenario: Frontmatter declares the documented tool surface

- **WHEN** a reader opens `skills/re-onboard/SKILL.md` and
  inspects the frontmatter
- **THEN** the `allowed-tools` list contains exactly `Read`,
  `Glob`, `Grep`, `Bash`, and `Edit` and does not contain `Write`

#### Scenario: Frontmatter names the optional argument

- **WHEN** a reader inspects the skill's `argument-hint` field
- **THEN** the hint names `[agent-name]` (with brackets or explicit
  "optional" wording) and does not require an argument

#### Scenario: Frontmatter triggering phrases are present

- **WHEN** a reader inspects the skill's `description` field
- **THEN** the field names at least "re-onboard", "drift",
  "refresh project context", and "onboarding drift" so that
  `/`-invocation and agent routing can match

### Requirement: Skill discovers onboarded agents from memory

The skill SHALL enumerate onboarded agents by globbing the
`.claude/agent-memory/engineering-leaders-<agent>/` directories
under the project root. Each directory found with a readable
`MEMORY.md` counts as an onboarded agent. When invoked with an
optional agent-name argument, the skill SHALL restrict the audit
to the single matching directory.

If no agent memory directories exist, the skill SHALL emit a
single-line friendly message indicating that no onboarded agents
were found and exit without further checks.

If the argument names an agent whose memory directory does not
exist, the skill SHALL emit a single-line friendly message naming
the missing directory and exit.

#### Scenario: Zero-argument invocation audits every onboarded agent

- **GIVEN** a project with two agent memory directories
  (`engineering-leaders-tech-lead` and
  `engineering-leaders-product-owner`), each containing
  `MEMORY.md`
- **WHEN** the caller runs `/re-onboard`
- **THEN** the skill audits both directories and the resulting
  report's `## Per-Agent Drift` section contains a subsection for
  each agent

#### Scenario: Agent-name argument narrows the audit

- **GIVEN** a project with two agent memory directories
- **WHEN** the caller runs `/re-onboard tech-lead`
- **THEN** the skill audits only the Tech Lead memory directory
  and the report's `## Per-Agent Drift` section contains exactly
  one agent subsection

#### Scenario: No onboarded agents found exits cleanly

- **GIVEN** a project with no `engineering-leaders-<agent>/`
  memory directories
- **WHEN** the caller runs `/re-onboard`
- **THEN** the skill prints a one-line message indicating no
  onboarded agents were found and exits without further checks

#### Scenario: Named agent with missing memory exits cleanly

- **GIVEN** a project with no memory directory for the named agent
- **WHEN** the caller runs `/re-onboard <agent-name>`
- **THEN** the skill prints a one-line message naming the missing
  directory and exits without further checks

### Requirement: Signal sources are limited to four documented
categories

The skill SHALL derive drift signals from exactly four local
signal sources, documented inline in the skill body:

1. **Filesystem path presence.** For every directory or file path
   claimed by memory (for example, an ADR directory or conventions
   directory), the skill verifies existence. If absent, the skill
   globs for plausible alternates using a documented candidate
   list and surfaces the candidates as suggestions.
2. **Specialist agent files.** For the Tech Lead's routing table,
   the skill enumerates files under `agents/` and compares against
   the specialists named in memory. Specialists present in memory
   but missing from `agents/`, and specialist files present in
   `agents/` but not named in memory, both surface.
3. **Git remote URL.** Where memory claims a hosting platform, the
   skill runs `git remote get-url origin` and classifies the
   hostname (for example, `github.com`, `gitlab.com`,
   `bitbucket.org`). Hostname classification mismatches surface.
4. **Tracker directory probes.** Where memory claims an issue
   tracker, the skill probes for the tracker's canonical
   footprint (for example, `.beads/` for Beads, `.github/` for
   GitHub-related usage). Missing expected footprints and
   unexpected new footprints both surface.

The skill MUST NOT call any network API, read credentials, or
require authentication. All signals derive from local files and
git state.

#### Scenario: Filesystem path miss surfaces plausible alternates

- **GIVEN** memory claims the ADR path is `docs/adr/` but only
  `docs/adrs/` exists on disk
- **WHEN** the skill runs the filesystem path check
- **THEN** the drift finding names the memory-claimed path, the
  missing-on-disk status, and lists `docs/adrs/` as a plausible
  alternate

#### Scenario: Specialist drift surfaces additions and removals

- **GIVEN** memory lists specialists `frontend-engineer` and
  `data-engineer` and the `agents/` directory contains
  `frontend-engineer.md` and `security-engineer.md`
- **WHEN** the skill runs the specialist check
- **THEN** the drift finding names `data-engineer` as present in
  memory but missing from `agents/`, and names `security-engineer`
  as present in `agents/` but not in memory

#### Scenario: Git remote mismatch surfaces hostname classification

- **GIVEN** memory claims the project is hosted on GitHub and
  `git remote get-url origin` returns a `gitlab.com` URL
- **WHEN** the skill runs the git remote check
- **THEN** the drift finding names the memory-claimed host, the
  observed hostname, and the hostname classification mismatch

#### Scenario: Tracker footprint mismatch surfaces

- **GIVEN** memory claims the tracker is Beads and no `.beads/`
  directory exists under the project root
- **WHEN** the skill runs the tracker probe
- **THEN** the drift finding names Beads as the memory-claimed
  tracker, the missing `.beads/` footprint, and surfaces any
  unexpected tracker directories found

#### Scenario: Skill makes no network calls

- **WHEN** the skill runs any of its four signal checks
- **THEN** no check issues a network request, reads a credential
  file, or requires authentication

### Requirement: Every drift finding is phrased as a question

The skill SHALL phrase every drift finding as a yes-or-no question
the user answers to confirm or dismiss an update to memory. Each
finding MUST carry:

- The memory-claimed value (quoted).
- The derived value or signal observation (quoted).
- A one-sentence question ending in a question mark.
- An optional free-text override so the user can supply a value
  different from the derived one.

The report MUST NOT present a derived value as a fact. Phrasing
such as "the path is now X" or "memory should say Y" is
prohibited; phrasing such as "memory says X, but Y looks present.
Does Y still look right?" is required.

#### Scenario: Finding includes memory value, derived value, and
question

- **WHEN** the skill emits a drift finding
- **THEN** the finding output includes the memory-claimed value,
  the derived value, and a sentence ending in a question mark

#### Scenario: Derived values are never presented as facts

- **WHEN** a reader scans any drift finding in the report
- **THEN** no finding contains the phrases "the path is now",
  "memory should say", or equivalent directive assertions about
  derived values

### Requirement: Confirmation is required before any memory edit

The skill SHALL NOT edit any memory file without an explicit user
confirmation per drifted item. The default confirmation flow is
one yes-or-no per item. A batch-accept option MAY be offered only
after the user has answered at least two individual items in the
current run.

If the user dismisses a finding, the skill MUST NOT edit the
corresponding memory file for that finding.

If the user accepts a finding, the skill SHALL edit the
corresponding memory file in place and MUST NOT create a new file
for the update.

#### Scenario: Dismissed finding leaves memory unchanged

- **GIVEN** a drift finding for a claimed value in a memory file
- **WHEN** the user dismisses the finding
- **THEN** the memory file's content for that value is unchanged
  after the skill completes

#### Scenario: Accepted finding updates the existing memory file

- **GIVEN** a drift finding the user accepts with the derived
  value
- **WHEN** the skill applies the update
- **THEN** the existing memory file is edited in place to contain
  the accepted value and no new file is created

#### Scenario: Batch accept is not offered at the start of the run

- **WHEN** the skill emits the first drift finding in a run
- **THEN** the confirmation flow for that finding does not include
  a batch-accept option

#### Scenario: Batch accept is offered only after at least two
individual confirmations

- **WHEN** the user has answered at least two individual drift
  findings in a run
- **THEN** subsequent findings MAY offer a batch-accept option

### Requirement: Shared context drift propagates to dependent
agents

Where drift is detected in
`.claude/agent-memory/engineering-leaders/PROJECT.md` (the Layer 1
shared context), the skill SHALL report the shared-context drift
once under a dedicated `## Shared Context` section and SHALL list
every per-agent memory that references `PROJECT.md` so the user
sees the blast radius in a single view.

When the user confirms a shared-context update, the skill SHALL
apply the update to `PROJECT.md` exactly once. It SHALL NOT
re-prompt the user per dependent agent memory for the same
shared-context item.

#### Scenario: Shared-context drift appears once with dependents
listed

- **GIVEN** drift detected in `PROJECT.md` and two per-agent
  memories that reference it
- **WHEN** the skill emits its report
- **THEN** the `## Shared Context` section contains exactly one
  drift entry for the item and lists both dependent agent memories

#### Scenario: Confirmed shared-context update prompts only once

- **GIVEN** a shared-context drift item and N dependent per-agent
  memories
- **WHEN** the user confirms the shared-context update
- **THEN** the skill applies the update to `PROJECT.md` once and
  does not emit N additional confirmations for the same item

### Requirement: Skill does not re-interrogate un-diffable content

The skill SHALL NOT prompt the user about onboarding content for
which no local signal source exists. Un-diffable content includes,
at minimum: team norms and review practices, persona preferences,
stakeholder relationships, philosophy, and free-text descriptions
of why a decision was made.

The skill MAY print a short reminder at the end of a run listing
un-diffable categories the user may wish to refresh manually via
a full onboarding skill, but MUST NOT ask drift questions about
them.

#### Scenario: Un-diffable categories do not produce drift
findings

- **GIVEN** memory contains team-norm content with no derivable
  signal
- **WHEN** the skill runs
- **THEN** the drift report contains no finding that references
  team-norm content

#### Scenario: Optional reminder lists un-diffable categories

- **WHEN** the skill emits its report
- **THEN** any reminder about un-diffable content appears as a
  plain list of category names with no per-item questions

### Requirement: Fixed report structure

The skill's output SHALL use a fixed markdown structure in the
following order:

1. `## Summary` with a count of drifted items per agent and a
   total.
2. `## Shared Context` with drift in `PROJECT.md` and the list of
   dependent agent memories, omitted if no shared-context drift
   was detected.
3. `## Per-Agent Drift` grouped by agent name, each agent's
   section listing drifted items, unchanged-notable items, and
   new items under named subsections.
4. `## Confirmation` listing each drift item as a numbered
   question the user answers.
5. `## Next Step` with a single-sentence call to action pointing
   at the highest-priority confirmation or suggesting a full
   `/onboard-<agent>` re-run when drift is extensive.

#### Scenario: Report sections appear in the documented order

- **WHEN** the skill emits its report
- **THEN** the section headings appear in the order `## Summary`,
  `## Shared Context` (when present), `## Per-Agent Drift`,
  `## Confirmation`, `## Next Step`

#### Scenario: Shared Context section is omitted when empty

- **GIVEN** no drift detected in `PROJECT.md`
- **WHEN** the skill emits its report
- **THEN** the `## Shared Context` heading is omitted and the
  `## Per-Agent Drift` section follows `## Summary` directly

#### Scenario: Next Step suggests full re-onboarding on extensive
drift

- **GIVEN** an agent whose drift findings cover more than half of
  the agent's onboarding-derived memory content
- **WHEN** the skill emits the `## Next Step` section
- **THEN** the call to action suggests the user re-run the
  corresponding `/onboard-<agent>` skill rather than confirm item
  by item

### Requirement: README documents the skill

The plugin SHALL document the skill in the top-level `README.md`
alongside the existing `/onboard` and audit skills. The README
entry MUST:

- Name the skill `/re-onboard` verbatim.
- Describe it in one paragraph and state in one sentence when to
  run it (for example, periodic cadence, after a structural
  project change, when an agent gives advice that feels out of
  date).
- Cross-reference `/onboard`, `/audit-routing-table`, and
  `/audit-agent-memory` so readers see the four skills as a
  family.
- State that the skill edits memory only after explicit user
  confirmation and does not replace a full `/onboard-<agent>`
  re-run.

#### Scenario: README names the skill and its trigger

- **WHEN** a reader searches `README.md` for `re-onboard`
- **THEN** the search finds a section that names the skill, a
  "when to use it" sentence, and cross-references to `/onboard`,
  `/audit-routing-table`, and `/audit-agent-memory`

#### Scenario: README states the confirmation posture

- **WHEN** a reader reads the README entry for the skill
- **THEN** the entry states that the skill edits memory only
  after explicit user confirmation and that the skill does not
  replace a full `/onboard-<agent>` re-run

