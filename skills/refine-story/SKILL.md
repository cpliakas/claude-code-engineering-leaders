---
name: refine-story
description: "Score a story draft against INVEST criteria and eight agile coaching principles. Returns a structured report with pass/fail per dimension and specific rewrites or corrective actions for failures."
user-invokable: true
allowed-tools: Read, Grep, Glob
context: fork
argument-hint: "[paste the story draft or describe the story to review]"
---

# Refine Story

Score a story draft against INVEST criteria and eight agile coaching principles. Returns a structured report with pass/fail per dimension and specific rewrites or corrective actions for every failure.

## Input

`$ARGUMENTS` = the story draft to review (paste the full story text, or describe the story if no draft is available yet).

## Process

### 1. Parse Input

Read the story draft. Identify:

- Title
- User Story statement (role, capability, benefit)
- Acceptance Criteria list
- Technical Notes section (if present)
- Definition of Done section (if present)
- Any scope statements

If only a description is provided (no draft), construct a minimal story from the description to give the scoring something to evaluate, and note that the review is based on a reconstructed draft.

### 2. Score INVEST

Score each of the six INVEST dimensions. For each, produce **PASS** or **FAIL** with a one-sentence explanation.

| Criterion | Question | Common failure |
|-----------|----------|----------------|
| **Independent** | Can this be delivered without waiting on another in-progress story? | Coupled to another story's implementation |
| **Negotiable** | Does it describe the *what/why* and leave room for *how*? | Specifies UI layout, API shape, or implementation approach |
| **Valuable** | Does the benefit statement name a real outcome for the role? | "So that the code is cleaner" — that's a refactor, not a user story |
| **Estimable** | Is there enough detail to estimate effort? | Vague scope, unknown integration, missing constraints |
| **Small** | Can it be completed in a single sprint? | Epic-sized scope, more than 7-8 acceptance criteria |
| **Testable** | Can every acceptance criterion be verified with a concrete test? | "Works correctly", "Handles all edge cases" |

### 3. Evaluate Coaching Principles

Evaluate each of the eight principles with **PASS** or **FAIL**. For every FAIL, provide a specific issue and a suggested rewrite or corrective action.

**Principle 1 — AC Outcome-Orientation**

Acceptance criteria describe behavior observable by the persona in domain language. Fail if criteria reference:

- HTTP status codes (e.g., "returns 200", "responds with 404")
- JSON shapes (e.g., "the response body contains `{ status: 'ok' }`")
- File paths, function signatures, or database columns
- Internal system mechanics instead of user-visible outcomes

**Principle 2 — DoD Explicit and Separated**

The story either references a project-level DoD or defines story-specific DoD items in a `## Definition of Done` section separate from acceptance criteria. Fail if:

- Completion standards (test coverage, security review, runbook update) are embedded inside acceptance criteria bullets
- No DoD section exists and story-specific completion requirements are present

**Principle 3 — Estimation Deferred to Refinement**

Size estimate and model recommendation belong to the story artifact as metadata fields. Fail if the story body contains planning discussion artifacts or team-internal estimation notes that are not proper metadata.

**Principle 4 — Scope Boundaries Explicit**

Non-obvious exclusions are named. Fail if adjacent features could reasonably be assumed in scope but are not addressed. Look for stories where a reader might reasonably expect feature X to be included.

**Principle 5 — Vertical Slice over Horizontal Layer**

The story delivers a user-visible outcome end-to-end. Fail if the story delivers only:

- A database migration with no UI or API change
- A service method or repository layer with no calling code
- Infrastructure provisioning with no feature enabled

These are technical tasks or enablers, not user stories.

**Principle 6 — Each AC Independently Testable**

Every acceptance criterion can be verified in isolation. Fail if:

- Criteria share unstated preconditions that are only defined in other criteria
- A criterion only makes sense after another criterion has been checked
- The criteria form a sequential script rather than independent conditions

**Principle 7 — Technical Notes as Disposable Context**

Technical notes help the implementer start faster; they are not requirements. Fail if:

- Performance requirements appear only in Technical Notes instead of as acceptance criteria
- Security requirements, data retention rules, or behavioral constraints are buried in notes
- Removing a technical note would change what gets built

**Principle 8 — Single-Concept Cohesion**

The story describes one coherent change, not several bundled changes. Evaluate the six failure signals below. Raise **FAIL** when **two or more** signals are observed; one signal alone does not trigger a FAIL (note it as an observation and pass).

Six failure signals:

1. Acceptance criteria describe adding multiple unrelated fields, features, or capabilities to the same surface (UI modal, API endpoint, CLI command, or other shared artifact).
2. One acceptance criterion is a gap fix or parity-with-backend change while another is net-new product behavior or a new capability.
3. Acceptance criteria have materially different risk profiles (for example, a low-risk UI polish criterion alongside a new-capability criterion with unexplored UX surface area).
4. Acceptance criteria would naturally carry different priorities if filed separately (for example, one criterion ships this sprint while another is a backlog candidate).
5. The story's scope statement hedges by joining items with "and" where the items do not share a user outcome ("add X and Y" where X serves one persona goal and Y serves a different one).
6. The independence test passes in reverse: splitting the story would **not** create awkward dependency chains, and each half could ship independently and deliver user value on its own.

On FAIL, include a **Suggested split** output block. Do **not** produce a "Suggested rewrite" that merges the halves into a single restated story; the correct action is always a split. The block must contain one entry per proposed child story, each with:

- A role / capability / benefit statement in standard user-story form ("As a \<role\>, I want \<capability\>, so that \<benefit\>").
- The subset of the original draft's acceptance criteria that belong to the child, possibly reworded to stand alone.
- A one-line split-boundary note explaining why the boundary is drawn where it is (e.g., "split on persona outcome", "split on risk profile", "split on shippable unit of value").

On PASS with a single observed signal, note the observation briefly. On PASS with zero signals, a brief confirmation is sufficient.

### 4. DoD Check

If no `## Definition of Done` section is present:

- Flag as missing
- Determine whether story-specific DoD items exist that should be separated from ACs
- Distinguish from team-level standing DoD (which should live in a project-wide document, not per story)
- Recommend: add story-specific DoD section, reference project DoD, or note that no story-specific DoD is needed

### 5. Horizontal Work Flag

If the story delivers no user-visible outcome:

- Flag as candidate for reclassification as a **technical task** or **enabler**
- State what user-visible outcome, if any, could justify keeping it as a story

### 6. Produce Structured Report

Format the output using the Output section below.

## Output

```
## INVEST Scorecard

| Criterion    | Result | Notes |
|--------------|--------|-------|
| Independent  | PASS   | ...   |
| Negotiable   | FAIL   | ...   |
| Valuable     | PASS   | ...   |
| Estimable    | PASS   | ...   |
| Small        | PASS   | ...   |
| Testable     | FAIL   | ...   |

## Coaching Principles

1. **AC Outcome-Orientation**: PASS/FAIL
   - [Explanation]
   - *Suggested rewrite:* [rewritten criterion, if failing]

2. **DoD Explicit and Separated**: PASS/FAIL
   - [Explanation]
   - *Suggested rewrite:* [rewritten DoD section or recommendation, if failing]

3. **Estimation Deferred to Refinement**: PASS/FAIL
   - [Explanation]

4. **Scope Boundaries Explicit**: PASS/FAIL
   - [Explanation]
   - *Suggested addition:* [out-of-scope statement, if failing]

5. **Vertical Slice over Horizontal Layer**: PASS/FAIL
   - [Explanation]
   - *Reclassification suggestion:* [technical task / enabler framing, if failing]

6. **Each AC Independently Testable**: PASS/FAIL
   - [Explanation]
   - *Suggested rewrite:* [rewritten criterion(ia), if failing]

7. **Technical Notes as Disposable Context**: PASS/FAIL
   - [Explanation]
   - *Suggested move:* [criterion text to add to AC section, if failing]

8. **Single-Concept Cohesion**: PASS/FAIL
   - [Explanation — enumerate which signals were observed and whether quorum was reached]
   - *Suggested split:* [per-child role / capability / benefit statement, AC subset, and split-boundary note, if failing]

## Definition of Done

[PRESENT / MISSING — recommendation]

## Horizontal Work

[NONE / FLAGGED — reclassification recommendation if flagged]

## Summary

**X of 6 INVEST criteria passing. Y of 8 coaching principles passing.**

Priority fixes:
1. [Highest-impact issue and action]
2. [Second issue and action]
...
```

Omit sections that are not applicable (e.g., omit Horizontal Work if no flag was raised). Keep each explanation to 1-2 sentences. Rewrites should be concrete and ready to paste into the story.

## Single-Concept Cohesion Example

The following example illustrates how Principle 8 works in practice, covering both the FAIL path (accidental bundle) and a separate intentional-bundle alternative handled by the Agile Coach.

### Example A — Conflated draft (FAIL)

**Original story draft:**

> **Title:** Improve user profile modal  
> **As a** power user,  
> **I want** the profile modal to show my timezone preference and include a DAG-based dependency view of my active workflows,  
> **so that** I can manage my settings and understand workflow relationships in one place.
>
> **Acceptance Criteria:**
> 1. The modal displays the timezone field sourced from the existing `user.timezone` backend column.
> 2. A new Workflow Dependencies panel renders an interactive DAG showing the user's active workflow relationships.
> 3. Selecting a node in the DAG highlights dependent workflows.

**Single-Concept Cohesion verdict:** **FAIL**

Observed signals:
- Signal 1: Two unrelated capabilities on the same modal surface (timezone parity fix and net-new DAG panel).
- Signal 2: AC #1 is a parity-with-backend gap fix; ACs #2–#3 are net-new product behavior requiring UX exploration.
- Signal 3: AC #1 is low-risk (field already exists in the backend); ACs #2–#3 carry unexplored UX surface area.
- Signal 4: AC #1 ships in the current sprint as a quick parity fix; ACs #2–#3 are backlog candidates pending DAG design.

Four signals observed. Quorum reached (≥ 2). **FAIL.**

**Suggested split:**

*Split boundary: split on shippable unit of value — the timezone parity fix and the DAG feature serve different user outcomes and have different risk profiles.*

**Child A:**
> As a power user, I want the profile modal to show my timezone preference, so that my time-sensitive settings reflect my local context.
>
> Acceptance Criteria:
> 1. The modal displays the timezone field sourced from the existing `user.timezone` backend column.

**Child B:**
> As a power user, I want a Workflow Dependencies panel in my profile area that shows an interactive DAG of my active workflows, so that I can understand how my workflows relate to one another.
>
> Acceptance Criteria:
> 1. A Workflow Dependencies panel renders an interactive DAG showing the user's active workflow relationships.
> 2. Selecting a node in the DAG highlights dependent workflows.

### Example B — Intentional bundle (PASS after Agile Coach judgment)

**Story draft:**

> **Title:** Add API key expiry field  
> **As a** developer,  
> **I want** the API keys page to display an expiry date for each key,  
> **so that** I can see when my keys will stop working.
>
> **Acceptance Criteria:**
> 1. The API keys list page displays the expiry date for each key.
> 2. The `api_keys` table includes an `expires_at` column populated by the backend migration.

**Single-Concept Cohesion verdict:** **FAIL** (mechanical)

Observed signals:
- Signal 1: Two distinct implementation concerns on the same API key management surface (display logic and data-model schema).
- Signal 2: AC #1 is the user-visible behavior (display); AC #2 is the enabling infrastructure change (schema migration), which the mechanical check flags as one behavior AC paired with one infrastructure AC in the same story.

Two signals observed. Quorum reached (≥ 2). **Mechanical FAIL.**

**Agile Coach overlay — intentional bundle:**

Atomicity test: does delivery require both ACs to ship together to avoid a broken intermediate state? Yes. AC #1 (UI display) depends on the `expires_at` column from AC #2. Shipping AC #1 without AC #2 produces a UI that references a non-existent column; shipping AC #2 without AC #1 produces a backend change with no user-visible outcome (fails the Vertical Slice principle). The two ACs are tightly coupled by delivery requirement, not coincidentally sharing a surface.

**Coach judgment: intentional bundle. Decline to split. Note the atomicity requirement in the story's Technical Notes.**

The Product Owner proceeds with a single story. The Technical Notes section records: "Backend migration (AC #2) and UI display (AC #1) must ship together; splitting creates a broken intermediate state or a no-outcome backend change."
