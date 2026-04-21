# Change Proposal: Routing Outcome Capture

## Why

The Tech Lead's routing table encodes which specialists to consult for a
given story. When a specialist is consulted and replies that they have no
relevant input, that signal is informational: the specialist's trigger
conditions overmatched the story. Today that signal is not captured
anywhere. Nothing updates the routing table, and nothing surfaces that,
over the last N plans, a particular specialist was consulted five times
and added no value three of those times.

Over time the routing table's trigger conditions drift toward over-broad
coverage because there is no pressure to narrow them. Plans pay for
specialist consultations that rarely contribute, and users learn to expect
consulting-theater from certain specialists in certain areas, eroding
trust in the Tech Lead's routing judgment.

## What Changes

- Extend the Tech Lead's Phase 2 synthesis output contract so each
  `### <Specialist Name>` subsection under `## Specialist Consultations`
  carries a parseable `**Routing Value:**` line with the fixed vocabulary
  `high`, `medium`, `low`, or `none`. Existing Phase 2 anchors
  (`## Engagement Depth`, `## Specialist Consultations`,
  `## Escalation Flags`, `## Implementation Constraints`,
  `## Recommended Approach`) are unchanged.
- Document a written rubric that defines what each value means, anchored
  on whether the specialist's response shifted the plan (high), added
  concrete constraints or trade-offs the plan incorporated (medium),
  merely confirmed existing direction without changing it (low), or
  explicitly disclaimed relevance (none). The rubric is the convention
  that keeps grading consistent across Tech Lead runs.
- Add a new Tech Lead project-memory section
  `## Routing Outcomes` documented in the `tech-lead-routing` spec. The
  section is an append-only markdown table with columns
  `Date | Story Slug | Specialist | Value | Note`. Entries are appended
  by the Tech Lead (or a wrapping skill) after each Phase 2 synthesis.
- Extend `/plan-implementation` so that after Phase 2 synthesis
  completes, the skill parses the per-specialist `**Routing Value:**`
  lines and appends one row per specialist to the `## Routing Outcomes`
  table in the Tech Lead's memory file. Parse failures are surfaced as a
  notice; they do not halt the plan.
- Add a new user-invokable skill `/audit-routing-quality` that reads the
  `## Routing Outcomes` table, aggregates per-specialist signal over the
  recorded history, and recommends routing-table narrowing actions
  (tighten description trigger vocabulary, remove redundant Code Area
  Overrides, consider deregistering a specialist). The skill is
  advisory: it never edits the routing table itself.
- Document a lightweight retention policy: when the
  `## Routing Outcomes` table exceeds 200 rows, the user-invokable
  `/audit-routing-quality` skill offers to summarize older rows into a
  roll-up row and drop the originals. Roll-up is user-confirmed.

## Capabilities

### New Capabilities

- `routing-outcome-capture`: the mechanism by which the Tech Lead
  records per-specialist routing value during Phase 2 synthesis, the
  schema of the `## Routing Outcomes` memory section, and the grading
  rubric that defines what each value means.
- `audit-routing-quality-skill`: a user-invokable skill that reads the
  aggregated `## Routing Outcomes` table and produces routing-quality
  findings with recommended narrowing actions, plus the optional
  retention roll-up.

### Modified Capabilities

- `tech-lead-routing`: the routing memory file gains a
  `## Routing Outcomes` section, and the spec adds invariants covering
  append-only semantics, the roll-up boundary, and the relationship
  between outcome data and the existing `## Registered Specialists` and
  `## Project Code Area Overrides` sections.
- `plan-implementation-skill`: the skill adds a post-Phase-2
  outcome-recording step that parses the new `**Routing Value:**` lines
  and appends rows to the Tech Lead's memory. On parse failure the skill
  surfaces a notice in its output but still returns the Phase 2
  synthesis to the caller.

## Impact

- **Users:** Gain visibility into which specialists consistently have no
  input for the kinds of stories being planned. Can tighten routing-table
  entries based on data rather than intuition.
- **Tech Lead agent:** Phase 2 synthesis output contract extends with a
  per-specialist `**Routing Value:**` line; the rubric is consulted at
  synthesis time.
- **Tech Lead project memory:** Gains a new `## Routing Outcomes`
  section. The new section is append-only during plans and rolled up
  only via the user-invokable audit skill.
- **`/plan-implementation` skill:** Adds one post-synthesis step
  (parse and append). On failure the skill returns the Phase 2 output
  and surfaces a notice; it never blocks or discards the plan.
- **`/audit-routing-table` skill:** Out of scope; the existing audit
  skill continues to cover the four hygiene checks it already owns
  (orphan overrides, broken pointers, redundant overrides, thin
  descriptions). `/audit-routing-quality` is a separate skill with a
  different input (outcome history) and a different recommendation set
  (narrowing based on value data).
- **Token cost:** One extra line per specialist in Phase 2 output and
  one parse-and-append step in `/plan-implementation`. Negligible.
- **Existing projects:** The new `## Routing Outcomes` section is
  missing initially; the Tech Lead, `/plan-implementation`, and
  `/audit-routing-quality` all handle the missing section gracefully by
  creating it on first append or reporting an empty-history notice.
- **Risks:** Value grading is subjective; early data will be noisy. The
  rubric and the "if in doubt, grade down" convention counterweight
  this. Memory file growth is bounded by the roll-up policy.
- **Non-goals:** Automated routing-table edits, cross-project
  aggregation, specialist-quality assessment (this is about routing fit,
  not specialist output quality), and any telemetry infrastructure
  beyond append-only markdown.
