---
name: refinement-review
description: "Convene the Product Owner, Chief Architect, and UX Strategist in parallel on a story draft and produce a consolidated readiness verdict. Use before /plan-implementation to surface scope, architectural, and persona-fit concerns while the story is still cheap to revise. Invoke with /refinement-review."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob, Bash, Agent
argument-hint: "<story body | file path | issue reference>"
---

# Refinement Review

Convene the Product Owner, Chief Architect, and UX Strategist in parallel on a
story draft. Each peer reviews the story from their own perspective and returns
an explicit verdict. The skill assembles a consolidated report with an overall
readiness verdict (`ready` / `needs-revision` / `blocked`), named peer
accountability, verbatim peer input, and next steps.

This skill is complementary to `/refine-story` (INVEST structural scoring) and
`/write-story` (story authoring). Use `/refinement-review` when the story draft
exists and you want strategic sign-off before implementation begins. Run
`/plan-implementation` after `/refinement-review` returns `ready`.

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

> Please provide the story draft to review. You can paste the story body
> directly, provide a file path (e.g., `./story.md`), or provide an issue
> reference (e.g., `ENG-123`). Do not proceed until a story is provided.

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

## Step 2: Parallel Peer Fan-Out

Invoke all three peers simultaneously in a single parallel batch. Do not wait
for one peer to respond before invoking the next. Issue all three Agent tool
calls together in the same turn.

**Product Owner prompt:**

```
Review this story draft from your perspective as product owner. Focus on:
scope fit (is this the right thing to build next?), business value (does it
deliver a clear user outcome?), roadmap alignment (does it belong in the
current phase?), and acceptance criteria completeness (do the ACs cover what
the product needs?). Surface any concerns about scope creep, premature
features, or missing business context.

Story:

[resolved story body]

End your response with a final line in this exact format:
Verdict: ready
OR
Verdict: needs-revision
OR
Verdict: blocked
```

**Chief Architect prompt:**

```
Review this story draft from your perspective as chief architect. Focus on:
one-way doors (does this commit the team to a data model, API contract, or
pattern that is hard to reverse?), cross-cutting impact (does this touch
multiple components or layers in a way that warrants early coordination?),
forward compatibility (does this decision hold two versions from now?), and
dependency risks (are there unresolved technical prerequisites?). Surface any
structural concerns that should be resolved before implementation begins.

Story:

[resolved story body]

End your response with a final line in this exact format:
Verdict: ready
OR
Verdict: needs-revision
OR
Verdict: blocked
```

**UX Strategist prompt:**

```
Review this story draft from your perspective as UX strategist. Focus on:
persona fit (which persona does this serve and is it the right one?),
user-observable outcomes (do the ACs describe what the user sees and can do,
or do they describe system internals?), behavioral consistency (does this
feature behave consistently with how similar features already work?), and
mental model impact (will this change how users understand or predict the
system?). Surface any concerns about persona mismatch, outcome framing, or
behavioral inconsistency.

Story:

[resolved story body]

End your response with a final line in this exact format:
Verdict: ready
OR
Verdict: needs-revision
OR
Verdict: blocked
```

Wait for all three peer responses before proceeding to Step 3.

For each peer response:

- If the response is empty, contains only whitespace, or the sub-agent errored,
  record it as a **failed invocation** with no verdict.
- Otherwise: record the verbatim response.

## Step 3: Parse Verdicts and Aggregate

For each peer response, extract the verdict:

- Scan the response for a line matching `Verdict: ready`, `Verdict:
  needs-revision`, or `Verdict: blocked` (case-insensitive). Use the last
  matching line if multiple appear.
- If no verdict line is found, or the peer invocation failed, treat the verdict
  as **unparseable** and record the peer name.

**Aggregation rules:**

1. If all three peers return `ready`: overall verdict is `ready`.
2. If any peer returns `blocked`: overall verdict is `blocked`.
3. If no peer returns `blocked` and at least one peer returns `needs-revision`:
   overall verdict is `needs-revision`.
4. If any peer invocation failed or returned an unparseable verdict: overall
   verdict is at least `needs-revision`, and the peer is named as responsible.

Record which peers drove any non-ready state.

## Step 4: Assemble Consolidated Report

Produce the consolidated report in this exact section order.

### Section 1: Overall Verdict

Emit the overall verdict as the first line of the report:

```
## Refinement Verdict: READY
```

or

```
## Refinement Verdict: NEEDS REVISION
```

or

```
## Refinement Verdict: BLOCKED
```

When the verdict is `needs-revision` or `blocked`, immediately follow with a
named accountability line:

```
Raised by: [peer-name(s) that drove the non-ready state, comma-separated]
```

### Section 2: Per-Peer Sections

Render one section per peer in the fixed order: `product-owner`,
`chief-architect`, `ux-strategist`. Use this format for each:

```
## product-owner

[verbatim peer response]
```

Apply the following markers as needed:

- **Successful response with no stated concerns** (peer returned `ready` with no
  listed concerns in the body): include the verbatim response and append a line:
  `_No concerns raised._`
- **Failed invocation** (empty response, error, or unresolvable agent): replace
  the verbatim response with:
  `_Invocation failed; input absent from this refinement._`

### Section 3: Objections (conditional)

Include an `## Objections` section when:

- The overall verdict is `needs-revision` or `blocked`, OR
- Any peer returned `ready` but stated a reservation inside the body.

Omit this section when all three peers returned clean `ready` with no stated
reservations.

Format each objection as a bullet attributed to the named peer, using the
peer's own wording verbatim:

```
## Objections

- **product-owner:** [verbatim scope concern from the peer's response]
- **chief-architect:** [verbatim architectural concern, if any]
```

### Section 4: Next Steps

Always include a `## Next Steps` section. Content should match the overall
verdict:

- **ready**: "All three peers approved this story. Proceed to implementation
  planning with `/plan-implementation`."
- **needs-revision**: "Address the concerns raised by [peer(s)] and re-run
  `/refinement-review` before beginning implementation. The concerns are listed
  in the `## Objections` section above."
- **blocked**: "Resolve the blocking concern raised by [peer(s)] before
  reopening the story for refinement. This concern may require a higher-level
  decision — consider consulting the named peer directly or escalating to the
  product owner for arbitration."
