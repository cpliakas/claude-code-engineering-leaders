# Change Proposal: Tech Lead Orchestration Tiers

## Why

The Tech Lead's current Rule 4 ("Specialist matches require consultation
requests — no exceptions") is correct for cross-cutting, multi-domain, or
architectural-ambiguity work where a missed specialist perspective is
expensive. Applied uniformly, however, it turns trivial single-domain stories
into consulting theater: a five-line bug fix inside a well-understood module
runs the full two-phase protocol and emerges with multi-specialist synthesis
when one specialist, or none, would have sufficed.

There is no documented lightweight path and no documented escalation signal
back to the Chief Architect for the opposite case. Users learn by trial and
error when to invoke the Tech Lead versus when to bypass it, and the plugin's
public voice (README, agent descriptions) does not help them tier the
engagement. The result is either over-orchestration on small work or
mid-implementation surprises when a one-way door was missed during refinement.

## What Changes

- Introduce three named orchestration tiers — **Direct specialist**,
  **Tech Lead Standard**, and **Tech Lead Full (with Architect escalation)** —
  as documented guidance for both human users and the `/plan-implementation`
  skill.
- Document each tier in the top-level `README.md` with concrete signals for
  selecting it and examples of the kind of work that belongs in each tier.
- Document a **signals catalog**: story attributes that push a decision to a
  given tier (touched-file count bands, domain count, one-way-door vocabulary,
  new-pattern vocabulary, schema/API commitment vocabulary, unfamiliar-area
  heuristic). The catalog includes an explicit "if in doubt, escalate" rule so
  users do not default to tier 1 simply to avoid overhead.
- Update the Tech Lead agent definition (`agents/tech-lead.md`) so that:
  - Rule 4 is scoped to tiers 2 and 3. A new preamble in the Implementation
    Planning response mode instructs the Tech Lead to identify the operating
    tier first and makes clear that tier 1 work should not have reached the
    Tech Lead in the first place; if it did, the Tech Lead names the
    most relevant specialist and exits without running the full routing pass.
  - The Phase 1 structured output gains an `## Engagement Tier` line (in
    addition to the existing `## Engagement Depth` line) so tier is machine
    readable. The existing Engagement Depth line is retained for continuity.
  - The Phase 2 synthesis explicitly flags tier 3 work that surfaces a
    one-way-door signal as an Architect escalation **before** implementation
    starts, cross-referencing the Chief Architect's description triggers so
    the escalation is concrete and actionable.
- Document the tier-to-signal mapping in one place (the new signals catalog
  section in the README) and reference it from the Tech Lead's definition so
  the two stay aligned.

## Capabilities

### New Capabilities

- `tech-lead-orchestration-tiers`: documented three-tier engagement model for
  Tech Lead consultation, with a signals catalog, README guidance, and a
  machine-readable `## Engagement Tier` line in the Tech Lead's Phase 1 output
  contract.

### Modified Capabilities

<!-- The `tech-lead-routing` capability gains a tier-aware interpretation of
the "no exceptions" rule and an explicit Architect-escalation path. No other
existing capability's requirements change. -->

## Impact

- **Users:** A clearer mental model for when to invoke the Tech Lead vs bypass
  it vs escalate to the Chief Architect. Trivial single-domain work stops
  running through the full two-phase protocol by default.
- **Tech Lead agent:** Rule 4 is tier-scoped rather than absolute. Phase 1
  output carries an explicit tier marker. Phase 2 synthesis names Architect
  escalations before implementation rather than mid-implementation.
- **Chief Architect agent:** No definition change. Tier 3 Architect
  escalation from the Tech Lead piggybacks on the Architect's existing
  description triggers (one-way door, cross-cutting, schema/API commitment).
- **`/plan-implementation` skill:** No behavior change in this proposal. The
  skill can later parse the new `## Engagement Tier` line for tier-aware
  behavior (e.g., short-circuit on tier 1). That automation is out of scope
  here; this change delivers the documented model and the parseable marker.
- **`/refinement-review` skill:** No change. Refinement-cell and orchestration
  tiers are independent concerns.
- **Token cost:** Tier 1 bypasses explicit Tech Lead orchestration entirely,
  reducing token spend on trivial work. Tiers 2 and 3 preserve existing
  behavior.
- **Existing projects:** No migration required. Guidance is additive. Existing
  Phase 1 output parsers that rely on `## Engagement Depth` continue to work
  because that line is retained alongside the new `## Engagement Tier` line.
- **Non-goals:** Automatic tier detection in code, new agents, new response
  modes, or changes to the Chief Architect's own definition. Tiers are
  guidance, not gates — the user or skill may override tier selection at any
  time.
