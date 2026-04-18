# Spec: Plan-Implementation Skill

## Identity

- **Skill name:** `plan-implementation`
- **Skill path:** `skills/plan-implementation/SKILL.md`
- **User-invokable:** yes
- **Context:** `fork` (the skill produces multi-specialist output; keep the main conversation uncluttered)
- **Allowed tools:** `Read`, `Grep`, `Glob`, `Agent`, plus any tools the Tech Lead and specialists require at invocation time
- **Argument hint:** `[story body, story file path, or issue reference]`

## Purpose

Execute the Tech Lead's existing two-phase consultation protocol deterministically so that callers receive a single synthesized implementation plan without manually orchestrating Phase 1 routing, specialist fan-out, and Phase 2 synthesis.

## Trigger Phrases

- `/plan-implementation`
- "plan the implementation for ..."
- "deterministic implementation plan"
- "run the full implementation-planning protocol"

## Inputs

### `$ARGUMENTS`

The skill accepts one of:

- An inline story or issue body (markdown)
- A file path to a story or issue
- An issue reference the project environment can resolve (for example, a beads ID when beads is configured)

If `$ARGUMENTS` is empty, the skill **must** prompt for one of the accepted inputs before proceeding. The skill **must not** guess or synthesize a story.

### Environmental Dependencies

- Tech Lead agent is available in the plugin
- Tech Lead's project memory (including `## Registered Specialists` and `## Project Code Area Overrides`) is readable
- All specialist agents referenced by the registered specialists list are available under the slugs the Tech Lead emits

## Outputs

On success, the skill returns the Tech Lead's Phase 2 synthesis, which per `agents/tech-lead.md:168-195` contains:

- `## Engagement Depth`
- `## Specialist Consultations` (one subsection per specialist, with verbatim responses)
- `## Escalation Flags`
- `## Implementation Constraints`
- `## Recommended Approach`

On the no-specialists-matched path, the skill returns the Tech Lead's Phase 1 output verbatim with a prepended notice stating that no specialists were matched and Phase 2 was skipped.

On the parse-failure path, the skill returns the raw Phase 1 output with a prepended parse-failure notice identifying which contract element could not be parsed.

## Behavior

### Phase 1 — Routing

1. Resolve `$ARGUMENTS` to a story body.
2. Invoke the Tech Lead agent with the story and the prompt hint "plan the implementation."
3. Receive the Tech Lead's Phase 1 markdown output.

### Phase 1 Parse

4. Locate the `## Consultation Requests` heading. If absent, take the parse-failure path.
5. Locate the `## Next Step` heading. If absent, take the parse-failure path.
6. Between those two anchors, extract each level-3 subsection as a specialist request. For each subsection, capture:
   - The specialist's human-readable name (level-3 heading text)
   - The agent slug (value of the `**Agent:**` field, backtick-delimited)
   - The prompt body (blockquoted lines after `**Prompt:**`, stripped of the `> ` prefix but otherwise verbatim)
7. If zero subsections were extracted, take the no-match path.

### No-Match Path

8. Prepend this notice to the Phase 1 output and return it as the final plan:
   > No registered specialists matched this issue. Phase 2 synthesis was skipped. The Phase 1 output below is the final plan.

### Parse-Failure Path

9. Prepend this notice to the raw Phase 1 output and return it:
   > Phase 1 output could not be parsed against the expected contract ([which anchor or field failed]). The raw Phase 1 output is surfaced below for manual review.

### Specialist Fan-Out

10. Spawn all extracted specialists concurrently, each with the verbatim prompt the Tech Lead emitted.
11. Wait for every fan-out to complete before proceeding.
12. For each specialist, capture their full response. Record the response even when empty or erroring; mark empty/error responses with "No response received" for the Phase 2 input.
13. If a specialist slug does not resolve to an available agent, record the miss and continue. Do not halt fan-out.

### Phase 2 — Synthesis

14. Build the Phase 2 prompt with this structure:

    ```markdown
    # Original Story

    [Original story body]

    # Specialist Responses

    ## [Specialist Name] (agent: `[agent-slug]`)

    [Verbatim specialist response, or the "No response received" notice]

    ## [Specialist Name] (agent: `[agent-slug]`)

    [Verbatim specialist response, or the "No response received" notice]
    ```

15. Re-invoke the Tech Lead with this prompt. Request Phase 2 synthesis explicitly (for example, "Synthesize the final plan from the specialist responses above").
16. Return the Tech Lead's Phase 2 output to the user as the final result.

## Invariants

- The skill must not paraphrase, summarize, or truncate specialist responses before Phase 2.
- The skill must not augment the Tech Lead's per-specialist prompts before fan-out.
- The skill must not run Phase 2 on the no-match or parse-failure paths.
- The skill must always run Phase 2 when at least one specialist was matched, even if all specialist responses are empty.
- The skill must never silently drop a specialist miss; every miss appears in the Phase 2 input so the Tech Lead can flag the gap.

## Non-Requirements

- The skill does not need to support multi-turn refinement of specialist responses (a single fan-out round is sufficient).
- The skill does not need to expose a "Phase 1 only" option in this iteration; the Tech Lead remains directly consultable for that use case.
- The skill does not need to tier engagement (trivial issues vs. large stories). Tiering belongs at the caller level and is tracked separately.

## Acceptance Criteria

- [ ] Invoking `/plan-implementation` with a story that matches multiple specialists returns a single Phase 2 synthesis containing verbatim specialist responses, escalation flags, and a recommended approach.
- [ ] Invoking the skill with a story that matches no specialists returns the Phase 1 output prepended with the documented no-match notice; Phase 2 is not invoked.
- [ ] Invoking the skill with an empty `$ARGUMENTS` prompts the user for input and does not proceed until one is provided.
- [ ] When a specialist sub-agent errors or returns empty, the Phase 2 input contains a "No response received" notice for that specialist, and Phase 2 still runs.
- [ ] When the Tech Lead's Phase 1 output lacks `## Consultation Requests` or `## Next Step`, the skill returns the parse-failure path output rather than proceeding blindly.
- [ ] Running the skill twice on the same story with the same Tech Lead memory produces outputs with the same specialist set and the same top-level section ordering.
