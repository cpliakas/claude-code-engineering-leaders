# Design: Routing Outcome Capture

## Context

The Tech Lead's specialist routing is governed by `openspec/specs/tech-lead-routing/spec.md`.
Registered specialists live under the `## Registered Specialists` section in
the Tech Lead's memory file; project-local code-area signals live under
`## Project Code Area Overrides`. Descriptions on the specialist agents
themselves are the source of truth for trigger vocabulary.

Every invocation through `/plan-implementation` runs the Tech Lead's
two-phase protocol: Phase 1 emits consultation requests, the skill fans
out to specialists, and Phase 2 synthesizes a single plan. The Phase 2
output already contains a `## Specialist Consultations` section with
one level-3 subsection per specialist, each capturing the specialist's
verbatim response.

What the system does not capture today is whether the specialist's
response was useful. When a specialist answers "no input relevant to
this story," that is a signal that the trigger conditions overmatched;
when a specialist's response adds a constraint the plan uses, that is
a signal that the trigger conditions fit. Both signals are ephemeral:
they appear in the Phase 2 output, the user reads the plan, and the
signals are not recorded anywhere. Over many plans, there is no
pressure on the routing table to narrow its triggers, so it drifts
toward over-broad coverage.

The existing `/audit-routing-table` skill handles four hygiene checks
(orphan overrides, broken pointers, redundant overrides, thin
descriptions). None of those checks consume outcome history; they are
structural checks against the memory file and the agent files. A
separate audit skill is needed to consume outcome data, because the
input and the recommendations are different: outcome-based audits
recommend tightening description vocabulary and narrowing overrides,
while structural audits recommend fixing broken pointers and orphan
rows.

The goal here is a lightweight mechanism: one extra line per
specialist in Phase 2 output, one append per plan to the Tech Lead's
memory, and a new advisory skill. No telemetry infrastructure, no
datastore, no cross-project aggregation.

## Goals / Non-Goals

**Goals:**

- Capture a coarse value signal per specialist per plan (`high`,
  `medium`, `low`, `none`) in a parseable location in Phase 2 output.
- Persist the signal in append-only markdown inside the Tech Lead's
  project memory so it survives across plans and sessions.
- Provide a user-invokable skill that reads the aggregated history and
  recommends routing-table narrowing actions.
- Keep overhead negligible: one extra line per specialist in Phase 2,
  one parse-and-append step in `/plan-implementation`, no new agents,
  no datastore.
- Document a grading rubric that defines what each value means so the
  signal is reasonably consistent across Tech Lead runs.
- Document a retention policy that prevents the outcomes file from
  growing unbounded, using user-confirmed roll-up rather than automatic
  truncation.

**Non-Goals:**

- Automated routing-table edits. The audit skill is advisory only; all
  edits remain user actions.
- Cross-project aggregation. Outcomes live in the Tech Lead's
  project-local memory; there is no global rollup.
- Specialist-quality assessment. The signal is about routing fit
  (did the trigger conditions overmatch?), not specialist output
  quality (was the specialist's response good?).
- Telemetry infrastructure. The mechanism is append-only markdown,
  not a datastore, queryable log, or structured event stream.
- Gating plans on outcome capture. Parse failures during the append
  step surface a notice but do not block the plan or discard the
  Phase 2 synthesis.
- Rewriting the existing `/audit-routing-table` skill. Structural
  hygiene and outcome-based narrowing are separate concerns with
  different inputs and different recommendations.

## Decisions

### D1. Four-value grading vocabulary

The per-specialist outcome values are the fixed vocabulary
`high`, `medium`, `low`, `none`. The semantics are:

- `high`: the specialist's response materially shifted the plan
  (named a trade-off the synthesis adopted, contradicted a default
  the Tech Lead would have chosen, or unblocked a specific design
  decision).
- `medium`: the specialist's response added concrete constraints or
  trade-offs the plan incorporated, without shifting overall
  direction.
- `low`: the specialist's response confirmed existing direction or
  added context but did not change the plan's substance.
- `none`: the specialist explicitly disclaimed relevance, returned
  an empty response, or returned content that did not apply to the
  story at all.

**Rationale:** Four values are the minimum that distinguish "shifted
the plan" from "confirmed the plan" from "did not apply." Three
values would conflate `low` and `medium`, obscuring the useful
signal that a specialist added concrete constraints even when the
overall direction held. Five or more values invite false precision;
the rubric would not keep up.

**Alternatives considered:** Boolean `added_value: yes | no`.
Rejected: it hides the gradient between "confirmed" and "shifted,"
which is where the narrowing signal actually lives. Numeric score
0 to 10. Rejected: requires a rubric per integer and produces the
same overall ordering as the four-value model with more grading
overhead.

### D2. Signal lives in the Phase 2 output, not Phase 1

The `**Routing Value:**` line is emitted by the Tech Lead during
Phase 2 synthesis, inside each `### <Specialist Name>` subsection
under `## Specialist Consultations`. It is not emitted in Phase 1
because Phase 1 runs before the specialist has responded; the
value cannot be graded until the synthesis step has read the
specialist's response.

**Rationale:** Grading at Phase 2 is where the Tech Lead already
has the specialist response in context and is already writing
synthesis text per specialist. Adding a one-line annotation is
near-zero marginal work. Grading at Phase 1 would require the
caller or a post-Phase-2 step to revisit the decision, and the
Tech Lead would not be the grader, which is worse for consistency.

**Alternatives considered:** Grade in a post-synthesis side-pass
after the Tech Lead returns the Phase 2 output. Rejected: it adds
a second Tech Lead invocation for a one-line decision, doubling
orchestration overhead. Grade in `/plan-implementation` itself
rather than in the Tech Lead's output. Rejected: the skill does
not have the synthesis context; it only parses and dispatches.

### D3. Memory section uses an append-only markdown table

The outcomes live in a new section `## Routing Outcomes` in the
Tech Lead's memory file at
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`.
The section is a markdown table with fixed columns:

```markdown
| Date       | Story Slug          | Specialist    | Value  | Note                         |
|------------|---------------------|---------------|--------|------------------------------|
| 2026-04-21 | add-retry-logic     | qa-lead       | medium | Added flake-resistance notes |
| 2026-04-21 | add-retry-logic     | devops-lead   | none   | No runtime concerns          |
```

Rows are appended, never edited in place. The `Note` column is a
short free-text reason the Tech Lead emits alongside the
`**Routing Value:**` line; it is optional but strongly
recommended for `none` and `low` so the audit skill can show the
user why a specialist was graded down.

**Rationale:** Markdown tables are readable by humans and by the
agent. Append-only semantics eliminate the concurrency question:
no plan ever needs to lock the memory file, and the worst-case
outcome of two concurrent plans is duplicated rows, not corruption.
Story slug is included so the user can trace a row back to its
originating plan.

**Alternatives considered:** JSONL in a separate file. Rejected:
requires readers to parse a non-markdown format and breaks the
convention that the Tech Lead's project memory is a single
markdown file. A normalized schema with separate tables for
specialists and outcomes. Rejected: over-engineered for data
that never exceeds a few hundred rows and is read by a single
advisory skill.

### D4. `/plan-implementation` appends outcomes after Phase 2

After Phase 2 synthesis completes, the `/plan-implementation`
skill parses each `### <Specialist Name>` subsection under
`## Specialist Consultations` and extracts the
`**Routing Value:**` line plus the optional `**Routing Note:**`
line. For each specialist, the skill appends one row to the
`## Routing Outcomes` table. The story slug is derived from the
input story (front matter `slug` field, filename without
extension, or the first heading slugified) with a fallback of
`unknown-slug` if no candidate is resolvable.

If the `## Routing Outcomes` section does not exist in the
memory file, the skill creates it with the header row and the
separator row before appending.

**Rationale:** The skill already parses the Phase 2 output to
display it; the outcome extraction piggybacks on that parse.
Writing to the Tech Lead's memory from the skill keeps the Tech
Lead's agent-side contract simple (emit the line; don't manage
the file).

**Alternatives considered:** Have the Tech Lead agent write the
outcomes directly during synthesis. Rejected: the Tech Lead's
definition keeps memory writes to explicit checkpoints
(onboarding, `/add-specialist`, etc.); embedding writes inside a
synthesis turn mixes concerns. Write the rows from a hook or a
post-skill wrapper. Rejected: adds surface area without benefit;
the skill is already the correct integration point.

### D5. Parse failure during append is non-fatal

If `/plan-implementation` cannot find the `**Routing Value:**`
line for a specialist, or the line's value is not in the fixed
vocabulary, the skill surfaces a one-line notice in its output:

> Routing outcome capture skipped for `<specialist>`: could not parse
> `**Routing Value:**` line.

The Phase 2 synthesis is still returned to the caller. No
rollback, no retry, no halt. On the no-match and parse-failure
paths (where Phase 2 did not run at all), no outcomes are
appended; there is nothing to grade.

**Rationale:** The outcome capture is a low-stakes signal. Losing
one row of data is better than blocking a plan. The notice makes
the failure visible so the user can update the Tech Lead's
definition if the output contract drifts.

**Alternatives considered:** Retry the Tech Lead with an explicit
"emit the missing line" prompt. Rejected: adds a re-synthesis
step for a cosmetic anchor. Fail the whole skill. Rejected:
catastrophic for a signal that exists only to tune the routing
table over time.

### D6. `/audit-routing-quality` is a separate skill from `/audit-routing-table`

The existing `/audit-routing-table` skill covers four structural
hygiene checks: orphan overrides, broken pointers, redundant
overrides, thin descriptions. It does not consume outcome data.
The new skill `/audit-routing-quality` consumes the
`## Routing Outcomes` table and produces narrowing
recommendations. The two are kept separate because:

- Inputs differ: structural vs. outcome history.
- Cadence differs: structural audit runs after onboarding or
  when routing looks wrong; quality audit runs when the user
  wants data-driven narrowing.
- Recommendations differ: structural audit says "fix this row";
  quality audit says "consider narrowing this description."

**Rationale:** Merging the two would force every
`/audit-routing-table` invocation to also process outcome
history, slowing the skill and blurring the mental model. The
skills complement each other; they do not replace each other.

**Alternatives considered:** Extend `/audit-routing-table` with
an `--include-outcomes` flag. Rejected: skills with modal flags
are harder to document; the decision tree branches on a
configuration, not a user intent.

### D7. Retention via user-confirmed roll-up at 200 rows

When `/audit-routing-quality` detects more than 200 rows in the
`## Routing Outcomes` table, it offers the user a roll-up: older
rows older than the most-recent 50 are condensed into summary
rows, one per specialist, with a combined count per value
bucket. Roll-up is user-confirmed; the skill never rewrites the
table without explicit permission.

**Rationale:** Bounded growth without data loss that blindsides
the user. The 200-row threshold gives at least 20 to 50 plans of
fully detailed history before any condensation. User
confirmation preserves the user's ability to keep full history
for audit-heavy projects.

**Alternatives considered:** Automatic truncation after N rows.
Rejected: silent data loss violates the append-only contract
users expect from memory files. Time-based retention (drop rows
older than 90 days). Rejected: conflates plan frequency with
calendar time; projects with slow cadence would lose data
prematurely.

### D8. Grading rubric is documented, not enforced

The rubric lives in the `routing-outcome-capture` spec and in a
referenced subsection of the Tech Lead's agent definition. The
rubric is descriptive, not algorithmic: different Tech Lead runs
may grade similar stories differently. The rubric includes a
"grade down when in doubt" convention that biases toward `low`
over `medium` and `none` over `low` when the synthesis has no
clear signal either way.

**Rationale:** Perfect inter-rater reliability is not achievable
for subjective grading, and the signal is valuable in aggregate
even when individual rows are noisy. The "grade down" convention
keeps the narrowing recommendations conservative: a specialist
that is systematically graded `low` under this convention is
highly likely to actually be over-routed.

**Alternatives considered:** Algorithmic grading based on
response length or keyword matches. Rejected: produces
false-positive `low` grades when specialists give terse but
decisive answers, and false-positive `high` grades when
specialists give long but non-actionable answers.

## Risks / Trade-offs

- **Grading subjectivity.** Different Tech Lead runs may grade
  the same response differently. **Mitigation:** The documented
  rubric and the "grade down when in doubt" convention. The
  `/audit-routing-quality` skill reports aggregates across
  multiple plans, not single-row verdicts, so noise averages out.
- **Memory bloat.** The `## Routing Outcomes` table grows every
  plan. **Mitigation:** The 200-row roll-up threshold in
  `/audit-routing-quality`. Rows are short (five columns), so
  200 rows is small by markdown standards.
- **Contract drift between the Tech Lead's output and the
  skill's parser.** If the Tech Lead starts emitting a different
  label, the append step silently skips. **Mitigation:** The
  parse-failure notice is surfaced in `/plan-implementation`'s
  output, so drift is user-visible within one plan.
- **Narrowing recommendations chilling specialist use.** If
  users aggressively prune specialists based on `low`-heavy
  history, a genuinely useful specialist could be removed for a
  streak of over-matched stories. **Mitigation:** The skill is
  advisory; edits require user action. Recommendations include
  the underlying row count and value distribution so the user
  can judge.
- **Append-only races.** Two concurrent plans could both append,
  producing interleaved rows. **Mitigation:** Append-only
  markdown tables tolerate interleaved rows without corruption;
  the worst outcome is two rows in an unexpected order, which is
  benign for an audit consumer.
- **Story slug collisions.** Two unrelated plans might share a
  derived slug. **Mitigation:** The `Date` column disambiguates;
  the `Note` column gives the user additional context when the
  audit skill surfaces a row.
- **Rubric drift.** The rubric in the spec and the rubric in the
  agent definition can diverge. **Mitigation:** The agent
  definition references the spec's rubric section rather than
  duplicating it; `/audit-routing-table` is not modified, so
  the spec remains the single source of truth.

## Migration Plan

The change is additive. No existing data is rewritten.

- The `## Routing Outcomes` section is missing in existing
  Tech Lead memory files. `/plan-implementation` creates the
  section on first append. `/audit-routing-quality` handles the
  missing section by reporting "no outcome history recorded yet"
  and exits without error.
- Existing Phase 2 output parsers are unaffected by the new
  `**Routing Value:**` line because they look for level-3
  subsection anchors and the `**Agent:**` / `**Prompt:**`
  markers, not for the value line.
- Rollback: remove the new spec, the new skill directory, revert
  the Tech Lead agent-definition edits that add the grading step
  and the rubric reference, and revert the
  `/plan-implementation` append step. Existing
  `## Routing Outcomes` sections in user memory files are left
  intact; they become inert but do not break anything.

## Open Questions

- Should the audit skill also suggest promoting signals into
  explicit `## Project Code Area Overrides` when a specialist is
  consistently graded `high` for a recognizable code area?
  Deferred: the current scope is narrowing, not broadening.
  Revisit after early usage shows whether the data is dense
  enough to support promotion heuristics.
- Should the grading rubric account for specialists that respond
  to Phase 2 follow-ups (out of scope today, but a possible
  future extension to `/plan-implementation`)? Deferred: today's
  protocol is single-round, so the rubric covers that case.
- Should the Tech Lead's Phase 2 output also record a
  `**Routing Note:**` line alongside `**Routing Value:**`?
  Decided yes: the note is optional in the line contract, but
  the rubric strongly recommends it for `none` and `low` grades.
  The skill appends the note text (empty string if absent) to
  the memory table.
