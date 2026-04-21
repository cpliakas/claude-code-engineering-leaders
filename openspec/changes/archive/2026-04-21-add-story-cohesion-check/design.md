# Design: Story Cohesion Check

## Context

`skills/refine-story/SKILL.md` is the single source of truth for story quality
scoring. The skill parses a story draft, scores six INVEST dimensions, and
evaluates seven coaching principles with PASS or FAIL plus specific rewrites
for each failure. The skill's output format has three fixed sections (INVEST
Scorecard, Coaching Principles, Summary) and two optional sections (Definition
of Done, Horizontal Work).

The seven coaching principles currently cover AC outcome-orientation, DoD
explicitness, estimation placement, scope-boundary clarity, vertical-slice
framing, AC independent-testability, and technical-notes discipline. None of
the seven evaluates whether the story is *one* change or *several bundled*
changes.

The Agile Coach agent (`agents/agile-coach.md`) invokes `/refine-story` as its
Story Review skill and applies judgment overlays for cases the skill cannot
resolve mechanically (horizontal-work legitimacy, scope-boundary norms, DoD
placement). The Product Owner agent (`agents/product-owner.md`) consults the
Agile Coach inline during `/write-story` and `/write-epic` authoring and
incorporates the coach's feedback into the final artifact before presenting
it to the user.

A real recent case on an adjacent project exposed the gap. A story proposed
adding two unrelated fields to the same UI modal: one a parity fix for an
existing backend field (low risk, pure UI gap closure), one a net-new product
capability (DAG semantics, UX surface area to explore, project does not yet
use the capability). The story passed INVEST and all seven coaching
principles and entered the backlog at P3. The conflation was only caught in a
priority-review conversation, and the story was split after the fact.

The existing principles miss this pattern for structural reasons:

- INVEST **Independent** scopes to inter-story dependency: "is this story
  waiting on another in-progress story?" It does not ask "does this story
  secretly describe two things?"
- INVEST **Small** uses AC count as a heuristic. A story with two ACs can
  still be two stories.
- **Scope Boundaries Explicit** (coaching principle #4) checks whether
  exclusions are *stated*, not whether the items included should be split.
- **Each AC Independently Testable** (coaching principle #6) passes as long
  as each AC is individually verifiable in isolation, which bundled stories
  satisfy easily because the "independent AC" test cares about AC shape, not
  AC subject matter.
- **Vertical Slice over Horizontal Layer** (coaching principle #5) catches
  technical-layer or enabler tasks framed as stories, not user-facing
  conflation.

This change adds a write-time check to close that gap.

## Goals / Non-Goals

**Goals:**

- Give `refine-story` a mechanical check that flags a story whose ACs
  describe two or more distinct product changes bundled into one artifact.
- Produce a **Suggested split** output block on failure that proposes two or
  more stories, each with its own role / capability / benefit and its own
  narrowed AC set. The block proposes; the user decides whether to split.
- Document the intentional-vs-accidental judgment overlay on the Agile
  Coach so the mechanical flag is interpreted correctly (a UI-plus-backend
  pair that must ship atomically is intentional; two capabilities sharing a
  template by coincidence is accidental).
- Extend the Product Owner's Requirement Authoring flow to act on a
  conflation finding: offer the split, author each child story via
  `/write-story`, and do not merge the split back into one story under any
  framing.
- Preserve full backward compatibility of the `refine-story` output: the
  existing seven principles keep their numbering and rules, and the Summary
  line's count changes from "X of 7" to "X of 8" without breaking consumers
  that parse by section header.

**Non-Goals:**

- Retroactively reviewing stories already filed in the issue tracker. This
  is a write-time authoring check, not a backlog-grooming tool. A later
  change MAY add a batch cohesion sweep over the tracker; this change does
  not ship it.
- Automatically splitting a story without user confirmation. The check
  proposes a split; the user accepts, rejects, or revises. Unilateral
  splitting is a failure mode, not a feature.
- Replacing or subsuming INVEST **Independent**. The two checks operate on
  different axes and both continue to run. Independent evaluates inter-story
  coupling; Single-Concept Cohesion evaluates intra-story cohesion.
- Auto-detecting conflation in epics. `/decompose-requirement` already
  handles multi-item breakdown for epics. The cohesion check is for stories
  that should have been two stories from the start.
- Changing `/write-story`. The authoring skill's structure and output are
  unchanged. The cohesion check acts through the coach's inline review,
  which is already part of the authoring flow.
- Changing the Definition of Done rule or any existing principle's failure
  signals.

## Decisions

### D1. Add as coaching principle #8 named "Single-Concept Cohesion"

The check is added as the eighth coaching principle. The seven existing
principles keep their current numbering (#1 through #7) and their current
rules. The new principle is principle #8 titled **Single-Concept Cohesion**.

**Rationale:** The `refine-story` skill already has an established coaching-
principle framework with PASS/FAIL scoring, failure-signal enumeration, and
suggested-rewrite output per principle. Adding the cohesion check as an
eighth principle reuses that framework and keeps the skill's output shape
coherent. Renumbering the existing principles would break external
references in the Agile Coach and Product Owner agent definitions, in any
project memory that has quoted principle numbers, and in the plugin's own
historical documentation.

**Alternatives considered:** Create a separate check outside the seven
principles (for example, as a new top-level "Cohesion" section alongside
INVEST and Coaching Principles). Rejected: fragments the output format for
no benefit; the cohesion check uses the same PASS/FAIL plus suggested-action
shape that the principles already use. Also considered: fold the check into
INVEST **Independent** by broadening its definition. Rejected: confuses two
different axes (inter-story coupling vs intra-story cohesion) and forces a
backward-incompatible semantic change on a standard INVEST criterion that
other projects rely on.

### D2. Six failure signals, two-signal quorum

The principle defines six observable failure signals:

1. ACs describe adding multiple unrelated fields, features, or capabilities
   to the same surface (UI modal, API endpoint, CLI command).
2. One AC is a gap fix or parity-with-backend change while another is
   net-new product behavior or a new capability.
3. ACs have materially different risk profiles (for example, low-risk UI
   polish alongside a new capability with unexplored UX surface area).
4. ACs would naturally carry different priorities if filed separately (for
   example, one ships this sprint, the other is a backlog candidate).
5. The story's scope statement itself hedges by connecting items with "and"
   where the items do not share a user outcome ("add X and Y" where X
   serves one persona goal and Y serves a different one).
6. The independence test fails in reverse: splitting the story does **not**
   create awkward dependency chains. Each half could ship independently
   and deliver user value on its own.

The principle raises a FAIL when **two or more** of these six signals are
observed. One signal alone is insufficient; many real single-concept
stories exhibit exactly one signal (for example, a story with materially
different risk levels across its ACs is common and not always conflated).

**Rationale:** A quorum of two signals filters out the noise of single-
signal matches while catching the real conflation pattern, which typically
lights up three or four signals at once (different fields, different
risks, different priorities, independent-half test passes). The quorum
number is a tunable that can be adjusted in a follow-up if the false-
positive or false-negative rate proves wrong in practice.

**Alternatives considered:** Require all six signals. Rejected: too strict;
real conflation rarely manifests across every axis. Also considered:
single-signal trigger. Rejected: over-flags legitimate single-concept
stories. Also considered: weighted signals (some count as two). Rejected:
adds scoring complexity without clear payoff; a flat quorum keeps the
check transparent and reproducible.

### D3. Suggested split output block proposes two or more distinct stories

On FAIL, the principle's output section includes a **Suggested split**
block. The block contains:

- One entry per proposed child story.
- Each entry states the child's role / capability / benefit (the standard
  user-story statement).
- Each entry names the ACs from the original draft that belong to that
  child, possibly reworded to stand alone.
- A one-line note explaining why the split draws the boundary where it
  does (for example, "split on persona outcome: half A serves the
  maintenance persona, half B serves the power-user persona").

The block does **not** produce a rewritten single story that merges the
halves. Rewriting-to-merge is an anti-pattern for conflation; the correct
action is always to split.

**Rationale:** The existing seven principles produce "suggested rewrite"
output on FAIL because rewriting is the correct action for those failures
(for example, a criterion worded as "the response body contains X" is
rewritten to describe the user-observable behavior). Conflation's correct
action is split, not rewrite, so the output block is named to match the
action. The per-child role / capability / benefit plus AC mapping gives
the Product Owner everything it needs to invoke `/write-story` on each
child.

**Alternatives considered:** Produce a suggested rewrite that merges the
halves into a more unified story. Rejected: papers over the bundling
instead of fixing it. Also considered: produce only a FAIL flag with no
structured split. Rejected: leaves the Product Owner to derive the split
from the draft, which was the manual-review recovery step the change is
designed to eliminate. Also considered: require the block to be exactly
two children. Rejected: genuine conflations occasionally bundle three
items (for example, three unrelated settings on one preferences page).

### D4. Agile Coach applies the intentional-vs-accidental overlay

The Agile Coach agent definition gains a short subsection documenting the
judgment overlay. The overlay states:

- **Intentional bundling is legitimate** when the bundled items must ship
  atomically to avoid a broken intermediate state. Example: a UI change
  that renders a new backend field along with the backend migration that
  adds the field. Splitting produces a story with a UI change whose
  backend does not exist, or a backend change with no user-visible
  outcome. Both halves would individually fail vertical-slice or cause
  integration drift.
- **Accidental bundling is the failure mode** when the items share a
  surface by coincidence rather than by requirement. Example: a story
  that adds two unrelated preferences to the same settings modal. The
  items share the modal but not a user outcome; each could ship
  independently without breaking anything.
- The test: ask "does the atomicity of the delivery require these to be
  one story?" If yes, the bundle is intentional and the FAIL is a false
  positive. The coach notes the intent in its response and declines to
  split. If no, the FAIL stands and the coach forwards the Suggested
  split block to the Product Owner for reauthoring.

The overlay lives in the Agile Coach's **Key Knowledge** section as a
judgment heuristic, consistent with how the existing overlays
(horizontal-work legitimacy, scope-boundary norms, DoD placement) are
documented.

**Rationale:** The mechanical signals in the skill cannot distinguish
intent. The skill is deliberately conservative (it flags the mechanical
pattern) and the coach's job is to apply judgment over the skill's output.
Keeping the overlay on the coach preserves the clean division between the
skill's mechanical scoring role and the coach's judgment role.

**Alternatives considered:** Put the overlay in the skill itself as a
prompt "do not fail if the bundle is intentional." Rejected: the skill
cannot reliably judge intent, and pushing the decision into the skill
would reintroduce the false-negative failure mode the change is designed
to eliminate. Also considered: make the Coach the only consumer of the
Suggested split block and have the skill always produce the block.
Rejected: standalone `/refine-story` invocations (outside the Coach
consultation path) still benefit from seeing the split proposal even
without coach judgment layered on top.

### D5. Product Owner splits and reauthors; never merges a conflated story

The Product Owner agent definition's Requirement Authoring flow gains an
explicit step: when the Agile Coach's inline review returns a Single-
Concept Cohesion FAIL with a Suggested split block, the Product Owner:

1. Presents the split to the user. The user accepts, rejects (declaring
   intentional bundling), or revises the draft.
2. On user acceptance, invokes `/write-story` once per child story using
   the Suggested split block's role / capability / benefit and AC mapping
   as the input.
3. Runs the Strategic triage step (consult `chief-architect` and
   `ux-strategist`) on each child story independently, not on the
   combined original.
4. Does **not** produce a single merged story that attempts to "fix" the
   conflation by rephrasing.

This step is inserted in the Requirement Authoring flow after the
existing "incorporate the coach's feedback into the artifact" step, so
the coach's cohesion finding is the first thing the PO acts on before
moving on to other feedback.

**Rationale:** The failure mode the change is designed to eliminate is
filing a single conflated story. The PO's natural incorporation flow
rewrites ACs and fixes individual-principle failures in place, which
does not work for conflation because the correct fix changes the number
of stories, not the content of one story. Explicitly calling out the
split-and-reauthor behavior prevents the PO from collapsing the
Suggested split back into the original artifact during incorporation.

**Alternatives considered:** Have the coach invoke `/write-story` on
each child directly. Rejected: violates the established delegation (the
PO owns authoring; the coach owns craft quality). Also considered: have
the skill write out the child stories as artifacts. Rejected: the skill
is scoring-only in the current model; writing new artifacts is an
authoring action that belongs to the PO and the `/write-story` skill.

### D6. Output format adds a new principle row and extends the Summary count

The `refine-story` output's Coaching Principles section gains a new
principle row (#8), structured the same way as the existing seven:

```
8. **Single-Concept Cohesion**: PASS/FAIL
   - [Explanation]
   - *Suggested split:* [per-child role/capability/benefit and AC mapping,
     if failing]
```

The Summary section's counting line changes from:

> X of 6 INVEST criteria passing. Y of 7 coaching principles passing.

to:

> X of 6 INVEST criteria passing. Y of 8 coaching principles passing.

No other sections change. The INVEST Scorecard section, Definition of
Done section, Horizontal Work section, and Priority fixes list are all
unchanged in shape.

**Rationale:** Additive output change preserves compatibility with any
consumer that parses the report by section header. The Priority fixes
list naturally absorbs cohesion failures because the list is ordered by
impact; a FAIL on cohesion typically ranks high because the split
affects the number of stories entering the backlog.

**Alternatives considered:** Add a new top-level Cohesion section
between Coaching Principles and Definition of Done. Rejected: fragments
the report format; using the established principle shape is cleaner.
Also considered: leave the Summary line reading "X of 7 coaching
principles passing" and count cohesion separately. Rejected: confusing
and inconsistent with the "count all principles" convention.

### D7. Standalone and inline invocation paths both support the check

The Single-Concept Cohesion principle runs in both invocation paths:

- **Standalone `/refine-story`:** The user invokes the skill with a
  story draft. The skill scores all six INVEST dimensions and all
  eight coaching principles and produces the structured report.
- **Inline during `/write-story`:** The Product Owner consults the
  Agile Coach mid-authoring. The coach invokes `/refine-story` with
  the draft. The skill produces the same report. The coach applies
  the intentional-vs-accidental overlay (D4) and returns either
  "cohesion OK, intentional bundle" or "cohesion FAIL, here is the
  proposed split" to the PO.

Both paths use the same skill, the same scoring, and the same output
format. The difference is only in who consumes the output and how.

**Rationale:** The skill is the single source of truth for scoring.
Two invocation paths with the same scoring logic keep the rubric
consistent regardless of how the check is triggered.

**Alternatives considered:** Run cohesion only inline during
`/write-story`. Rejected: standalone `/refine-story` users (the
primary trigger for the coach's standalone-coaching mode) would
miss the check. Also considered: run cohesion only standalone. The
inverse problem: inline authoring would miss it, which is exactly
the pattern that motivated the change.

## Risks / Trade-offs

- **False positives on legitimate atomic bundles.** A UI-plus-backend
  story that must ship atomically genuinely belongs as one story,
  even though the two ACs describe different layers. Mitigation: the
  Agile Coach's intentional-vs-accidental overlay (D4) explicitly
  handles this case. The skill flags the mechanical pattern; the
  coach decides whether the flag is a real issue.
- **False negatives on subtle conflations.** A story whose ACs
  share a persona and a surface but secretly serve different user
  outcomes may not trip two of the six signals. Mitigation: the
  check is a floor, not a ceiling. The coach's judgment overlay
  can raise additional conflation concerns outside the six signals
  when experience suggests them.
- **User confusion about "split" vs "rewrite" actions.** Users who
  expect the skill to suggest a rewrite (the existing action for
  other principle failures) may be surprised by a split action.
  Mitigation: the output block is explicitly named "Suggested
  split" and the principle's explanation text states "this is a
  split, not a rewrite." The Agile Coach documentation reinforces
  this.
- **Ambiguity on "unrelated" between ACs.** Whether two items
  count as related or unrelated is judgment-laden. Mitigation: the
  six signals are objective (different fields, different risks,
  different priorities, independent-half test) rather than
  subjective ("unrelated"). The quorum-of-two rule (D2) prevents
  any single subjective signal from triggering a FAIL alone.
- **Coach-overlay drift.** If the Agile Coach's judgment overlay
  text drifts out of sync with the skill's failure signals, the
  mechanical flag and the judgment response will contradict each
  other. Mitigation: the overlay lives in the Agile Coach's Key
  Knowledge section as a short rule, not as a duplicate of the
  skill's signal list. The overlay describes the interpretation
  layer only; the signals remain in the skill.
- **Principle-number sprawl.** Adding an eighth coaching principle
  grows the rubric and may create pressure to add a ninth and
  tenth for other categories. Mitigation: the change adds one
  principle with explicit failure signals and a specific authoring
  problem it solves. Future principle additions would need the
  same justification; drift toward a twelve-principle rubric is
  out of scope for this change and should be resisted at the time
  it arises.

## Migration Plan

No migration required. The change is additive.

- Existing stories in any tracker continue to exist unchanged. The
  check runs at write-time on new or in-review drafts; it does not
  sweep the backlog.
- The existing seven coaching principles keep their numbering and
  their rules. Any agent memory or user documentation that quotes
  "coaching principle #5" continues to refer to the same principle.
- The `refine-story` output format changes in two places only: a
  new row in the Coaching Principles section and a revised count
  in the Summary line. Consumers that parse by section header are
  unaffected.
- The Agile Coach agent definition gains a short subsection in Key
  Knowledge and a sentence in How to Respond. The Product Owner
  agent definition gains a step in Requirement Authoring. No
  existing subsection is removed or reworded.
- Rollback: remove principle #8 from the skill, revert the Summary
  count, remove the Key Knowledge overlay from the coach, and
  remove the Requirement Authoring step from the PO. Existing
  coaching consultations continue to produce the prior seven-
  principle output under the reverted model because the current
  model is a superset of the prior one.

## Open Questions

- Should the check run on `/write-bug` and `/write-spike` drafts
  as well as stories? Deferred: bugs and spikes do not follow the
  role / capability / benefit shape and the six signals do not
  apply cleanly. The initial scope is user stories only.
- Should the Suggested split block include a suggested sequencing
  for the resulting child stories (which ships first)? Deferred:
  sequencing is the Product Owner's jurisdiction, not the coach's.
  The PO's Strategic triage step runs on each child after the
  split, which already covers sequencing.
- Should the quorum threshold (currently two signals out of six)
  be exposed as a tunable or remain fixed? Deferred: fixed for the
  initial implementation; revisit after observing real-world
  false-positive and false-negative rates.
- Should the skill emit a machine-readable JSON alongside the
  markdown report so downstream tooling can act on the cohesion
  flag programmatically? Deferred: no current downstream consumer
  exists; premature to design the format. Reopen if a consumer
  materializes.
- Should the Engineering Manager's SDLC health report include a
  cohesion-failure rate metric (stories flagged as conflated per
  sprint)? Deferred: useful as a signal but not part of this
  change. Reopen after the check has produced a few sprints of
  data to measure against.
