# Design: Plan-Implementation Skill

## Context

The Tech Lead agent already defines a two-phase consultation protocol for implementation planning (see `agents/tech-lead.md:94-195`). The protocol exists because sub-agents cannot spawn further sub-agents; the Tech Lead emits structured consultation requests in Phase 1, the caller executes them, then the Tech Lead synthesizes in Phase 2.

The protocol's correctness depends entirely on the caller faithfully executing both phases. This design defines a skill that removes that dependency by driving both phases deterministically.

## Design Principles

1. **Wrap, don't replace.** The skill operationalizes the existing protocol; it does not change the Tech Lead's output formats, rules, or response modes.
2. **Parse a documented contract.** The skill depends on a specific markdown shape in the Tech Lead's Phase 1 output. That shape becomes a documented contract rather than an incidental format.
3. **Fail loudly, not silently.** If Phase 1 output cannot be parsed, or a specialist returns empty, the skill surfaces the condition rather than producing a half-plan.
4. **Preserve specialist voices.** Specialist responses flow into Phase 2 verbatim — the skill does not paraphrase, summarize, or truncate them.
5. **Degrade gracefully.** No-specialists-matched is a first-class path, not an error.

## Input Contract

The skill accepts a single positional argument via `$ARGUMENTS`:

- A story or issue body (markdown pasted or referenced)
- A file path pointing to a story or issue
- An issue identifier the caller can resolve (e.g., a beads ID when beads is configured)

If `$ARGUMENTS` is empty, the skill prompts for the story body or reference before proceeding. It does not guess.

## Parseable Phase 1 Output Contract

The skill parses the Tech Lead's Phase 1 output using the structure already described in `agents/tech-lead.md:116-149`. The parseable elements are:

- A `## Consultation Requests` heading that contains zero or more specialist subsections
- Each specialist subsection:
  - Level-3 heading with the specialist's human-readable name
  - A bold `**Agent:**` field on its own line whose value is the agent slug, backtick-quoted
  - A bold `**Prompt:**` field on its own line followed by a blockquote (lines prefixed with `> `) containing the prompt
- A `## Next Step` heading that signals end-of-requests

The skill does not rely on heading case beyond exact matches on `## Consultation Requests` and `## Next Step`. If either anchor is missing, parsing fails loudly.

When the Tech Lead emits no consultation requests (either the section is absent, empty, or explicitly notes "No routing table matches for this issue"), the skill treats the Phase 1 output as the final plan and skips Phase 2.

## Phase 2 Input Format

When the skill re-invokes the Tech Lead for Phase 2, it concatenates specialist responses under a structured heading so the Tech Lead's synthesis logic has a predictable input shape. Proposed format:

```markdown
# Original Story

[Original story body passed to Phase 1]

# Specialist Responses

## [Specialist Name] (agent: `[agent-slug]`)

[Specialist's verbatim response]

## [Specialist Name] (agent: `[agent-slug]`)

[Specialist's verbatim response]

<!-- For any specialist whose response was empty or errored: -->
## [Specialist Name] (agent: `[agent-slug]`)

> No response received. Synthesize without this input and flag the gap.
```

The Tech Lead's existing Phase 2 instructions already expect specialist input to be quoted verbatim, so this format maps cleanly onto the synthesis step.

## Parallel Fan-Out Semantics

- Specialists are spawned concurrently. The skill launches all matched specialists in a single fan-out, then waits for all responses before moving to Phase 2.
- Sub-agent invocations use the prompt verbatim from the Tech Lead's Phase 1 output. The skill does not augment, summarize, or rewrite prompts.
- If a specialist sub-agent errors or returns an empty response, the skill records the condition and continues; the empty slot is surfaced in the Phase 2 input so the Tech Lead can explicitly flag it.

## Failure Modes

| Condition | Behavior |
| --- | --- |
| `$ARGUMENTS` empty | Prompt for story body or reference; do not proceed without input. |
| Phase 1 output missing `## Consultation Requests` | Surface the raw Phase 1 output with an explicit parse-failure notice; do not attempt Phase 2. |
| Phase 1 output has the section but zero subsections | Treat as no-specialists-matched. Return the Phase 1 output as the final plan with a notice. |
| One specialist slug does not resolve to an available agent | Skip that specialist; record the miss in the Phase 2 input so the Tech Lead can flag the routing gap. |
| One specialist returns empty or errors | Continue with remaining responses; record the miss in the Phase 2 input. |
| All specialists return empty or error | Invoke Phase 2 anyway with all-missing notices; let the Tech Lead synthesize a best-effort plan and explicitly flag the gap. |

## Alternatives Considered

- **Sequential specialist consultation.** Rejected: parallel fan-out is strictly faster with no synthesis cost, because specialists do not see each other's output by design.
- **Skill invokes specialists without going through the Tech Lead.** Rejected: the Tech Lead owns the routing logic and per-specialist prompts. Bypassing it duplicates logic and diverges over time.
- **Skill augments specialist prompts with shared context.** Rejected: the Tech Lead's emitted prompt is the contract. Augmenting it changes specialist behavior unpredictably.
- **Skill renders intermediate Phase 1 output to the user and waits for confirmation.** Rejected for the default path: it reintroduces the discipline gap the skill is meant to close. An opt-in "Phase 1 only" mode may be added in a future iteration if users need it.

## Open Questions

- Should the skill surface the Phase 1 output to the user before proceeding to Phase 2, or only after Phase 2 synthesis completes? Current design: only after, to minimize noise. Revisit if users request mid-execution visibility.
- Should the skill allow the caller to pass a specialist allowlist or denylist to skip particular agents? Current design: no. The Tech Lead's routing table is the source of truth; exceptions belong in the routing table, not at the skill's interface.
- Does the Tech Lead agent definition need a new "Parseable Phase 1 output contract" subsection that explicitly calls out the field anchors this skill depends on? Current design: yes, a small clarifying addition is in scope for the change.
