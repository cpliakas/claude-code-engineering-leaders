# story-cohesion-check Specification

## Purpose

Provide a write-time single-concept cohesion check layered on top of the existing INVEST and seven-principle rubric in `/refine-story`. The check detects stories that bundle two or more discrete changes into one artifact, surfaces the failure signals, and proposes a split for user confirmation. The check covers the eighth coaching principle (Single-Concept Cohesion), the intentional-vs-accidental judgment overlay on the Agile Coach, the Product Owner's split-and-reauthor flow, and the extension to the `refine-story` output format.
## Requirements
### Requirement: refine-story SHALL score an eighth coaching principle named Single-Concept Cohesion

The `skills/refine-story/SKILL.md` rubric SHALL evaluate an eighth coaching
principle, in addition to the existing seven, titled **Single-Concept
Cohesion**. The principle evaluates whether the story describes one
coherent change or several bundled changes. The existing seven coaching
principles MUST retain their current numbering (#1 through #7) and their
current rules; the new principle MUST be added as principle #8.

The principle MUST produce a PASS or FAIL verdict for every story the
skill scores, using the same PASS/FAIL shape as the existing seven
principles. The principle MUST apply in every invocation path of
`/refine-story`, including standalone invocation and invocation via the
Agile Coach's inline consultation during `/write-story`.

#### Scenario: The rubric lists eight coaching principles

- **WHEN** a reader inspects `skills/refine-story/SKILL.md`
- **THEN** the Evaluate Coaching Principles section contains exactly
  eight numbered principles, with Single-Concept Cohesion listed as
  principle #8

#### Scenario: The existing seven principles keep their numbering and rules

- **WHEN** a reader compares the rules for principles #1 through #7
  before and after this change
- **THEN** each principle's number, name, and failure signals are
  unchanged in substance

#### Scenario: Every story review includes a cohesion verdict

- **WHEN** `/refine-story` is invoked with any story draft
- **THEN** the Coaching Principles section of the output contains an
  entry for Single-Concept Cohesion with a PASS or FAIL verdict

### Requirement: Single-Concept Cohesion SHALL define six failure signals with a two-signal quorum

The Single-Concept Cohesion principle SHALL enumerate six observable
failure signals and MUST raise a FAIL verdict when two or more signals
are observed in the same story draft. The six signals are:

1. Acceptance criteria describe adding multiple unrelated fields,
   features, or capabilities to the same surface (UI modal, API
   endpoint, CLI command, or other shared artifact).
2. One acceptance criterion is a gap fix or parity-with-backend change
   while another acceptance criterion is net-new product behavior or a
   new capability.
3. Acceptance criteria have materially different risk profiles (for
   example, a low-risk UI polish criterion alongside a new-capability
   criterion with unexplored UX surface area).
4. Acceptance criteria would naturally carry different priorities if
   filed separately (for example, one criterion ships this sprint while
   another is a backlog candidate).
5. The story's scope statement itself hedges by joining items with
   "and" where the items do not share a user outcome ("add X and Y"
   where X serves one persona goal and Y serves a different one).
6. The independence test passes: splitting the story into the
   candidate halves would not create awkward dependency chains, and
   each half could ship independently and deliver user value on its
   own.

A single signal MUST NOT trigger a FAIL on its own. The skill MUST
treat fewer than two signals as a PASS and MAY note any observed
single signal as a non-failing observation in the explanation text.

#### Scenario: Two or more signals raise a FAIL

- **WHEN** a story draft exhibits signal #1 (two unrelated fields on
  one modal) and signal #4 (different priorities if split)
- **THEN** the principle returns FAIL and the explanation enumerates
  the two observed signals

#### Scenario: One signal alone passes

- **WHEN** a story draft exhibits signal #3 (different risk profiles
  across ACs) and no other signal
- **THEN** the principle returns PASS and the explanation MAY note
  the single observed signal without raising FAIL

#### Scenario: Zero signals passes

- **WHEN** a story draft exhibits none of the six signals
- **THEN** the principle returns PASS and the explanation is brief

### Requirement: A FAIL verdict SHALL include a Suggested split output block

When the Single-Concept Cohesion principle returns FAIL, the skill MUST
include a **Suggested split** output block in the principle's section
of the report. The block MUST contain one entry per proposed child
story, and each entry MUST include:

- A role / capability / benefit statement in the standard user-story
  form ("As a <role>, I want <capability>, so that <benefit>").
- The subset of the original draft's acceptance criteria that belong
  to the child, possibly reworded to stand alone.
- A one-line note explaining why the split boundary is drawn where
  it is (for example, "split on persona outcome", "split on risk
  profile", "split on shippable-unit of value").

The block MUST propose at least two child stories. The block MUST NOT
produce a merged rewrite that combines both halves into a single
restated story; rewriting-to-merge is an anti-pattern for conflation
and the correct action is always a split.

#### Scenario: FAIL produces a split block with two or more children

- **WHEN** the principle returns FAIL on a story that conflates two
  distinct capabilities
- **THEN** the Suggested split block contains two child entries,
  each with its own role / capability / benefit statement and its
  own AC subset

#### Scenario: Three-way conflation produces three children

- **WHEN** the principle returns FAIL on a story that bundles three
  unrelated settings on one preferences page
- **THEN** the Suggested split block contains three child entries
  rather than two

#### Scenario: FAIL does not produce a merged rewrite

- **WHEN** the principle returns FAIL
- **THEN** the principle's output section does NOT include a
  "Suggested rewrite" block that combines the halves into a single
  restated story; only the Suggested split block is produced

#### Scenario: PASS produces no split block

- **WHEN** the principle returns PASS
- **THEN** the principle's output section does NOT include a
  Suggested split block

### Requirement: refine-story output SHALL extend the Summary count to eight coaching principles

The `/refine-story` output's Summary section SHALL count all eight
coaching principles in its summary line. The line MUST read "X of 6
INVEST criteria passing. Y of 8 coaching principles passing." instead
of the prior "Y of 7 coaching principles passing." wording. The INVEST
Scorecard section, Definition of Done section, Horizontal Work section,
and Priority fixes list MUST remain structurally unchanged.

The Coaching Principles section MUST list the new principle in
position #8, using the same per-principle shape as the existing seven:
bolded name, PASS/FAIL verdict, explanation bullet, and (on FAIL) a
suggested-action block named appropriately for the principle's
corrective action. For Single-Concept Cohesion, the suggested-action
block MUST be named "Suggested split" per the preceding requirement.

#### Scenario: Summary counts eight principles

- **WHEN** a user inspects the Summary section of a `/refine-story`
  report
- **THEN** the summary line reads "X of 6 INVEST criteria passing.
  Y of 8 coaching principles passing." with Y reflecting the count
  of passing principles out of eight

#### Scenario: The principle row uses the established shape

- **WHEN** a reader inspects the Coaching Principles section
- **THEN** principle #8 follows the same layout as principles #1
  through #7: numbered heading with bolded name, PASS/FAIL verdict,
  one-sentence explanation, and a suggested-action block on FAIL

#### Scenario: Other output sections are unchanged

- **WHEN** a reader compares the INVEST Scorecard, Definition of
  Done, Horizontal Work, and Priority fixes sections before and
  after this change
- **THEN** no structural changes are present in those sections

### Requirement: The Agile Coach SHALL apply an intentional-vs-accidental judgment overlay

The `agents/agile-coach.md` definition SHALL document a judgment
overlay for Single-Concept Cohesion findings in its Key Knowledge
section, alongside the existing overlays for horizontal-work
legitimacy, scope-boundary norms, and DoD placement. The overlay MUST
state:

- **Intentional bundling is legitimate** when the bundled items must
  ship atomically to avoid a broken intermediate state (for example,
  a UI change that renders a new backend field together with the
  backend migration that adds the field). Splitting an intentional
  bundle would produce halves that individually fail vertical-slice
  or cause integration drift.
- **Accidental bundling is the failure mode** the cohesion check is
  designed to catch. The bundled items share a surface by
  coincidence rather than by delivery requirement.
- **The test:** the coach asks whether the atomicity of the delivery
  requires the items to be one story. When yes, the bundle is
  intentional and the FAIL is a false positive; the coach notes the
  intent in its response and declines to split. When no, the FAIL
  stands and the coach forwards the Suggested split block to the
  Product Owner for reauthoring.

The Agile Coach agent's How to Respond section MUST reference the
overlay explicitly so the coach applies it every time the skill
returns a Single-Concept Cohesion FAIL. The overlay MUST NOT replace
or override the skill's mechanical scoring; the overlay interprets
the skill's output rather than modifying the scoring rules.

#### Scenario: Intentional bundle is declared and the split is declined

- **WHEN** the skill returns a Single-Concept Cohesion FAIL on a
  story whose ACs require atomic delivery (UI change plus its
  backend migration)
- **THEN** the coach's response identifies the bundle as
  intentional, notes the atomicity requirement, and declines to
  forward the Suggested split block to the Product Owner

#### Scenario: Accidental bundle is forwarded as-is

- **WHEN** the skill returns a Single-Concept Cohesion FAIL on a
  story whose ACs share a surface by coincidence
- **THEN** the coach's response confirms the accidental bundling
  and forwards the Suggested split block to the Product Owner for
  reauthoring

#### Scenario: Overlay lives in Key Knowledge, not in the skill

- **WHEN** a reader inspects `skills/refine-story/SKILL.md`
- **THEN** the skill describes the six mechanical failure signals
  but does NOT describe intentional-vs-accidental judgment criteria;
  the judgment content lives only in `agents/agile-coach.md`

### Requirement: The Product Owner SHALL split and reauthor on a cohesion FAIL rather than merge

The `agents/product-owner.md` Requirement Authoring flow SHALL act on
a Single-Concept Cohesion FAIL by splitting the story and authoring
each child separately. The flow MUST:

1. Present the Suggested split block from the coach to the user,
   including each proposed child's role / capability / benefit and
   its AC subset.
2. Ask the user whether to accept the split, reject it as an
   intentional bundle, or revise the draft.
3. On user acceptance, invoke `/write-story` once per child story
   using the Suggested split block's role / capability / benefit and
   AC mapping as input for each invocation.
4. Run the existing Strategic triage step (consultation with
   `chief-architect` and `ux-strategist` when triggers match) on
   each child story independently, rather than on the combined
   original.

The flow MUST NOT produce a single merged story that "fixes" the
conflation by rephrasing both halves into one restated artifact. The
split step MUST be executed before the Product Owner moves on to
incorporate other coach feedback into the artifact.

#### Scenario: Accepted split produces two independently authored stories

- **WHEN** the coach returns a Single-Concept Cohesion FAIL with a
  two-child Suggested split block and the user accepts the split
- **THEN** the Product Owner invokes `/write-story` twice, once per
  child, and runs Strategic triage on each resulting story
  independently

#### Scenario: Rejected split records the intentional bundle

- **WHEN** the user rejects a Suggested split by declaring the
  bundle intentional
- **THEN** the Product Owner proceeds with a single story and
  records the atomicity rationale in the story's Technical Notes or
  Scope section so future reviewers see why the conflation signal
  was accepted

#### Scenario: The flow never merges halves into one restated story

- **WHEN** the Product Owner receives a Single-Concept Cohesion FAIL
- **THEN** the Product Owner does NOT produce a single story that
  incorporates both halves under a unifying rephrase; the only
  outcomes are split-and-reauthor or intentional-bundle acceptance

### Requirement: The cohesion check SHALL be additive to existing principles and NOT modify INVEST Independent

The Single-Concept Cohesion principle SHALL operate on intra-story
cohesion (does this story describe one change or several?) as a
separate axis from INVEST **Independent** (does this story wait on
another in-progress story?). Both checks MUST continue to run on every
story review; neither MUST be folded into the other. The wording,
failure signals, and scoring of INVEST **Independent** MUST remain
unchanged by this change.

The existing seven coaching principles' wording, failure signals, and
suggested-rewrite outputs MUST likewise remain unchanged. The cohesion
check MUST NOT renumber, rename, or re-scope any existing principle.

#### Scenario: INVEST Independent is unchanged

- **WHEN** a reader compares the INVEST Independent row in the
  skill's INVEST table before and after this change
- **THEN** the criterion's question and common-failure text are
  unchanged

#### Scenario: The seven existing coaching principles are unchanged

- **WHEN** a reader compares principles #1 through #7 in the skill
  before and after this change
- **THEN** no principle has been renumbered, renamed, or had its
  failure signals modified

#### Scenario: Both cohesion and Independent run on every review

- **WHEN** `/refine-story` scores any story draft
- **THEN** the report includes a verdict for INVEST **Independent**
  and a verdict for coaching principle #8 Single-Concept Cohesion,
  scored independently

### Requirement: The cohesion check SHALL NOT target epics or other authoring skills

The Single-Concept Cohesion principle SHALL apply to user stories
scored by `/refine-story` only. The principle MUST NOT be added to
`/write-epic`, `/write-bug`, `/write-spike`, or
`/decompose-requirement`. Epic decomposition is handled by
`/decompose-requirement`; bugs and spikes do not follow the role /
capability / benefit shape the principle evaluates.

The `/write-story` skill's structure and output MUST remain
unchanged by this change. The cohesion check takes effect through the
coach's inline consultation on the draft, which is already part of
the authoring flow; no changes to `/write-story` itself are required.

#### Scenario: Epics are not scored for cohesion

- **WHEN** `/write-epic` produces an epic draft
- **THEN** the epic's output does NOT include a Single-Concept
  Cohesion verdict; epic decomposition remains the responsibility
  of `/decompose-requirement`

#### Scenario: write-story is unchanged

- **WHEN** a reader compares `skills/write-story/SKILL.md` before
  and after this change
- **THEN** no structural or content changes are present; the
  cohesion check operates through the coach's inline review, which
  is already invoked by the existing authoring flow

#### Scenario: Bugs and spikes are not scored for cohesion

- **WHEN** `/write-bug` or `/write-spike` produces an artifact
- **THEN** the output does NOT include a Single-Concept Cohesion
  verdict, since those artifacts do not follow the user-story shape
  the principle evaluates

