---
name: write-story
description: "Write a well-structured user story with acceptance criteria and INVEST validation."
user-invokable: true
allowed-tools: Read, Grep, Glob
argument-hint: "[description of the feature or requirement]"
---

# Write Story

Write a complete, high-quality user story with INVEST validation.

## Input

`$ARGUMENTS` = description of the feature, requirement, or problem to solve.

## Process

### 1. Gather Context

- Read the project's CLAUDE.md for architecture, conventions, and domain language
- Scan for a roadmap or backlog file if one exists (Glob for roadmap*, backlog*, TODO*)
- Understand the domain well enough to write specific, testable criteria

**Readiness assessment:**

- If the story has hard blockers on unstarted work (entire epics or phases that have not begun), classify readiness as `backlog` and skip to the Backlog-Tier Output section at the end of this skill
- If dependencies are complete or actively in-progress, classify readiness as `sprint-ready` and continue the full process below

Detailed specification should happen at pull time, not envisioning time. Stories deep in the backlog will change as the project evolves — investing in full acceptance criteria and technical notes for work that is months away produces waste. A lightweight backlog entry captures intent and scope; the full story gets written when the team is ready to start.

### 2. Assess Context Sufficiency

> **Gate:** If readiness is `backlog`, skip to the **Backlog-Tier Output** section.

Before drafting, evaluate whether the input provides enough detail across four dimensions:

| Dimension | Sufficient when | Prompt if underspecified |
|-----------|----------------|--------------------------|
| **Persona** | A specific role or actor is named or clearly implied | "Who is the primary user or actor for this requirement?" |
| **Observable behavior** | The desired system behavior is concrete enough to demonstrate | "What should the system do — what would a user see or experience?" |
| **Benefit / motivation** | A reason or outcome beyond restating the capability is present | "Why does this matter — what problem does it solve or what outcome does it enable?" |
| **Scope boundaries** | At least a rough sense of what is in and out of scope is present | "What is explicitly out of scope or deferred for this work?" |

**Outcome paths:**

- **All sufficient** — proceed to Step 3 immediately. Do not prompt.
- **One or more underspecified** — present targeted questions for only the underspecified dimensions in a single consolidated prompt. Incorporate the answers into your working context, then proceed to Step 3.
- **No response (non-interactive context)** — infer reasonable answers from available project context (CLAUDE.md, roadmap, codebase). Record each inference in Technical Notes with the prefix "Inferred:" so the contributor can verify.

### 3. Draft the Story

> **Gate:** If readiness is `backlog`, skip to the **Backlog-Tier Output** section.

**Title**: Action-oriented, concise, starts with a verb.

- Good: "Add email notification after order approval"
- Bad: "Email improvement" or "Feature: better emails"

**Body structure**:

```
## User Story
As a [specific role — not "user"],
I want [specific capability — what the system should do],
so that [measurable benefit — why it matters to this role].

## Acceptance Criteria

Use Given/When/Then for behavioral criteria:
- [ ] Given [precondition], when [action], then [observable outcome]
- [ ] Given [precondition], when [action], then [observable outcome]

Use checkboxes for straightforward validations:
- [ ] [Specific, testable condition]

Include at minimum:
- 2-3 happy path criteria
- 1-2 error/edge cases
- 1 criterion for test coverage expectations

## Technical Notes
- **Scope**: XS / S / M / L / XL (relative size estimate)
- **Recommended model**: [haiku | sonnet | opus] — [one-sentence rationale]
- **Dependencies**: [other stories, services, or decisions this is blocked by]
- **Constraints**: [performance requirements, compatibility, regulatory, etc.]
- **Files likely affected**: [key modules — only if codebase context is available from step 1]
```

**What to avoid in acceptance criteria:**

Acceptance criteria must describe behavior observable by the persona, not internal system mechanics. Given/When/Then steps use domain language, not protocol or implementation language.

| Bad (implementation detail) | Good (domain behavior) |
|-----------------------------|------------------------|
| "then the API returns HTTP 201" | "then the order appears in the customer's order history" |
| "then the response body contains `{ status: 'ok' }`" | "then a confirmation message is displayed" |
| "when `createUser()` is called" | "when the visitor submits the registration form" |
| "then a row is inserted into the `notifications` table" | "then the customer receives a notification within 60 seconds" |

**Hard rule:** If an acceptance criterion references implementation artifacts (HTTP status codes, JSON shapes, file paths, function signatures, database columns), rewrite it in domain language and move the implementation detail to Technical Notes.

**Definition of Done guidance:**

Stories reference a project-level Definition of Done rather than repeating completion standards inline. Emit a `## Definition of Done` section ONLY when the story has requirements beyond the project standard.

Examples of story-specific DoD items (include only when applicable):

- An ADR is required for the architectural decision introduced by this story
- The runbook must be validated in staging before the story is accepted
- A load test must demonstrate the endpoint handles 500 req/s at p99 < 200ms

When present, place the `## Definition of Done` section after Technical Notes in the story body.

### 4. Validate with INVEST

Check every story against all six criteria before finalizing:

| Criterion | Question | Common failure |
|-----------|----------|----------------|
| **Independent** | Can this be delivered without waiting on another in-progress story? | Coupled to another story's implementation |
| **Negotiable** | Does it describe the *what/why* and leave room for *how*? | Specifies UI layout, API shape, or implementation approach |
| **Valuable** | Does the benefit statement name a real outcome for the role? | "So that the code is cleaner" — that's a refactor, not a user story |
| **Estimable** | Is there enough detail to estimate effort? | Vague scope, unknown integration, missing constraints |
| **Small** | Can it be completed in a single sprint? | Epic-sized scope, AC grouped under sub-headings, more than 7-8 acceptance criteria |
| **Testable** | Can every acceptance criterion be verified with a concrete test? | "Works correctly", "Handles all edge cases" |

If a criterion fails, fix the story before output. Common fixes:

- **Too large** — Detection signals: AC grouped under sub-headings, more than 7-8 criteria, implementation spanning multiple PRs. Split vertically by user-visible slice, not by technical layer. Use `/decompose-requirement` when any signal fires
- **Not independent** — Merge with the dependency or extract a shared prerequisite
- **Not valuable** — Rewrite with a real user outcome, or reclassify as a technical task
- **Not testable** — Replace vague criteria with specific Given/When/Then

### 5. Select Model Tier

Reason across three dimensions to select `recommended_model`:

| Dimension | Question |
|-----------|----------|
| **Complexity** | How many files are affected? Does the task require multi-step reasoning or deep domain knowledge? |
| **Latency tolerance** | Is this a quick task where fast turnaround matters, or a careful task where thoroughness is paramount? |
| **Cost** | Is the task well-scoped enough to trust a faster, cheaper model? |

**Selection rules:**

- **haiku** — XS or S size, low ambiguity, single-file or narrow-scope changes, no cross-service coordination. Override to `sonnet` if any of the following are present: multi-step reasoning, API design, cross-file impact.
- **sonnet** — M or L size, multi-step reasoning, cross-file changes, API design decisions, or ambiguous scope. Default for most stories.
- **opus** — Correctness-critical work (security, data integrity, complex algorithms), deep multi-layer debugging, or stories where Sonnet has previously struggled on similar work. Always include explicit rationale when recommending opus.

Record the chosen tier and a one-sentence rationale in the Technical Notes section of the story body.

### 6. Final Quality Check

Before presenting the story, verify:

- [ ] Title starts with a verb and is under 10 words
- [ ] Role is specific (not "user" or "developer" unless that truly is the role)
- [ ] Benefit is an outcome, not a restatement of the capability
- [ ] Every acceptance criterion is independently testable without reading other criteria
- [ ] Error cases are covered — not just the happy path
- [ ] No implementation details in acceptance criteria — check for HTTP status codes, JSON shapes, file paths, function signatures, and database columns; rewrite any offenders in domain language and move detail to Technical Notes
- [ ] Technical notes describe constraints and outcomes, not methods
- [ ] Scope size is present
- [ ] `recommended_model` is present and rationale is included in Technical Notes

### 7. Peer Review

**Delivery guarantee:** This step MUST conclude with the complete formatted story as the primary output. Nothing — no review feedback, coaching report, or product concern — replaces or defers the story delivery.

Run `/refine-story` on the draft story. Categorize every failing item into one of two categories and handle it accordingly:

**Craft issues** — mechanical problems fixable without product judgment:

- AC wording (implementation language, vague criteria, non-independent tests)
- DoD placement (completion standards mixed into ACs)
- Scope boundary gaps (missing out-of-scope statements)
- INVEST failures with clear rewrites (testability, estimability)

Apply craft fixes directly to the story. Record each fix in the `## Change Summary` section (one bullet per change with rationale). If no craft fixes were needed, omit the Change Summary.

**Product concerns** — substantive questions requiring user judgment:

- Horizontal work (pure infrastructure with no user-visible outcome)
- Scope-fit (story may belong to a different phase or epic)
- Reclassification (story is really a technical task or enabler)
- Cross-cutting concerns (unresolved dependencies, sequencing conflicts)

Collect product concerns for presentation to the user AFTER the story output. Do not attempt to resolve product concerns by modifying the story or escalating to another agent.

## Output

For **sprint-ready** stories, the markdown body MUST follow this exact section order with `##` headings:

1. `## User Story`
2. `## Acceptance Criteria`
3. `## Technical Notes`
4. `## Definition of Done` *(optional — only when story-specific DoD items exist beyond the project standard)*
5. `## Change Summary` *(optional — present only when Step 7 peer review resulted in revisions; one bullet per change with rationale)*

Additional rules:

- **Technical Notes format**: every item uses `**Label**: value` as a bullet — no prose paragraphs, no heading variations.
- **Optional fields** (`dependencies`, `Files likely affected`): omit entirely if empty. Never include blank bullets, "None", or placeholder text.

For **backlog** stories, see the Backlog-Tier Output section below — only `## User Story` is required.

**Example:**

```markdown
## User Story

As an **online customer**,
I want to receive an email notification when my order is approved,
so that I know my order is being processed without needing to check the website.

## Acceptance Criteria

- [ ] Given an order is approved, when the approval is saved, then an email is sent within 60 seconds
- [ ] Given the customer has no email on file, then no email is sent and a warning is logged
- [ ] Given the email service is unavailable, then the send is retried up to 3 times
- [ ] Email contains: order number, items ordered, estimated delivery date

## Technical Notes

- **Dependencies**: Requires the order approval event from the order workflow service
- **Constraints**: Email must be sent asynchronously; must comply with CAN-SPAM
- **Recommended model**: sonnet — multi-step async flow with cross-service integration warrants the workhorse model
```

### Product Considerations (conditional)

Present this section AFTER the complete story output when Step 7 identified product concerns. This section is NOT part of the story artifact — it is not included in the story body.

For each product concern:

- State the concern with enough context for the user to understand the issue
- Explain why this is a product decision rather than a craft fix
- Describe the trade-offs or options available

End with: "For interactive coaching on any of these concerns, consult `agile-coach`."

Omit this section entirely when no product concerns were identified in Step 7.

### Backlog-Tier Output

Use this format when readiness is `backlog` — the story has hard blockers on unstarted work and full specification would be premature.

**Skip:** acceptance criteria, technical notes, model recommendation, INVEST validation.

**Example:**

```markdown
## User Story

As an **integration partner**,
I want to receive webhook notifications when billing events occur,
so that I can keep my systems in sync without polling.

**Scope:** Covers webhook registration, delivery with retries, and a delivery log. Does not cover webhook signature verification (separate story).

**Why backlog:** The billing event pipeline (parent epic) has not started; detailed AC will be specified when this story is pulled into a sprint.
```
