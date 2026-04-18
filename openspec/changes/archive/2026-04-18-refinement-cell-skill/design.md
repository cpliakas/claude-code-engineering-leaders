# Design: Refinement Cell Skill

## Context

The plugin already ships three agents that together form the "refinement
cell":

- `product-owner` — scope, business value, roadmap fit
- `chief-architect` — one-way doors, cross-cutting impact, forward
  compatibility
- `ux-strategist` — persona fit, behavioral consistency, user-observable
  outcomes

The plugin also ships `/plan-implementation`, which orchestrates a two-phase
consultation with the Tech Lead and specialists. That skill is the strongest
existing template for what this change needs: a parallel fan-out to multiple
agents with verbatim preservation of their responses, followed by a synthesis
step.

`/refinement-review` is a simpler fan-out than `/plan-implementation`:

- The peer set is fixed (PO, Architect, UX) rather than routed dynamically, so
  no routing table lookup is required.
- There is no second synthesis pass through another agent; the skill itself
  assembles the consolidated report from the three peer responses.
- The output is a readiness verdict for a story draft, not an implementation
  plan.

The existing `refine-story` skill scores INVEST and seven coaching principles.
It is a structural check on the story's own text. `/refinement-review` is a
complementary perspective check: even a perfectly INVEST-compliant story can
be the wrong thing to build, a one-way door the team should not walk through,
or a feature that creates behavioral inconsistency. The two skills are
composable and users can run either or both.

## Goals / Non-Goals

**Goals:**

- Make the refinement cell a concrete ceremony rather than a convention.
- Preserve each peer's input verbatim so the user sees the peer's actual
  voice, not the skill's summary.
- Produce an explicit readiness verdict with named accountable peers for any
  non-ready state.
- Handle graceful degradation when a peer has no concerns or errors out.
- Reuse the input-resolution conventions established by `/plan-implementation`
  (inline, file path, issue reference) so the input contract is familiar.
- Keep the three peer agents unmodified in substance; the only agent-file
  changes are minor description additions that document membership.

**Non-Goals:**

- Automatic triggering from other skills or events. Users invoke it
  explicitly.
- Forcing consensus among the peers. When peers disagree, the report presents
  the disagreement; the user decides how to resolve it.
- Extending the same pattern to other triads (infrastructure triad, quality
  triad, etc.) as part of this change. That can follow as separate work once
  this pattern is proven.
- Replacing `/write-story` or the existing `refine-story` INVEST scorer.
- A "minimal mode" that skips peers based on signals in the story text. The
  issue flags token cost as a potential concern, but building selective
  skipping before we have usage data risks skipping the peer whose perspective
  most challenges the story — the exact failure mode this skill exists to
  prevent. Deferred as a possible follow-up once usage patterns are visible.

## Decisions

### D1. Fixed peer set rather than routed

The peer set is hard-coded to `product-owner`, `chief-architect`,
`ux-strategist`. The skill does not consult the Tech Lead's routing table and
does not accept a configurable peer list.

**Rationale:** The value of the ceremony comes from the fact that the three
perspectives are always on record. Making the set configurable invites exactly
the skipping behavior the skill exists to prevent. If a project later decides
the set should be different, that is a plugin-level design change to be made
deliberately, not a per-invocation toggle.

**Alternatives considered:** Route peers dynamically via the Tech Lead's
routing table. Rejected: the refinement cell is a design-time commitment, not
a content-dependent routing decision. Allowing stories to route around UX is
the failure mode.

### D2. Parallel fan-out with verbatim preservation

The three peers are invoked in a single parallel batch using the Agent tool.
Each response is captured verbatim and included in the final report under a
per-peer section.

**Rationale:** Matches the pattern used by `/plan-implementation` and the
Tech Lead's verbatim-quote convention. Preserving the peer's own voice keeps
accountability clear (the peer said X, not the skill's paraphrase of X) and
avoids lossy summarization. Parallel invocation minimizes wall-clock cost.

**Alternatives considered:** Sequential invocation where each peer sees the
previous peers' responses. Rejected: it biases later peers toward the earlier
ones' framing, collapsing the independent-perspectives value. Verbatim
inclusion also rules out summarizing peer output into a single combined
voice.

### D3. Role-specific prompts, shared context

Each peer receives the same story draft but a role-specific prompt that asks
them to focus on their slice of refinement concerns. The prompts are embedded
in the skill file so they are version-controlled and reviewable.

**Rationale:** Shared context ensures the peers are reviewing the same
artifact; role-specific prompts keep each response scoped and prevent the
peers from redundantly covering the same ground. The prompts are short and
should not re-explain the agent's full jurisdiction; the agents already
know their own job.

**Alternatives considered:** A single shared prompt asking all three for
"refinement feedback". Rejected: produces overlapping, unfocused responses
and loses the role-specific signal that justifies running three agents in the
first place.

### D4. Skill-side synthesis rather than a fourth agent

After collecting the three peer responses, the skill itself assembles the
consolidated report (verdict + verbatim peer sections + objections callout).
It does not invoke a fourth agent to synthesize.

**Rationale:** The "synthesis" here is mechanical: collect verdicts, surface
disagreements, compute the overall readiness. A further LLM pass would risk
re-summarizing the verbatim input the skill just committed to preserving. The
Tech Lead's Phase 2 synthesis in `/plan-implementation` serves a different
purpose: it produces an implementation plan, not a readiness verdict.

**Alternatives considered:** Invoke the Product Owner a second time to
produce the consolidated verdict. Rejected: privileges one peer's view over
the others and contradicts the peer-refinement-cell framing.

### D5. Readiness verdict vocabulary: `ready` / `needs-revision` / `blocked`

The final report carries one of three verdicts:

- `ready`: all three peers sign off with no substantive objections.
- `needs-revision`: at least one peer raised a concern the author can
  address; the story can re-enter refinement after revision.
- `blocked`: at least one peer raised a structural concern (one-way door
  warning, wrong-persona, strategy mismatch) that cannot be resolved by
  revising the story text alone and warrants a higher-level decision before
  proceeding.

The report names the peer(s) responsible for any `needs-revision` or
`blocked` classification.

**Rationale:** Three-level is enough to distinguish "tweak the wording" from
"re-examine the idea" without forcing false precision. Matching vocabulary to
the plugin's existing Chief Architect one-way-door framing keeps the
semantics consistent.

**Alternatives considered:** Binary pass/fail. Rejected: collapses the
actionable "revise the text" case with the structural "re-examine the idea"
case.

### D6. Input contract mirrors `/plan-implementation`

`$ARGUMENTS` accepts inline story body, file path, or issue reference. The
resolution logic is copied from `/plan-implementation`: file paths are read;
issue references are resolved via `bd show` then `gh issue view`; inline
content is used verbatim.

**Rationale:** Users already know how to invoke `/plan-implementation`.
Establishing a second input convention would be friction for no gain.

**Alternatives considered:** Accept only a file path, forcing the user to
draft the story in a file first. Rejected: it raises the cost of running a
quick refinement pass on a draft the user has in-memory or in an issue
tracker.

### D7. Graceful "no concerns" handling

When a peer response indicates no substantive concerns (either the agent
explicitly says so, or the response is empty/whitespace after invocation), the
report renders that peer's section with a short "no concerns raised" line
rather than omitting the section entirely.

**Rationale:** Silent omission would be ambiguous: did the peer have no
concerns, or did the invocation fail? Explicit "no concerns" vs. "peer
invocation failed, input absent" preserves the signal.

**Alternatives considered:** Drop the section entirely. Rejected for
ambiguity reasons above.

### D8. No agent-description schema changes; minor body additions only

The three peer agent files get a short addition under a "Collaboration"
subsection (or equivalent existing body section) noting membership in the
refinement cell and pointing at `/refinement-review`. No frontmatter fields,
memory schema, or jurisdiction are changed.

**Rationale:** Minimum-viable change to surface the skill from within the
agents without reshaping them. The skill itself carries the mechanics.

**Alternatives considered:** Adding a new `refinement_cell: true` frontmatter
flag. Rejected as over-engineering for a fixed three-agent set.

## Risks / Trade-offs

- **Token cost.** Three parallel agent invocations per run, each with the
  full story draft as context. For a trivial story this is clearly more
  expensive than a single-peer consultation. **Mitigation:** Document in the
  skill's description and the README that trivial stories may legitimately
  skip the ceremony. Revisit a "minimal mode" (D2 / Non-Goals) once usage data
  suggests the cost is meaningful in practice.

- **Peer disagreement without a clear resolution path.** The skill
  deliberately does not force consensus. Users may be left with three
  conflicting recommendations and no script for resolving them.
  **Mitigation:** The report includes an explicit `## Objections` section
  that surfaces disagreements in one place, and the readiness verdict names
  the peer responsible. The user decides. Documented in the skill output
  format.

- **Role-specific prompts drifting from agent jurisdiction over time.** If
  the agent definitions evolve (e.g., the UX Strategist absorbs a new
  concern), the hard-coded prompts in the skill can become stale.
  **Mitigation:** The prompts are intentionally short and frame-oriented
  ("review this story from your perspective on persona fit and behavioral
  consistency") rather than enumerating every concern. They should survive
  minor agent evolution. A review of the prompts alongside any major agent
  jurisdiction change is a reasonable convention.

- **Interaction with `refine-story` (INVEST scorer).** Users may conflate
  the two skills or assume one subsumes the other. **Mitigation:** README
  section explicitly contrasts them: `refine-story` checks the story's own
  structure; `/refinement-review` checks whether the story should be built
  at all. The two are composable.

- **Graceful degradation under partial peer failure.** If one peer errors
  out, the other two's verdicts are still produced, but the overall
  readiness verdict is necessarily incomplete. **Mitigation:** The report
  marks the failed peer with an explicit "invocation failed" line and
  downgrades the overall verdict to `needs-revision` (at minimum) with the
  missing peer named. Users can re-run the skill or consult the missing peer
  manually.

## Migration Plan

No migration required; the skill is additive. Rollback is removal of the
skill directory and the minor agent description additions.

## Open Questions

- Should the skill optionally write the consolidated report to a file
  alongside the story draft (e.g., `story.refinement.md`) for persistence?
  Deferred until users request it; initially the report is returned to the
  conversation only.
- Should the Agile Coach be invoked as a fourth peer to provide
  INVEST-structural coverage within the same ceremony? Deferred: the
  `refine-story` skill already covers that ground and composes cleanly with
  this one. Folding it in would blur the peer-refinement-cell framing with
  structural review.
