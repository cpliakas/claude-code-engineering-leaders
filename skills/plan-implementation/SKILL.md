---
name: plan-implementation
description: "Drive the Tech Lead's two-phase implementation planning protocol end-to-end. Accepts a story or issue reference, invokes the Tech Lead for Phase 1 routing, spawns each matched specialist as a sub-agent in parallel, then re-invokes the Tech Lead for Phase 2 synthesis. Use when you want a fully orchestrated implementation plan without manually driving the two-phase consultation loop. Invoke with /plan-implementation."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob, Agent
argument-hint: "<story body | file path | issue reference>"
---

# Plan Implementation

Drive the Tech Lead's two-phase implementation planning protocol end-to-end,
producing a fully synthesized implementation plan without requiring manual
orchestration of the two phases.

## Dependencies

This skill depends on the Parseable Phase 1 Output Contract defined in
`agents/tech-lead.md` (see the "Parseable Phase 1 Output Contract" subsection
under Implementation Planning). If the Tech Lead's Phase 1 output format
changes, this skill's parsing logic must be updated to match. Conversely, if
this skill's parsing logic changes in a way that requires new contract fields or
relaxes existing constraints, the contract in `agents/tech-lead.md` must also be
updated to reflect the new expected format.

## Accepted Input Forms

`$ARGUMENTS` accepts three forms:

- **Inline story body**: paste the full story or issue description directly as
  the argument. The skill uses it verbatim.
- **File path**: a path to a markdown file containing the story or issue body
  (e.g., `./stories/auth-feature.md` or `/path/to/story.md`). The skill reads
  the file and uses its contents.
- **Issue reference**: an issue identifier (e.g., `ENG-123`, `#42`,
  `beads-456`). The skill attempts to resolve it via the configured issue
  tracker CLI (e.g., `bd show <id>`, `gh issue view <id>`). If no CLI is
  available or the reference cannot be resolved, the skill prompts for the story
  body before proceeding.

## Step 1: Resolve Input

If `$ARGUMENTS` is empty, prompt the user:

> Please provide the story or issue to plan. You can paste the story body
> directly, provide a file path (e.g., `./story.md`), or provide an issue
> reference (e.g., `ENG-123`). Do not proceed until a story or issue is
> provided.

Do not guess. Do not continue with a placeholder or fabricated story.

Once `$ARGUMENTS` is provided or confirmed:

- If it looks like a file path (starts with `/`, `./`, or `../`): use the Read
  tool to load the file. If the file does not exist, report the error and prompt
  for the story body directly.
- If it looks like an issue reference (the entire trimmed value matches patterns
  like `[A-Z]+-\d+`, `#\d+`, or `beads-\d+`): attempt to resolve via a
  configured CLI. Try `bd show $ARGUMENTS` first; if unavailable, try
  `gh issue view $ARGUMENTS`. If the command exits non-zero, is not found, or
  returns empty output, surface the failure and prompt for the story body
  directly:
  ```
  [INPUT ERROR] Could not resolve `[issue reference]` (tried: `[command]`).
  Please paste the story body directly.
  ```
- Otherwise: treat `$ARGUMENTS` as the inline story body.

Store the resolved story text as the story input for all subsequent steps.

## Step 2: Phase 1 Routing

Invoke the `tech-lead` agent with the following prompt:

```
Plan the implementation for this story. Use Phase 1 of your two-phase
consultation protocol: assess engagement depth, match registered specialists
via description and overrides, and emit structured consultation requests for
each matched specialist.

Story:

[resolved story body]
```

Collect the full Phase 1 response. Proceed to Step 3.

## Step 3: Parse Phase 1 Output

**Empty-response path:** If the Phase 1 response is empty or contains only
whitespace, surface a failure notice and stop:

```
[PHASE 1 FAILURE] The Tech Lead returned no output. Verify that the tech-lead
agent is registered and retry /plan-implementation.
```

Stop here. Do not attempt Phase 2.

**No-specialists-matched path:** Check whether the response signals that no
registered specialists matched. This can appear as:

- The text "No registered specialists matched this issue" anywhere in the
  response, OR
- A `## Consultation Requests` section that is present but contains zero
  level-3 specialist subsections.

If either condition is met, treat the Tech Lead's output as the final plan:

```
[NOTICE] No registered specialists matched this story. The Tech Lead produced
a direct plan without specialist consultation. This may be expected for stories
with no domain specialist concerns. Run /onboard or /add-specialist if
specialist coverage is unexpectedly missing.

---

[Phase 1 output]
```

Stop here. Do not proceed to Phase 2.

**Parse-failure path:** If `## Consultation Requests` is absent from the
response and no no-match signal was detected above, the output cannot be parsed.
Surface it with a notice:

```
[PARSE FAILURE] The Tech Lead's Phase 1 output did not contain a
## Consultation Requests section. The raw Phase 1 output follows. You may
re-run /plan-implementation or manually drive Phase 2 using the output below.

---

[raw Phase 1 output]
```

Stop here. Do not attempt Phase 2.

**Parse success:** For each specialist subsection (level-3 heading between
`## Consultation Requests` and `## Next Step`), extract:

- The **agent slug** from the `**Agent:** \`<slug>\`` field
- The **prompt** from the blockquote lines (`> ...`) following the
  `**Prompt:**` field. Collect all consecutive `> ` lines as the prompt body.

Stop parsing specialist subsections when `## Next Step` is encountered.

Record each specialist as a (slug, prompt) pair. Proceed to Step 4.

## Step 4: Parallel Specialist Fan-Out

For each extracted (slug, prompt) pair:

- **Slug not resolvable:** If the slug does not correspond to a known agent in
  the project's `.claude/agents/` directory or the plugin's `agents/` directory,
  skip the specialist. Surface the miss to the user and record it for Phase 2:
  ```
  [WARNING] Specialist `[slug]` could not be resolved to a registered agent.
  This specialist's input will be absent from the final plan.
  ```

- **Resolvable specialists:** Spawn each as a sub-agent in a single parallel
  batch, using the verbatim prompt extracted from Phase 1. Do not augment,
  summarize, or rewrite the prompts.

Wait for all specialist responses before proceeding to Step 5.

For each specialist response:

- **Empty/error:** If a response is empty, contains only whitespace, or the
  sub-agent errored, surface the miss to the user and record it for Phase 2:
  ```
  [WARNING] No response received from specialist `[slug]`. This specialist's
  input will be absent from the final plan.
  ```
- Otherwise: record the verbatim response.

Note: This skill always runs the full specialist fan-out regardless of the Tech
Lead's engagement depth classification (Minimal / Standard / Full). Tiering the
fan-out based on depth is a caller-level concern tracked separately. The skill
is intentionally conservative: a fast "nothing for me here" from a specialist is
cheaper than a missed constraint.

## Step 5: Assemble Phase 2 Input

**All-specialists-missing:** If every specialist slot is a miss (all were
unresolvable or returned empty), surface a warning to the user before proceeding:

```
[WARNING] No specialist responses were received. All [N] specialists either
could not be resolved or returned empty responses. The Tech Lead will synthesize
a best-effort plan from conventions alone; the result will lack domain-specific
constraints. Check that specialists are registered via /add-specialist.
```

Still proceed to Phase 2 with all-missing notices. The Tech Lead synthesizes a
best-effort plan and explicitly flags the gap.

Construct the Phase 2 prompt using the following structure:

```markdown
# Original Story

[Resolved story body from Step 1]

# Specialist Responses

## [agent-slug]

[Verbatim specialist response]

## [agent-slug]

> No response received. Synthesize without this input and flag the gap.
```

Use "No response received. Synthesize without this input and flag the gap." for
any specialist slot where the response was empty, errored, or where the slug
could not be resolved.

## Step 6: Phase 2 Synthesis

Invoke the `tech-lead` agent with the following prompt:

```
You are in Phase 2 of the two-phase implementation planning protocol.
Below is the original story and the verbatim specialist responses collected
after Phase 1. Synthesize them into a final implementation plan following your
Phase 2 synthesis format.

[Phase 2 input block from Step 5]
```

Collect the full Phase 2 response.

**Phase 2 failure path:** If the Phase 2 response is empty, contains only
whitespace, or the invocation errored, surface a failure notice and stop:

```
[PHASE 2 FAILURE] The Tech Lead did not return a Phase 2 synthesis. The
assembled specialist input follows so you can attempt a manual synthesis or
re-run /plan-implementation.

---

[Phase 2 input block from Step 5]
```

Stop here. Do not proceed to Step 7.

## Step 7: Return the Plan

Return the Phase 2 synthesis to the user as the final output. No additional
summarization or wrapping is needed.
