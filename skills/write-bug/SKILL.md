---
name: write-bug
description: "Scaffold a RIMGEN-validated bug report with reproduction steps, environment context, severity, and priority. Outputs named warnings for any missing or incomplete RIMGEN sections."
user-invokable: true
context: fork
argument-hint: "[description of the bug]"
---

# Write Bug

Scaffold a complete, RIMGEN-validated bug report ready to file as an issue or ticket.

## Input

`$ARGUMENTS` = description of the bug — what broke, what you were doing, what you expected.

## Process

### 1. Handle Missing Input

If `$ARGUMENTS` is empty or contains no actionable description, prompt the author for the minimum information needed to begin scaffolding. Present these questions in a single consolidated prompt:

- **What broke?** — Describe the failure in one sentence.
- **How do you reproduce it?** — What steps lead to the failure?
- **What did you expect to happen?** — The correct behavior.
- **What actually happened?** — The incorrect behavior you observed.
- **What is your environment?** — Version, OS, browser or runtime if applicable.
- **Who is affected?** — Just you, or specific configurations or all users?

Do not proceed to draft until the author has provided at least: a failure description, at least one reproduction step, and both expected and actual behaviors.

### 2. Assess RIMGEN Completeness

Before drafting, evaluate whether the input provides enough information across all six RIMGEN dimensions:

| Dimension | Sufficient when | Prompt if underspecified |
|-----------|----------------|--------------------------|
| **R — Reproducible** | Steps are present and specific enough to follow independently | "What are the exact steps to reproduce this?" |
| **I — Isolated** | A single, specific failure is described — not a cluster of related issues | "Is this one specific failure, or are there multiple separate issues to report?" |
| **M — Minimal** | The reproduction path is not bloated with unnecessary setup | No prompt needed — trim during drafting |
| **G — Generalizable** | Scope of impact is stated (all users? specific role? specific config?) | "Who else sees this — all users, or only in specific configurations?" |
| **E — Expected vs. Actual** | Both expected and actual behaviors are present and distinct | "What did you expect to happen?" and/or "What actually happened?" |
| **N — Necessary Context** | At least one environment detail is present (version, OS, or configuration) | "What version and environment are you running?" |

**Outcome paths:**

- **All sufficient** — proceed to Step 3 immediately. Do not prompt.
- **One or more underspecified** — present targeted questions for only the underspecified dimensions in a single consolidated prompt. Incorporate the answers, then proceed to Step 3.
- **No response (non-interactive context)** — infer reasonable answers from available project context (CLAUDE.md, codebase). Record each inference in the Notes section with the prefix "Inferred:" so the reporter can verify.

### 3. Draft the Bug Report

**Title**: Concise, describes the failure — not the fix. Prefer the format: `[Component] verb + symptom`.

- Good: "Payment form crashes on submit when amount field is empty"
- Bad: "Bug with payments" or "Payment issue"

Do not use "As a / I want / So that" framing. A bug title states what is broken.

**Severity** — the technical impact of the bug:

| Level | Definition |
|-------|-----------|
| **Critical** | Data loss, security vulnerability, system crash, or complete feature failure with no workaround |
| **High** | Major functionality broken for most users; workaround is awkward or unavailable |
| **Medium** | Functionality impaired; a reasonable workaround exists |
| **Low** | Minor issue, cosmetic defect, or edge-case behavior with easy mitigation |

**Priority** — the urgency of the fix:

| Level | Definition |
|-------|-----------|
| **P0** | Fix immediately; ship a hotfix regardless of sprint cycle |
| **P1** | Fix in the current sprint; cannot close sprint without resolution |
| **P2** | Fix in the next sprint |
| **P3** | Fix when bandwidth allows; no time pressure |

If severity or priority cannot be determined from context, emit a warning using the format defined in Step 4 and leave a `[AUTHOR: specify]` placeholder.

**Reproduction steps** — critical formatting rules:

- Each step is numbered.
- Each step describes exactly one action.
- No compound instructions joined by "and" or "then" within a single step.
  - Bad: "Click Submit and wait for the error message"
  - Good: Step N: "Click Submit." / Step N+1: "Observe the error message."
- Steps are the minimal path to trigger the failure — exclude setup steps not relevant to reproducing the bug.

### 4. RIMGEN Validation

After drafting, validate each dimension. For any dimension that is absent, blank, contains only a placeholder (e.g., "TBD", "N/A" with no further detail), or fails its criterion, emit a named warning **before** the report output.

This warning format applies to both RIMGEN dimensional failures and the severity/priority placeholder case from Step 3:

```
⚠ RIMGEN Warning — [Dimension Name]: [One sentence describing what is missing or insufficient and what the author should add.]
```

**Validation criteria:**

- **R — Reproducible**: At least one numbered step exists. Each step describes exactly one action with no "and" or "then" compound instructions. Steps are specific enough for an independent reporter to follow.
- **I — Isolated**: The report describes exactly one failure mode. Flag if the summary or steps describe multiple distinct failures.
- **M — Minimal**: No unnecessary preamble or setup steps that do not contribute to triggering the failure. Flag if steps include obvious environment setup that a developer would perform by default.
- **G — Generalizable**: The scope of impact section is present and states more than "unknown." At minimum it identifies whether the issue is user-specific, role-specific, configuration-specific, or universal.
- **E — Expected vs. Actual**: Both "Expected Behavior" and "Actual Behavior" sections are present, non-empty, and distinct from each other. Flag if they are identical, near-identical, or if one is missing.
- **N — Necessary Context**: The environment section contains at least one concrete detail (version number, OS, browser, or configuration key). "Unknown" alone does not satisfy this dimension.

Do not block output for warnings. Present all warnings first, then present the complete report.

### 5. Final Quality Check

Before presenting the output, verify:

- [ ] Title describes the failure, not the fix
- [ ] Title does not use "As a / I want / So that" framing
- [ ] Severity and priority are distinct labeled fields with their definitions noted
- [ ] Each reproduction step is numbered and describes exactly one action
- [ ] No compound instructions in reproduction steps
- [ ] Expected and actual behaviors are clearly distinct from each other
- [ ] Scope of impact is stated (even if approximate)
- [ ] At least one environment detail is present
- [ ] All applicable RIMGEN warnings were emitted before the report

## Output

Present any warnings first, then the bug report body.

```markdown
## Summary

[One-sentence description of the failure]

**Severity:** High — Major functionality broken; workaround unavailable
**Priority:** P1 — Fix in the current sprint

## Reproduction Steps

1. Navigate to the payment form at /checkout
2. Leave the amount field empty
3. Click the Submit button

## Expected Behavior

The form displays a validation error indicating the amount field is required.

## Actual Behavior

The page crashes with an unhandled exception and the user loses their cart.

## Scope of Impact

All users who attempt to submit the payment form without entering an amount.
Reproducible in Chrome 122, Firefox 123, and Safari 17.

## Environment & Context

- **Version**: 2.4.1
- **OS**: macOS 14.3
- **Browser**: Chrome 122

## Notes

[Additional context, links to logs, screenshots, related issues]
```
