# Change Proposal: Operationalize the Refinement Cell

## Why

The plugin's design positions the Product Owner, Chief Architect, and UX
Strategist as peers at the refinement layer. In practice there is no ceremony
that convenes them: users have to invoke each agent separately, and the one
whose perspective most challenges the current direction is the one most likely
to get skipped. The peer refinement cell exists on paper but is not
operationalized in the tool surface, so one-way-door and persona-fit concerns
surface mid-implementation rather than before it.

## What Changes

- Add a new user-invokable skill, `/refinement-review`, that takes a story
  draft and convenes the Product Owner, Chief Architect, and UX Strategist in
  parallel on a shared context.
- Each peer is invoked with a role-specific prompt focused on their slice of
  refinement concerns (PO on scope and business value, Architect on one-way
  doors and cross-cutting impact, UX on persona fit and behavioral
  consistency). Peer outputs are preserved verbatim in the final report.
- The skill produces a consolidated refinement report with a readiness verdict
  (`ready` / `needs-revision` / `blocked`) that names which peer(s) drove any
  non-ready state and includes an explicit objections section when peers
  disagree.
- Accept three input forms consistent with `/plan-implementation`: inline
  story body, file path, or issue tracker reference (resolved via configured
  CLI such as `bd show` or `gh issue view`).
- Handle the case where a peer has no substantive input for a given story
  (e.g., infrastructure-only story with no UX concerns) by surfacing a
  "no concerns from this peer" line rather than forcing artificial content.
- Update the Product Owner, Chief Architect, and UX Strategist agent
  definitions to document that they are members of the refinement cell and
  reference the new skill.
- Update the top-level `README.md` to document when to use `/refinement-review`
  and how it relates to `/write-story`, the existing `refine-story` INVEST
  scorer, and `/plan-implementation`.

## Capabilities

### New Capabilities

- `refinement-review-skill`: a parallel-consultation ceremony that convenes the
  PO, Architect, and UX Strategist on a story draft and produces a consolidated
  report with a readiness verdict and verbatim peer input.

### Modified Capabilities

<!-- No existing capability's requirements change. The three agents are
reused via their existing prompt surface; the `refine-story` INVEST scorer is
unchanged and continues to serve its distinct purpose. -->

## Impact

- **Users:** A single command to drive a three-peer refinement pass before
  implementation. Reduces the "forgot to ask UX" failure mode.
- **Product Owner, Chief Architect, UX Strategist agents:** Minor description
  additions documenting refinement-cell membership. No schema or memory
  changes.
- **`/write-story`:** No change. `/refinement-review` is a review pass on an
  existing draft, not a replacement for authoring.
- **`refine-story` skill (INVEST scorer):** No change. Complementary tool;
  INVEST-level structural review continues to be its own thing.
- **`/plan-implementation`:** No change. `/refinement-review` runs before
  implementation planning, not instead of it.
- **Token cost:** Running three peers in parallel is meaningfully more
  expensive than a single-agent invocation. Documented trade-off; users who
  want a cheaper pass can still invoke agents individually.
- **Existing projects:** No migration required. The skill is additive.
