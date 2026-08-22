---
name: plan-implementation
description: "Produce a fully synthesized implementation plan for a story or issue. Accepts a story body, file path, or issue reference; reads the Tech Lead's routing model, matches and dispatches every relevant specialist by target type in parallel, then invokes the Tech Lead once to synthesize the specialist input into an implementation plan. Use when you want an orchestrated implementation plan with specialist consultation. Invoke with /plan-implementation."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob, Bash, Agent, Skill
argument-hint: "<story body | file path | issue reference>"
---

# Plan Implementation

Produce a synthesized implementation plan for a story. This skill owns all
mechanical routing: it reads the Tech Lead's routing model directly, matches
specialists, dispatches them by target type, and then invokes the Tech Lead
**once** — for judgment, not routing — to synthesize the results.

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

## Step 2: Load the Routing Model

Read `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md` directly.
Use two sections:

- **`## Registered Specialists`** — a flat list of specialist entries. Each
  entry carries an optional path-or-slug and an optional
  `target-type: <type>` suffix; when the suffix is absent, the target type
  defaults to `subagent`. Supported target types: `subagent`, `skill`, `doc`,
  `human`, `external-agent`.
- **`## Project Code Area Overrides`** — a table of project-local signals
  (file globs, repo-specific module names, internal terminology) mapped to
  registered specialists.

If an entry declares a target type outside the five supported values, emit a
routing warning naming the entry and the invalid type, then treat the entry
as `subagent` — never silently drop it.

If the memory file is missing, or `## Registered Specialists` is missing or
empty, emit this notice, skip the matching in Step 3 and the dispatch in
Step 4 (tier classification in Step 3 still runs — Step 5 requires a tier),
and proceed to Step 5 with zero specialists:

```
[NOTICE] No registered specialists were found in the Tech Lead's routing
model. The plan will be produced without specialist consultation. Run
/onboard or /add-specialist if specialist coverage is unexpectedly missing.
```

## Step 3: Match and Tier

**Load descriptions.** For each `subagent` entry, read the agent definition
file at the entry's path (default: `agents/<agent-name>.md`). If a file
cannot be read, emit a routing warning naming the agent and path — never
silently drop a specialist:

```
[WARNING] Could not read agent file for `[agent-name]` at `[path]`. This
specialist cannot be dispatched; its input will be absent from the final plan.
```

Carry every routing warning forward to Step 5.

**Match.** A specialist matches the story if either holds:

- The story text matches the specialist's trigger phrases or jurisdiction as
  described in its `description` field. This is a **semantic match** — the
  story concerns the specialist's domain — not a literal substring test.
- The story text or any referenced file paths match a row in
  `## Project Code Area Overrides` whose target is this specialist.

`skill`, `doc`, `human`, and `external-agent` entries are always match
candidates: the user registered them explicitly, so their relevance is
assumed. An `external-agent` entry's path-or-slug is a namespaced
`plugin:agent-slug` used for dispatch in Step 4 — it is not a readable local
file, so do not attempt to read one.

**Tier.** Classify the story using the
[Signals Catalog](../../README.md#signals-catalog) in the top-level README.
The three canonical tier labels are:

- `1 — Direct specialist`: single-domain change following an established
  pattern. Dispatch ONLY the single most relevant specialist. Synthesis still
  runs — do not skip it. Record every other matched specialist as
  **deprioritized at tier 1** and carry those records forward to Step 5 so
  they appear in the synthesis as not-consulted slots.
- `2 — Standard` and `3 — Full (with Architect escalation)`: dispatch every
  matched specialist.

**User override:** If the invocation explicitly states a tier (e.g., "plan
this at tier 3"), use that tier and record the override in the rationale.

Note the tier and its rationale; both are passed to the Tech Lead in Step 5.
Emit the canonical tier label **verbatim** on the `# Tier Classification`
line — the Tech Lead's tier-3 escalation requirement keys on it.

**Hard rule — every match is dispatched.** At tiers 2 and 3, never skip a
matched specialist because consultation seems unnecessary. A fast "nothing for
me here" is cheaper than a missed constraint.

**Unregistered domain gaps.** If a relevant domain has no registered
specialist, record the gap for Step 5. Never invent a consultation for an
agent that is not registered.

**Zero matches from a populated registry.** If specialists are registered but
none match this story, emit this notice, skip the dispatch in Step 4, and
proceed to Step 5 with zero specialist responses:

```
[NOTICE] No registered specialists matched this story. The plan will be
produced without specialist consultation. If a relevant domain seems
uncovered, register a specialist via /add-specialist.
```

## Step 4: Dispatch by Target Type

Dispatch every matched specialist according to its target type:

- **`subagent` and `external-agent`**: spawn in one parallel batch via the
  Agent tool. Author a focused prompt for each: the story context, the
  relevant code areas, and the questions this specialist should answer.
- **`skill`**: invoke the named skill via the Skill tool with a focused
  argument derived from the story.
- **`doc`**: read the referenced file and extract the constraints relevant to
  the story.
- **`human`**: do not block. Record the question for this person as an open
  item for the synthesis to surface.

Wait for all dispatched responses before proceeding.

For each response:

- **Empty/error:** If a response is empty, contains only whitespace, or the
  dispatch errored, surface the miss and record it for Step 5:
  ```
  [WARNING] No response received from specialist `[slug]`. This specialist's
  input will be absent from the final plan.
  ```
- Otherwise: record the verbatim response.

**All-specialists-missing:** If at least one specialist was actually
dispatched and every dispatched specialist is a miss, surface a warning
before proceeding:

```
[WARNING] No specialist responses were received. All [N] specialists either
could not be dispatched or returned empty responses. The Tech Lead will
synthesize a best-effort plan from conventions alone; the result will lack
domain-specific constraints. Check that specialists are registered via
/add-specialist.
```

Still proceed to Step 5 with all-missing notices.

## Step 5: Tech Lead Synthesis

Invoke the `tech-lead` agent **once** with everything gathered:

```markdown
Produce your Implementation Plan Synthesis for this story.

# Story

[Resolved story body from Step 1]

# Tier Classification

[Tier label] — [rationale from Step 3]

# Specialist Responses

[One subsection per specialist as below, or "None — no specialists were
dispatched (see the notice carried forward from Step 2 or Step 3)."]

## [specialist-slug]

[Verbatim specialist response]

## [specialist-slug]

> No response received — synthesize without this input and flag the gap.

## [specialist-slug]

> Not consulted — deprioritized at tier 1.

# Doc Extracts

[Constraints extracted from each doc target, or "None."]

# Open Human Questions

[Questions recorded for human targets, or "None."]

# Routing Warnings

[Routing warnings from Step 3, or "None."]

# Unregistered Domain Gaps

[Gaps recorded in Step 3, or "None."]
```

Use "No response received — synthesize without this input and flag the gap."
for any specialist slot where the response was empty, errored, or where the
specialist could not be dispatched. Use "Not consulted — deprioritized at
tier 1." for every matched specialist that was not dispatched under tier 1 —
never silently omit a match from the assembled input.

The Tech Lead's agent definition defines the synthesis output format.

**Synthesis failure path:** If the Tech Lead's response is empty, contains
only whitespace, or the invocation errored, surface the assembled input with a
failure notice so the user can retry:

```
[SYNTHESIS FAILURE] The Tech Lead did not return a synthesis. The assembled
input follows so you can attempt a manual synthesis or re-run
/plan-implementation.

---

[Assembled input block from Step 5]
```

Stop here.

## Step 6: Return the Plan

Return the Tech Lead's synthesis to the user verbatim as the final output. No
additional summarization or wrapping is needed.
