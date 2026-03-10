---
name: write-spike
description: "Produce a structured findings document for a topic too uncertain to story-write directly. Covers problem restatement, key questions, options considered, findings, remaining unknowns, and a story seed."
user-invokable: true
allowed-tools: Read, Grep, Glob, WebSearch, WebFetch
argument-hint: "[topic or question driving the investigation]"
context: fork
---

# Write Spike

Produce a structured findings document that resolves enough uncertainty to let the product owner write a well-formed user story.

## Input

`$ARGUMENTS` = the topic, question, or work area that is too uncertain to story-write directly.

## Process

### 1. Gather Context

- Read the project's CLAUDE.md for architecture, domain language, and constraints
- Scan for a roadmap or backlog file if one exists (Glob for roadmap*, backlog*, TODO*)
- Identify any existing work or decisions that bear on the topic

### 2. Scope the Investigation

State clearly:

- **The driving question**: What specific question does this spike need to answer? Narrow to one well-formed question if the input is broad.
- **Why now**: What decision or story is blocked until this question is answered?
- **Out of scope**: What related questions will be explicitly deferred?
- **Timebox**: State a recommended investigation timebox (typically 1-2 days for a focused spike). The spike should produce findings within this window even if not all questions are fully resolved — partial findings with identified follow-ups are better than an unbounded investigation.

A spike that tries to answer three questions usually answers none well.

### 3. Explore the Topic

Research the topic through whatever means are available:

- Read relevant source files if the topic is code or architecture
- Search for documentation, prior art, or established patterns (WebSearch / WebFetch)
- Enumerate options or approaches with concrete trade-offs — not just "Option A vs Option B" but specific pros, cons, and constraints for this project
- Note sources and links for evidence that will be referenced in the output

When options involve architectural trade-offs (one-way doors, pattern selection, service boundaries), note that the findings should be reviewed by the Chief Architect before being used to seed a story. The spike documents options; architectural judgment belongs to the Chief Architect.

### 4. Assess Story Readiness

Before producing output, evaluate:

- Can the driving question be answered with enough confidence to write a story?
- Are there remaining unknowns that would block story writing or cause the story to be poorly scoped?
- If unknowns remain, identify a concrete follow-up action for each (prototype, user interview, additional reading, architectural decision)

Classify the spike outcome:

- **Answered** — The driving question can be answered with confidence. Proceed to story writing.
- **Partially answered** — Key aspects are resolved but remaining unknowns need a follow-up spike or prototype.
- **Inconclusive** — The question cannot be answered with available information. Escalate or reframe.

State the classification in the output.

## Output

Print the findings document body. Example:

```markdown
## Problem Restatement

**Outcome:** Answered | Partially answered | Inconclusive
**Timebox:** [duration]

The mobile client needs to authenticate against the API, but it is unclear which approach fits the
constraints: no server-side session storage, short-lived tokens preferred, and support for
offline-first operation.

## Key Questions Explored

- Can OAuth2 work without a browser redirect in the mobile context?
- Does JWT satisfy the offline-first requirement without a token-refresh round-trip?
- What is the operational cost of rotating API keys vs. refreshing tokens?

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| OAuth2 (authorization code) | Industry standard, revocable | Requires browser redirect; complex for native clients |
| API key | Simple to implement | Long-lived; revocation requires key rotation; poor for multi-device |
| JWT (short-lived + refresh) | Stateless, offline-capable, revocable via refresh rotation | Refresh token storage adds complexity |

## Findings

JWT with short-lived access tokens and a rotating refresh token is the best fit. It satisfies
the offline-first constraint (access token valid for 15 minutes without network), avoids
browser redirects, and allows revocation by invalidating the refresh token. The operational
overhead of a refresh endpoint is justified by the security and UX benefits.

OAuth2 was ruled out because the authorization code flow requires a browser redirect — viable
for web but disruptive in a native mobile app. API keys were ruled out due to long-lived
credentials and no per-device revocation.

## Remaining Unknowns

- **Refresh token storage on device**: Where to securely store the refresh token on iOS and
  Android is not resolved. Follow-up: evaluate Keychain (iOS) and Keystore (Android) before
  implementing.

## Story Seed

Add JWT-based authentication to the mobile API client, using short-lived access tokens and a
rotating refresh token stored in platform-native secure storage.
```
