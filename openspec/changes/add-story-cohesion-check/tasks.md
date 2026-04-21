# Tasks

## 1. Author the `story-cohesion-check` capability spec

- [x] 1.1 Create `openspec/specs/story-cohesion-check/spec.md` with the
      Purpose, Invariants, Acceptance Criteria, and Requirements sections
      following the existing capability-spec template
- [x] 1.2 Document the eighth coaching principle (Single-Concept Cohesion)
      and confirm the seven existing principles retain their numbering
      and rules
- [x] 1.3 Document the six failure signals with the two-signal quorum rule
      and the PASS/FAIL scoring shape consistent with the existing
      principles
- [x] 1.4 Document the Suggested split output block shape (per-child role /
      capability / benefit plus AC mapping) and the rule that no merged
      rewrite is produced
- [x] 1.5 Document the Summary line change from "Y of 7 coaching principles
      passing" to "Y of 8 coaching principles passing" and confirm no other
      output sections change
- [x] 1.6 Document the Agile Coach intentional-vs-accidental judgment
      overlay and confirm the overlay lives in the agent definition rather
      than in the skill
- [x] 1.7 Document the Product Owner split-and-reauthor flow: invoke
      `/write-story` per child, run Strategic triage on each child
      independently, and never produce a merged rewrite
- [x] 1.8 Document the scope boundary: the check applies to `/refine-story`
      on user stories only, not to epics, bugs, spikes, or
      `/decompose-requirement`, and `/write-story` is unchanged

## 2. Update the refine-story skill

- [ ] 2.1 Add a "Principle 8 — Single-Concept Cohesion" subsection to the
      Evaluate Coaching Principles section of `skills/refine-story/SKILL.md`
      with the six failure signals enumerated as bullets
- [ ] 2.2 Document the two-signal quorum rule: FAIL when two or more
      signals are observed; PASS with an optional note when exactly one
      signal is observed; PASS with a brief explanation when zero signals
      are observed
- [ ] 2.3 Add a Suggested split output block specification under the
      principle's description, showing the per-child role / capability /
      benefit format and AC mapping
- [ ] 2.4 Extend the Output section's principle enumeration to include
      principle #8 with the "Suggested split" action block shape (not a
      "Suggested rewrite")
- [ ] 2.5 Update the Summary line in the Output section from "Y of 7
      coaching principles passing" to "Y of 8 coaching principles passing"
- [ ] 2.6 Confirm that principles #1 through #7 are unchanged in
      wording, failure signals, and suggested-rewrite shapes
- [ ] 2.7 Confirm that the INVEST Scorecard, Definition of Done, and
      Horizontal Work sections are structurally unchanged

## 3. Update the agile-coach agent definition

- [ ] 3.1 Add an intentional-vs-accidental judgment overlay to the Key
      Knowledge section of `agents/agile-coach.md`, alongside the
      existing horizontal-work, scope-boundary, and DoD placement overlays
- [ ] 3.2 Document the atomicity test: ask whether the bundled items must
      ship together to avoid a broken intermediate state; when yes the
      bundle is intentional and the FAIL is a false positive
- [ ] 3.3 Document the downstream action for each case: accidental bundle
      forwards the Suggested split block to the Product Owner; intentional
      bundle notes the atomicity rationale and declines to split
- [ ] 3.4 Update the Story Review subsection of How to Respond so the
      coach explicitly applies the overlay each time `/refine-story`
      returns a Single-Concept Cohesion FAIL
- [ ] 3.5 Confirm the agent's Jurisdiction section is updated to include
      intra-story cohesion (Single-Concept Cohesion) as a distinct axis
      from INVEST Independent

## 4. Update the product-owner agent definition

- [ ] 4.1 Add a Single-Concept Cohesion acknowledgement step to the
      Requirement Authoring flow in `agents/product-owner.md`, inserted
      before the existing "incorporate the coach's feedback" step
- [ ] 4.2 Document the split-and-reauthor behavior: present the Suggested
      split block to the user, invoke `/write-story` per child on user
      acceptance, and run Strategic triage on each child story
      independently
- [ ] 4.3 Document the rejection path: on intentional-bundle rejection,
      record the atomicity rationale in the story's Technical Notes or
      Scope section and proceed with a single story
- [ ] 4.4 Document the anti-pattern: the Product Owner MUST NOT produce a
      single merged story that rewrites both halves under a unifying
      rephrase; the only outcomes are split-and-reauthor or
      intentional-bundle acceptance
- [ ] 4.5 Confirm the agent's Delegation section notes that post-coaching
      scope review handles cohesion findings the same way it handles
      other scope findings

## 5. Add a documentation example

- [ ] 5.1 Add an example to the plugin README, the `refine-story` skill,
      or the Agile Coach agent definition showing a conflated draft,
      the coach's Single-Concept Cohesion FAIL, and the Product Owner's
      split-and-reauthor action producing two `/write-story` invocations
- [ ] 5.2 The example MUST include the original conflated draft, the
      Suggested split block output, and both child stories as they would
      be authored independently
- [ ] 5.3 The example MUST show the intentional-bundle alternative (a
      case where the coach recognizes atomic delivery and declines to
      split) so readers can see both outcomes of the overlay

## 6. Validate back-compat and internal consistency

- [ ] 6.1 Confirm that `skills/write-story/SKILL.md` is not modified by
      this change
- [ ] 6.2 Confirm that `skills/write-epic/SKILL.md`,
      `skills/write-bug/SKILL.md`, `skills/write-spike/SKILL.md`, and
      `skills/decompose-requirement/SKILL.md` are not modified by this
      change
- [ ] 6.3 Confirm that the INVEST Scorecard and the seven existing
      coaching principles are unchanged in wording and failure signals
- [ ] 6.4 Confirm that the Agile Coach's existing overlays (horizontal-
      work legitimacy, scope-boundary norms, DoD placement) are unchanged
      and the new cohesion overlay is additive
- [ ] 6.5 Confirm that the Product Owner's existing Requirement Authoring
      flow steps (write-spike routing, write-bug routing, inline coach
      review, Strategic triage) remain in place and the cohesion step is
      additive

## 7. Manual verification

- [ ] 7.1 Invoke `/refine-story` with a conflated draft (two unrelated
      fields on one modal, different risk profiles, different priorities
      if split) and confirm Single-Concept Cohesion returns FAIL with a
      Suggested split block naming two children
- [ ] 7.2 Invoke `/refine-story` with a single-concept draft (one
      capability, multiple ACs all serving the same user outcome) and
      confirm Single-Concept Cohesion returns PASS
- [ ] 7.3 Invoke `/refine-story` with a draft that has different AC risk
      profiles but shares a user outcome (one signal only) and confirm
      Single-Concept Cohesion returns PASS with an optional note
- [ ] 7.4 Consult the Agile Coach with a draft that passes the
      atomicity test (UI plus backend migration that must ship
      together) and confirm the coach identifies the bundle as
      intentional, notes the rationale, and declines to split
- [ ] 7.5 Consult the Agile Coach inline during `/write-story` with a
      conflated draft and confirm the Product Owner receives the
      Suggested split block, presents it to the user, and invokes
      `/write-story` per child on acceptance
- [ ] 7.6 Consult the Product Owner with a user rejection of the split
      and confirm the PO records the atomicity rationale in the story
      rather than producing two children or merging the halves into a
      rewritten single story
- [ ] 7.7 Confirm the `/refine-story` Summary line reads "X of 6 INVEST
      criteria passing. Y of 8 coaching principles passing." on any
      review
