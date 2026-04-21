# Tech Lead Orchestration Tiers

## ADDED Requirements

### Requirement: Three named orchestration tiers

The plugin SHALL document three named tiers of Tech Lead engagement and
reference the same tier vocabulary consistently across the top-level
`README.md` and `agents/tech-lead.md`. The canonical tier labels are:

- `1 — Direct specialist`: single-domain, established pattern; the caller
  invokes the relevant specialist directly and skips the Tech Lead.
- `2 — Standard`: multi-file change within one domain, or an unfamiliar
  area; the Tech Lead runs the existing two-phase consultation protocol
  with routing limited to matched specialists.
- `3 — Full (with Architect escalation)`: cross-domain change, new
  pattern, schema or public API commitment, or one-way-door signal; the
  Tech Lead runs the full protocol and its Phase 2 synthesis names the
  Chief Architect as the escalation target before implementation starts.

The three labels MUST appear verbatim (including the em-dash-separated
form) in every document that references tier names so that the vocabulary
is machine-matchable.

#### Scenario: README documents all three tiers

- **WHEN** a reader opens the top-level `README.md`
- **THEN** the document contains a section that names `1 — Direct
  specialist`, `2 — Standard`, and `3 — Full (with Architect escalation)`
  in that order with a framing paragraph and a "when to use it" sentence
  for each tier

#### Scenario: Agent definition references the same labels

- **WHEN** a reader opens `agents/tech-lead.md`
- **THEN** the Implementation Planning response mode references the three
  tier labels verbatim and does not introduce alternative tier vocabulary

### Requirement: Signals catalog for tier selection

The plugin SHALL publish a signals catalog inside the README orchestration
tiers section that maps observable story attributes to default tier
recommendations. The catalog MUST at minimum cover:

- Touched-file count bands (one file; two through five files in one
  domain; more than five files or multiple domains).
- Domain count, measured against the registered specialist set and
  `## Project Code Area Overrides`.
- One-way-door vocabulary drawn from the Chief Architect's description
  triggers (for example: "schema", "migration", "API contract", "public
  interface", "data model").
- New-pattern vocabulary (for example: "new pattern", "introduce",
  "first time", "convention").
- An unfamiliar-area heuristic that promotes the story one tier above
  the file-count signal alone when the caller has not previously edited
  the affected code.

The catalog MUST include an "if in doubt, escalate" rule that recommends
the higher of two candidate tiers when signals conflict or are absent.
The catalog MUST state explicitly that it is guidance, not gates.

#### Scenario: Catalog lists concrete signals, not platitudes

- **WHEN** a reader inspects the signals catalog
- **THEN** the catalog contains numeric file-count bands, named vocabulary
  lists, and a domain-count rule rather than abstract advice

#### Scenario: If-in-doubt rule is present

- **WHEN** a reader inspects the signals catalog
- **THEN** the catalog contains a rule that defaulting downward is the
  failure mode the catalog prevents, and recommends selecting the higher
  of two candidate tiers when signals are ambiguous

#### Scenario: One-way-door vocabulary mirrors the Chief Architect

- **WHEN** a reader cross-checks the catalog's one-way-door vocabulary
  against the Chief Architect's description triggers in
  `agents/chief-architect.md`
- **THEN** the catalog uses the same named triggers (for example
  "one-way door", "schema", "API contract", "public interface",
  "cross-cutting") so tier 3 promotion aligns with the Architect's own
  invocation vocabulary

### Requirement: Tier-scoped Rule 4

The plugin SHALL scope the Tech Lead's Rule 4 ("Specialist matches require
consultation requests — no exceptions") to tiers 2 and 3. The agent
definition MUST include:

- A preamble clarifying that Rule 4's invariant applies within tiers 2
  and 3 only.
- Guidance that tier 1 work should not reach the Tech Lead; if it does,
  the Tech Lead names the single most relevant specialist and exits
  without running the full routing pass.

Rule 4's "no exceptions" clause MUST remain in force within tiers 2 and
3 so silent skipping of matched specialists is still prohibited where
the tier permits orchestration.

#### Scenario: Rule 4 preamble is present

- **WHEN** a reader inspects the "Rules" section of `agents/tech-lead.md`
- **THEN** Rule 4 includes preamble text that identifies tiers 2 and 3 as
  the scope within which the invariant applies

#### Scenario: Tier-1 exit path is documented

- **WHEN** a reader inspects the Implementation Planning response mode
- **THEN** the procedure documents a step that identifies the operating
  tier first, and that a tier-1 identification results in naming a
  single specialist and exiting without running Phase 1 routing

#### Scenario: Rule 4 invariant holds within tiers 2 and 3

- **WHEN** the Tech Lead is running Phase 1 routing within tier 2 or tier
  3 and the story matches a registered specialist by description or by
  override
- **THEN** a consultation request for that specialist is emitted; no
  silent skipping is permitted

### Requirement: Phase 1 output tier line

The Tech Lead's Phase 1 structured output SHALL include an `## Engagement
Tier` line immediately following the existing `## Engagement Depth` line.
The tier value MUST be one of the fixed strings `1 — Direct specialist`,
`2 — Standard`, or `3 — Full (with Architect escalation)`. The existing
`## Engagement Depth` line MUST be retained unchanged so existing parsers
continue to work.

The Parseable Phase 1 Output Contract subsection of `agents/tech-lead.md`
MUST document `## Engagement Tier` as an additive anchor and explicitly
note that downstream parsers MAY ignore it for backward compatibility.

#### Scenario: Phase 1 output contains the tier line

- **WHEN** the Tech Lead produces Phase 1 output for any tier-2 or tier-3
  story
- **THEN** the output contains an `## Engagement Tier` heading on the
  line immediately following the `## Engagement Depth` heading, and the
  tier value under it matches one of the three fixed strings

#### Scenario: Engagement Depth line is preserved

- **WHEN** the Tech Lead produces Phase 1 output
- **THEN** the `## Engagement Depth` heading and its one-sentence
  rationale remain present in the same position in the template

#### Scenario: Parseable contract documents the additive anchor

- **WHEN** a reader inspects the Parseable Phase 1 Output Contract
  subsection
- **THEN** the contract lists `## Engagement Tier` as an additive anchor
  and states that `/plan-implementation` parsers MAY ignore it

### Requirement: Tier 3 names the Chief Architect in Phase 2

When the Tech Lead runs Phase 2 synthesis on a tier-3 story, the
`## Escalation Flags` section of the Phase 2 output SHALL name the Chief
Architect explicitly, quote the specialist-surfaced signal that triggered
the escalation, and recommend pausing implementation for Architect
consultation before proceeding. The Tech Lead MUST NOT autonomously
invoke the Chief Architect; the escalation is an explicit recommendation
to the user.

When a tier-3 Phase 2 synthesis surfaces no specialist signal that
warrants Architect escalation, the synthesis MAY note the tier as
implicitly downgraded in the narrative; the recorded `## Engagement
Tier` line from Phase 1 is not retroactively edited.

#### Scenario: Tier 3 escalation names the Architect

- **WHEN** the Tech Lead produces Phase 2 output for a tier-3 story whose
  specialists surfaced a one-way-door, schema, or public-API signal
- **THEN** the `## Escalation Flags` section names `chief-architect`,
  quotes the specialist-surfaced signal verbatim, and recommends pausing
  for Architect consultation before implementation begins

#### Scenario: No autonomous Architect invocation

- **WHEN** the Tech Lead produces Phase 2 output flagging an Architect
  escalation
- **THEN** the output is a recommendation to the user; no Agent tool call
  to `chief-architect` is issued by the Tech Lead as part of synthesis

#### Scenario: Tier-3 synthesis with no qualifying signal

- **WHEN** the Tech Lead produces Phase 2 output for a tier-3 story whose
  specialist responses contain no one-way-door, schema, or public-API
  signal
- **THEN** the synthesis narrative MAY note the tier as implicitly
  downgraded, and the `## Escalation Flags` section does not fabricate an
  Architect escalation

### Requirement: User-stated tier override

The Tech Lead SHALL honor an explicit user-stated tier in the invocation
when one is present. The stated tier MUST be used as the operating tier,
and the Tech Lead MUST record the override in its `## Engagement Depth`
rationale line so the choice is visible in the Phase 1 output.

#### Scenario: Explicit override is honored

- **WHEN** a caller invokes the Tech Lead with an explicit tier statement
  (for example, "plan this at tier 2")
- **THEN** the Tech Lead's Phase 1 output uses the stated tier on the
  `## Engagement Tier` line and the `## Engagement Depth` rationale
  mentions that the tier was set by user override

#### Scenario: Signal-based default when no override is present

- **WHEN** the caller does not state a tier explicitly
- **THEN** the Tech Lead selects a tier using the signals catalog and
  records the default on the `## Engagement Tier` line

### Requirement: No changes to adjacent components

The change MUST NOT modify `agents/chief-architect.md`,
`skills/plan-implementation/SKILL.md`, or `skills/refinement-review/SKILL.md`.
Tier awareness in those components is deliberately out of scope; any
future tier-aware behavior in skills is handled by separate changes.

#### Scenario: Chief Architect definition unchanged

- **WHEN** `agents/chief-architect.md` is diffed before and after the
  change
- **THEN** no lines are added, removed, or modified

#### Scenario: Plan-implementation skill unchanged

- **WHEN** `skills/plan-implementation/SKILL.md` is diffed before and
  after the change
- **THEN** no lines are added, removed, or modified

#### Scenario: Refinement-review skill unchanged

- **WHEN** `skills/refinement-review/SKILL.md` is diffed before and after
  the change
- **THEN** no lines are added, removed, or modified
