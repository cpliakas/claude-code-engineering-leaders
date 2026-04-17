# Refinement Review Skill

## ADDED Requirements

### Requirement: Skill definition and invocation

The plugin SHALL provide a user-invokable skill named `refinement-review`
(invoked as `/refinement-review`) located at
`skills/refinement-review/SKILL.md`. The skill definition MUST declare
`user-invokable: true`, `context: fork`, and include `Agent` in
`allowed-tools` so it can spawn sub-agents for the peer fan-out. The
`argument-hint` MUST document that the skill accepts a story body, file path,
or issue reference.

#### Scenario: Skill file exists with required frontmatter
- **WHEN** a user inspects `skills/refinement-review/SKILL.md`
- **THEN** the file exists with YAML frontmatter containing `name:
  refinement-review`, `user-invokable: true`, `context: fork`, and an
  `allowed-tools` list that includes `Agent`

#### Scenario: Skill appears in user-invokable skill list
- **WHEN** the user lists available user-invokable skills
- **THEN** `refinement-review` appears in the list with a description that
  summarizes it as a parallel consultation with the Product Owner, Chief
  Architect, and UX Strategist

### Requirement: Input resolution

The skill SHALL accept `$ARGUMENTS` in three forms: inline story body, file
path, and issue reference. Input resolution MUST follow the same conventions
as `/plan-implementation`: values that look like a file path (start with
`/`, `./`, or `../`) are read from disk; values that match issue-reference
patterns (`[A-Z]+-\d+`, `#\d+`, or `beads-\d+`) are resolved via `bd show`
first and `gh issue view` as a fallback; all other values are treated as
inline story body.

When `$ARGUMENTS` is empty, the skill MUST prompt the user for a story or
issue reference before proceeding and MUST NOT fabricate or placeholder a
story.

When an issue reference cannot be resolved by any configured CLI, the skill
MUST surface the failure and prompt the user to paste the story body
directly, rather than proceeding with no content.

#### Scenario: Inline story body
- **WHEN** a user invokes `/refinement-review` with a pasted story draft as
  the argument
- **THEN** the skill uses the pasted content verbatim as the story input for
  all three peer invocations

#### Scenario: File path input
- **WHEN** a user invokes `/refinement-review ./stories/draft.md`
- **THEN** the skill reads `./stories/draft.md` and uses its contents as the
  story input

#### Scenario: Resolvable issue reference
- **WHEN** a user invokes `/refinement-review beads-123` and `bd show
  beads-123` returns story content
- **THEN** the skill uses the resolved content as the story input without
  prompting the user

#### Scenario: Unresolvable issue reference
- **WHEN** a user invokes `/refinement-review ABC-999` and no configured CLI
  returns content for the reference
- **THEN** the skill surfaces an `[INPUT ERROR]` notice naming the attempted
  commands and prompts the user to paste the story body directly

#### Scenario: Empty argument
- **WHEN** a user invokes `/refinement-review` with no argument
- **THEN** the skill prompts for a story or issue reference and does not
  invoke any peer until input is provided

### Requirement: Fixed peer set and parallel fan-out

The skill SHALL always invoke exactly three peer agents for every run:
`product-owner`, `chief-architect`, and `ux-strategist`. The peer set MUST
NOT be configurable per invocation. The three agents MUST be invoked in a
single parallel batch using the Agent tool so responses are collected
concurrently rather than sequentially.

Each peer MUST receive a role-specific prompt (see the role-specific prompt
requirement) together with the full resolved story input. Prompts MUST NOT
include any other peer's output; each peer must review the story
independently.

#### Scenario: All three peers invoked
- **WHEN** the skill completes Step 2 (peer fan-out) of a run
- **THEN** the skill has issued exactly three Agent tool calls with
  `subagent_type` equal to `product-owner`, `chief-architect`, and
  `ux-strategist`

#### Scenario: Parallel execution
- **WHEN** the skill invokes the three peers
- **THEN** the three Agent tool calls are issued in a single assistant turn
  (parallel fan-out) rather than across three sequential turns

#### Scenario: No peer sees another peer's response
- **WHEN** an Agent tool call is issued to any of the three peers
- **THEN** the prompt body contains only the story input and the peer's
  role-specific framing, with no content from the other two peers

### Requirement: Role-specific prompts

The skill SHALL send each peer a role-specific prompt that frames the
review in terms of that peer's jurisdiction:

- Product Owner prompt focuses on scope, business value, roadmap fit, and
  whether the story is the right thing to build next.
- Chief Architect prompt focuses on one-way doors, cross-cutting impact,
  data-model or contract implications, and forward compatibility.
- UX Strategist prompt focuses on persona fit, user-observable outcomes, and
  whether the story creates behavioral inconsistency with other surfaces.

Prompts MUST be short and MUST NOT re-enumerate the agent's full
jurisdiction; each agent already knows its job. Each prompt MUST instruct
the peer to conclude with an explicit verdict line in the vocabulary `ready`
/ `needs-revision` / `blocked` so the skill can machine-read the result.

#### Scenario: Role framing is peer-specific
- **WHEN** the skill issues the peer invocations
- **THEN** the Product Owner prompt references scope/value/roadmap, the
  Chief Architect prompt references one-way doors/cross-cutting, and the UX
  Strategist prompt references persona fit/behavioral consistency

#### Scenario: Verdict line is requested
- **WHEN** a peer receives its prompt
- **THEN** the prompt explicitly asks the peer to end its response with a
  line of the form `Verdict: ready` or `Verdict: needs-revision` or
  `Verdict: blocked`

### Requirement: Verbatim preservation of peer responses

The consolidated report SHALL include each peer's response verbatim under a
per-peer section. The skill MUST NOT summarize, paraphrase, or rewrite the
peer's response text. Formatting adjustments limited to wrapping the peer's
output in a fenced block or indented quote for visual separation are
permitted; semantic editing is not.

#### Scenario: Peer output appears unmodified
- **WHEN** the skill renders the consolidated report
- **THEN** each peer section contains the peer's response text byte-for-byte
  (modulo a single outer fence or indentation level used for visual
  grouping)

### Requirement: Readiness verdict and peer accountability

The skill SHALL compute an overall readiness verdict from the three peer
verdict lines and include it prominently at the top of the consolidated
report. Verdict aggregation rules:

- If all three peers return `ready`, the overall verdict is `ready`.
- If no peer returns `blocked` and at least one peer returns
  `needs-revision`, the overall verdict is `needs-revision`.
- If any peer returns `blocked`, the overall verdict is `blocked`.
- If any peer invocation failed or returned no parseable verdict, the
  overall verdict MUST be at least `needs-revision` and the failed peer MUST
  be named.

When the overall verdict is `needs-revision` or `blocked`, the report MUST
name the peer(s) whose verdict drove the non-ready state.

#### Scenario: Unanimous ready
- **WHEN** all three peers return `Verdict: ready`
- **THEN** the consolidated report opens with `Overall verdict: ready`

#### Scenario: One peer flags blocked
- **WHEN** the Chief Architect returns `Verdict: blocked` and the other two
  return `Verdict: ready`
- **THEN** the consolidated report opens with `Overall verdict: blocked`
  and names `chief-architect` as the peer responsible

#### Scenario: Mixed needs-revision without blocked
- **WHEN** one peer returns `Verdict: needs-revision`, one returns `Verdict:
  ready`, and one returns `Verdict: ready`
- **THEN** the consolidated report opens with `Overall verdict:
  needs-revision` and names the single peer responsible

#### Scenario: Peer verdict unparseable
- **WHEN** a peer response does not contain a parseable verdict line
- **THEN** the consolidated report's overall verdict is at least
  `needs-revision`, and the peer is named with an explicit "verdict not
  parseable" note

### Requirement: Objections section for disagreement

The consolidated report SHALL include an `## Objections` section whenever
peers disagree (mixed verdicts) or any peer raises a stated reservation
inside a `ready` overall verdict. Each objection MUST appear as one bullet
per peer, preserving the peer's own wording verbatim. When all peers return
clean `ready` with no stated reservations, the section MAY be omitted.

#### Scenario: Disagreement surfaces in Objections
- **WHEN** the Product Owner returns `Verdict: needs-revision` with a scope
  concern and the other two peers return `Verdict: ready`
- **THEN** the consolidated report includes an `## Objections` section with
  a `product-owner` bullet that quotes the scope concern verbatim

#### Scenario: Unanimous clean ready omits Objections section
- **WHEN** all three peers return `Verdict: ready` with no stated
  reservations
- **THEN** the consolidated report omits the `## Objections` section

### Requirement: Graceful handling of no-concerns and failed peers

The skill SHALL render a peer's section with a "no concerns raised" marker
alongside the verbatim response when the peer response indicates no
substantive concerns. The skill MUST render a failed peer's section with an
explicit "invocation failed; input absent from this refinement" marker when
the invocation returns empty, errors, or targets an unresolvable agent. A
failed peer section MUST NOT be silently omitted.

#### Scenario: Peer reports no concerns
- **WHEN** the UX Strategist returns a response containing `Verdict: ready`
  with no listed concerns
- **THEN** the UX Strategist section in the report includes a "no concerns
  raised" marker alongside the verbatim response

#### Scenario: Peer invocation fails
- **WHEN** the Product Owner Agent tool call returns an empty response or
  errors
- **THEN** the Product Owner section in the report contains a "invocation
  failed; input absent from this refinement" marker and the overall verdict
  is at least `needs-revision` with `product-owner` named

### Requirement: Consolidated report structure

The skill SHALL produce a single consolidated report with this section
order and composition:

1. Overall verdict line (top of report).
2. Named accountable peer(s) line when verdict is not `ready`.
3. One `## <agent-name>` section per peer, in the fixed order
   `product-owner`, `chief-architect`, `ux-strategist`, each containing the
   verbatim response and any failure/no-concerns marker.
4. `## Objections` section when applicable (per the objections requirement).
5. Trailing `## Next Steps` section with a one- to three-line recommendation
   appropriate to the verdict (e.g., "proceed to `/plan-implementation`" for
   `ready`; "revise per <peer>'s concern and re-run `/refinement-review`"
   for `needs-revision`; "escalate <peer>'s concern before reopening the
   story" for `blocked`).

#### Scenario: Section order is fixed
- **WHEN** the consolidated report is rendered
- **THEN** peer sections appear in the order `product-owner`,
  `chief-architect`, `ux-strategist` regardless of which peer responded
  first

#### Scenario: Next Steps references correct follow-on
- **WHEN** the overall verdict is `ready`
- **THEN** the `## Next Steps` section recommends advancing to
  `/plan-implementation` as the next action

### Requirement: Agent description updates

The plugin SHALL update the `product-owner`, `chief-architect`, and
`ux-strategist` agent definitions to document membership in the refinement
cell and to reference `/refinement-review` as the ceremony that convenes
the three peers. Updates MUST be confined to descriptive body content
(e.g., a "Collaboration" or equivalent section). Agent frontmatter schema,
memory protocol, and jurisdiction MUST NOT change as part of this
requirement.

#### Scenario: Agent files reference the skill
- **WHEN** a user reads `agents/product-owner.md`, `agents/chief-architect.md`,
  or `agents/ux-strategist.md`
- **THEN** the body includes a reference to `/refinement-review` and a
  one-line statement naming the other two peers in the refinement cell

#### Scenario: Frontmatter is unchanged
- **WHEN** the frontmatter of the three agent files is compared before and
  after the change
- **THEN** no frontmatter field values differ

### Requirement: README documentation

The plugin's top-level `README.md` SHALL document `/refinement-review`,
explicitly contrasting it with `/write-story` (authoring, not review), the
existing `refine-story` skill (structural INVEST scoring), and
`/plan-implementation` (implementation planning after refinement). The
documentation MUST state that trivial stories may legitimately skip the
ceremony.

#### Scenario: README contrasts the refinement tools
- **WHEN** a user reads the `README.md`
- **THEN** the document contains a section naming `/refinement-review`,
  `refine-story`, and `/write-story` and explains when to use each
