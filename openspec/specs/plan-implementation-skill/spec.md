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

### Phase 3 — Outcome Capture

This step runs only on the success path (Phase 2 completed and produced parseable specialist subsections). It does not run on the no-match or parse-failure paths.

17. For each `### <Specialist Name>` subsection in the Phase 2 output, extract:
    - The `**Routing Value:**` line value (must be one of `high`, `medium`, `low`, `none`).
    - The `**Routing Note:**` line value (optional single-sentence note on the line immediately after `**Routing Value:**`).
18. Derive the story slug using this order: front-matter `slug` field, then filename without extension (if `$ARGUMENTS` was a path), then the first heading of the story slugified, then `unknown-slug` as a fallback.
19. Append one row per specialist to the `## Routing Outcomes` section of the Tech Lead's project memory file (`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`). Each row contains `Date`, `Story Slug`, `Specialist`, `Value`, and `Note` as defined in `openspec/specs/routing-outcome-capture/spec.md`.
20. If the `## Routing Outcomes` section does not exist in the memory file, create it with the documented column header and separator rows before appending.
21. If a specialist's `**Routing Value:**` line is missing or its value is not in the fixed vocabulary, emit a one-line notice naming the affected specialist, skip that specialist's row, and continue appending for parseable specialists.
22. If the memory file cannot be written, emit a one-line notice identifying the write failure. The Phase 2 synthesis returned to the user is unaffected.

## Invariants

- The skill must not paraphrase, summarize, or truncate specialist responses before Phase 2.
- The skill must not augment the Tech Lead's per-specialist prompts before fan-out.
- The skill must not run Phase 2 on the no-match or parse-failure paths.
- The skill must always run Phase 2 when at least one specialist was matched, even if all specialist responses are empty.
- The skill must never silently drop a specialist miss; every miss appears in the Phase 2 input so the Tech Lead can flag the gap.
- Outcome capture must not modify the Phase 2 synthesis content returned to the caller.
- Outcome capture failures (parse errors, write errors) are surfaced as notices; they must never prevent the Phase 2 synthesis from reaching the user.
- The skill must not append any rows on the no-match or parse-failure paths.

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
- [ ] After a successful Phase 2 synthesis with three specialists, the Tech Lead's memory file contains three new rows in `## Routing Outcomes`, one per specialist, each with `Date`, `Story Slug`, `Specialist`, `Value`, and `Note`.
- [ ] When the memory file has no `## Routing Outcomes` section, the first successful run creates the section header, separator row, and appended rows.
- [ ] When Phase 2 output is missing a `**Routing Value:**` line for one specialist, the skill appends rows for the other specialists, emits a notice for the missing one, and returns the full Phase 2 synthesis unchanged.
- [ ] When the memory file cannot be written during outcome capture, the skill emits a write-failure notice and still returns the Phase 2 synthesis to the user.
- [ ] The skill appends no rows to `## Routing Outcomes` on the no-match path or the parse-failure path.
## Requirements
### Requirement: Post-Phase-2 outcome capture

The `/plan-implementation` skill SHALL append one row per
specialist to the `## Routing Outcomes` section of the Tech Lead's
memory file after Phase 2 synthesis completes successfully. The
append step runs only on the success path: when Phase 2 produced
output that the skill could parse into specialist subsections. The
skill MUST NOT append rows on the no-match path (no specialists
consulted) or the parse-failure path (Phase 1 output could not be
parsed against the expected contract).

Each row MUST contain values for `Date`, `Story Slug`,
`Specialist`, `Value`, and `Note` as defined in the
`routing-outcome-capture` capability. The story slug MUST be
derived using the documented order: front-matter `slug` field,
then filename without extension, then the first heading
slugified, then `unknown-slug` as a fallback.

The append step MUST NOT modify the Phase 2 synthesis content
returned to the caller; the synthesis is returned to the user as
before, with the append occurring as a side effect.

#### Scenario: Success path appends one row per specialist

- **WHEN** `/plan-implementation` completes Phase 2 synthesis with
  three specialists, each carrying a `**Routing Value:**` line
- **THEN** the skill appends three rows to the
  `## Routing Outcomes` section in the Tech Lead's memory file,
  one per specialist, each row containing the five documented
  columns

#### Scenario: No-match path appends nothing

- **WHEN** `/plan-implementation` takes the no-match path because
  Phase 1 produced no consultation requests
- **THEN** the skill does not append any row to
  `## Routing Outcomes`, because there is nothing to grade

#### Scenario: Parse-failure path appends nothing

- **WHEN** `/plan-implementation` takes the parse-failure path
  because Phase 1 output lacked the required anchors
- **THEN** the skill does not append any row to
  `## Routing Outcomes`, because Phase 2 did not run

### Requirement: Parse failures in the append step are non-fatal

The skill SHALL treat failures inside the outcome-append step as
non-fatal. If the Tech Lead's Phase 2 output lacks a
`**Routing Value:**` line for one or more specialists, or the
value is not in the fixed vocabulary, the skill MUST:

- Emit a one-line notice in its output identifying the affected
  specialists.
- Append rows for specialists whose values parsed successfully.
- Skip appending for specialists whose values failed to parse.
- Return the full Phase 2 synthesis to the caller unchanged.

A failure to write to the memory file (for example, because the
file is read-only) MUST NOT prevent the skill from returning the
Phase 2 synthesis. The write failure is surfaced as a notice, and
the plan still reaches the user.

#### Scenario: Partial parse failure surfaces a notice

- **WHEN** Phase 2 output contains `**Routing Value:**` lines for
  two of three specialists, with the third specialist's line
  missing
- **THEN** the skill appends two rows (for the parseable
  specialists), surfaces a notice naming the third specialist as
  unparseable, and returns the full Phase 2 synthesis to the
  caller

#### Scenario: Write failure does not discard the plan

- **WHEN** the Tech Lead's memory file cannot be written during
  the append step
- **THEN** the skill surfaces a notice identifying the write
  failure and still returns the Phase 2 synthesis to the caller

### Requirement: Append step creates the section when missing

The skill SHALL create the `## Routing Outcomes` section on first
append when the section does not exist in the memory file. The
created section MUST consist of:

- A `## Routing Outcomes` heading.
- The documented column header row
  `| Date | Story Slug | Specialist | Value | Note |`.
- The markdown-table separator row.
- One row per specialist with parsed values.

The skill MUST NOT reorder existing sections in the memory file
when creating the outcomes section; the new section is appended
at the end of the file or after the last existing
top-level-`##` section, whichever is consistent with the file's
current structure.

#### Scenario: First append creates header and separator

- **WHEN** the memory file exists and contains
  `## Registered Specialists` and `## Project Code Area Overrides`
  but no `## Routing Outcomes` section
- **THEN** the skill appends the `## Routing Outcomes` heading,
  the column header row, and the separator row, followed by one
  row per graded specialist

#### Scenario: Subsequent append does not duplicate the header

- **WHEN** the memory file already contains a
  `## Routing Outcomes` section with previous rows
- **THEN** the skill appends new rows after the existing rows, and
  does not duplicate the section header, column header row, or
  separator row

