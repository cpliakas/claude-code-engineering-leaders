# Change Proposal: Add Story Cohesion Check

## Why

`skills/refine-story/SKILL.md` currently scores six INVEST dimensions and seven
coaching principles. Between them, none of the checks detects a story that
secretly bundles two or more discrete changes stapled together into one
artifact. INVEST's **Independent** criterion scores inter-story coupling ("is
this story waiting on another in-progress story?"), not intra-story cohesion.
**Small** uses acceptance-criteria count as a heuristic; a two-criterion story
can still be two stories in disguise. **Scope Boundaries Explicit** checks
whether exclusions are *stated*, not whether the included items should be split
apart. **Each AC Independently Testable** passes as long as each criterion is
individually verifiable, even when the criteria describe entirely unrelated
features that happen to share a template file.

The result is a real write-time gap. A recent story on an adjacent project
passed INVEST and all seven coaching principles, entered the backlog at P3, and
was only split into two stories after a priority-review conversation raised the
"feels like these are two issues" smell. The bundled story added two unrelated
fields to the same UI modal: one a low-risk parity fix for an existing backend
field; one a net-new product capability (DAG semantics) that the project does
not even use yet. The two halves had materially different risk profiles,
different priorities if filed separately, and no shared user outcome. The
rubric missed it because no existing principle evaluates whether the story
describes one change or several.

The goal of this change is to move that judgment upstream into the authoring
flow so the Product Owner and Agile Coach catch bundled-story conflation the
first time, rather than relying on post-hoc priority review to recover.

## What Changes

- Add an eighth coaching principle, **Single-Concept Cohesion**, to
  `skills/refine-story/SKILL.md`. The principle evaluates whether the story
  describes one change or several bundled changes and produces a PASS or FAIL
  verdict.
- Document the failure signals the principle detects (ACs spanning unrelated
  capabilities, mixed risk profiles within one story, ACs that would naturally
  carry different priorities if filed separately, scope statements that
  connect items with "and" where the items do not share a user outcome, and
  the independence test: could each half ship independently with value?).
- Add a **Suggested split** output block for FAIL cases. The block proposes
  two or more distinct stories, each with its own role / capability / benefit
  statement and its own narrowed AC set, derived from the conflated draft.
  The block proposes a split; it does not rewrite the original story as a
  merged artifact.
- Extend the `refine-story` output format so the Coaching Principles section
  lists eight principles instead of seven and the Summary counts "X of 8
  coaching principles passing."
- Update `agents/agile-coach.md` with the intentional-vs-accidental judgment
  overlay: some bundled stories are intentional (tightly coupled UI and
  backend that must ship atomically) and others are accidental (two features
  sharing a template file by coincidence). The agent documents when to flag
  and when to accept.
- Update `agents/product-owner.md` Requirement Authoring flow so the PO acts
  on a conflation finding by offering to split and author each resulting
  story separately via `/write-story`, rather than incorporating a "fix" back
  into a single story.
- Add at least one example in the plugin documentation showing a conflated
  draft flowing through the coach, triggering the split suggestion, and being
  authored as two separate stories.

## Capabilities

### New Capabilities

- `story-cohesion-check`: the write-time single-concept cohesion check layered
  on top of the existing INVEST and seven-principle rubric. Covers the eighth
  coaching principle, its failure signals, the Suggested split output block,
  the intentional-vs-accidental judgment overlay on the Agile Coach, the
  Product Owner's split-and-reauthor flow, and the extension to the
  `refine-story` output format.

### Modified Capabilities

None. No existing capability spec covers the `refine-story` rubric or the
Agile Coach's coaching principles. This change adds a new capability rather
than modifying an existing one.

## Impact

- **Users authoring stories via `/write-story` or `/refine-story`:** Get a
  write-time cohesion check that flags conflated drafts before they enter
  the backlog. The `refine-story` report now includes an eighth principle
  and, on FAIL, a Suggested split block proposing two or more distinct
  stories. Users can accept the split, reject it (intentional bundle), or
  revise the draft and re-run.
- **Agile Coach agent:** Gains the intentional-vs-accidental judgment overlay.
  The agent definition documents when a bundled story is legitimate (tightly
  coupled change that must ship atomically) and when it is accidental (two
  unrelated capabilities sharing a surface by coincidence). The coach
  continues to use `/refine-story` as the single-pass scoring tool; the
  judgment overlay applies when the skill raises the new flag.
- **Product Owner agent:** Gains a split-and-reauthor step in the Requirement
  Authoring flow. When the coach flags a story as conflated, the PO offers
  to split the story and author each child separately via `/write-story`.
  The PO does not silently incorporate a "fix" that merges both halves back
  into one story. The PO's Strategic triage step runs on each resulting
  child story, not on the combined original.
- **`refine-story` output format:** Extended so the Coaching Principles
  section lists eight numbered principles and the Summary line counts "X of
  8 coaching principles passing." The existing seven principles keep their
  current numbering; the new principle is added as principle #8.
- **Scope of the check:** Applies at write-time, not backlog grooming. The
  check runs when `/refine-story` is invoked (standalone or inline during
  `/write-story` via the Agile Coach consultation). The check does not
  retroactively evaluate already-filed stories in the tracker and does not
  auto-split without user confirmation.
- **Relationship to existing principles:** Additive, not replacement. INVEST
  **Independent** remains the inter-story dependency check; **Single-Concept
  Cohesion** is the new intra-story cohesion check. The two checks operate
  on different axes and both continue to run.
- **Relationship to `/decompose-requirement`:** The decompose skill already
  handles multi-item breakdown for epics and large requirements. The
  cohesion check is for stories that should have been two stories from the
  start, not for epics that always needed decomposition. The two skills
  remain distinct.
- **Token cost:** Minor. The `refine-story` skill gains a new principle
  section and an optional Suggested split output block. The Agile Coach and
  Product Owner agent definitions each gain a short subsection. No skill
  invocation path changes.
- **Backward compatibility:** The existing seven principles keep their
  numbering and their rules. A story that passes all seven today will still
  pass those seven after this change; it may newly fail on principle #8 if
  it genuinely conflates multiple concepts. The output format gains one
  row; consumers that parse the report by section header continue to work.
- **Non-goals (explicit):** Retroactive review of filed stories, automated
  splitting without user confirmation, replacing INVEST **Independent**,
  auto-detecting conflation in epics (out of scope: decompose-requirement
  already covers that), and changing the `/write-story` skill's output
  shape (this change only modifies `/refine-story` and the two agent
  definitions).
