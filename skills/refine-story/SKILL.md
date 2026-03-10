---
name: refine-story
description: "Score a story draft against INVEST criteria and seven agile coaching principles. Returns a structured report with pass/fail per dimension and specific rewrites for failures."
user-invokable: true
allowed-tools: Read, Grep, Glob
context: fork
argument-hint: "[paste the story draft or describe the story to review]"
---

# Refine Story

Score a story draft against INVEST criteria and seven agile coaching principles. Returns a structured report with pass/fail per dimension and specific rewrites for every failure.

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

Evaluate each of the seven principles with **PASS** or **FAIL**. For every FAIL, provide a specific issue and a suggested rewrite.

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

## Definition of Done

[PRESENT / MISSING — recommendation]

## Horizontal Work

[NONE / FLAGGED — reclassification recommendation if flagged]

## Summary

**X of 6 INVEST criteria passing. Y of 7 coaching principles passing.**

Priority fixes:
1. [Highest-impact issue and action]
2. [Second issue and action]
...
```

Omit sections that are not applicable (e.g., omit Horizontal Work if no flag was raised). Keep each explanation to 1-2 sentences. Rewrites should be concrete and ready to paste into the story.
