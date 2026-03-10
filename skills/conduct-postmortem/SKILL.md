---
name: conduct-postmortem
description: >
  Conduct a blameless postmortem for an incident or failed/aborted release.
  Collects evidence and produces a structured postmortem document. Use when
  the user invokes /conduct-postmortem,
  says "postmortem", "incident retrospective", "release blocked", or describes a
  production incident or release failure that needs a postmortem document.
user-invokable: true
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "<incident description>"
context: fork
---

# Conduct Postmortem

Conduct a blameless incident postmortem for the incident described in
`$ARGUMENTS`. Collect evidence and produce a structured postmortem document.

## Step 1 — Collect Available Evidence

If `$ARGUMENTS` is empty and there is no incident context in the current session,
ask the user to describe the incident before proceeding. Do not continue until
an incident description is provided.

Scan the current session context for:

- Error messages and stack traces
- Failed commands and their output
- Observed behaviors and timeline events
- Services and components involved

Read the incident description from `$ARGUMENTS`. If key facts are missing to
populate the timeline and impact section, prompt the developer for them before
proceeding:

- **Severity:** What was the user-facing or operational impact? (SEV-1 through SEV-4)
- **Date/time:** When did the incident occur (or when was it discovered)?
- **Duration:** How long until resolution?
- **Services involved:** Which components were affected?
- **Impact metrics:** Users affected, events disrupted, revenue lost, SLA violations?

Do not proceed to Step 2 until enough information exists to produce a credible
timeline and quantified impact section.

## Step 2 — Determine the Next POST ID

Check the DevOps Lead's project memory
(`.claude/agent-memory/engineering-leaders-devops-lead/MEMORY.md`) for a
configured postmortem directory path and ID format.

If a directory is configured:

1. Read the index file (typically `README.md`) in that directory
2. Find the highest `POST-NNN` number in the index table
3. Set the next ID to that number + 1, zero-padded to 3 digits

If no directory is configured:

1. Generate the postmortem document as output only (do not write to disk)
2. Note in the output that the DevOps Lead's memory can be configured with a
   `postmortem_directory` path to enable automatic filing

The output filename convention is: `POST-NNN-YYYY-MM-DD-<slug>.md`

Where `<slug>` is a short, hyphenated description of the incident (e.g.,
`migration-chain-failure`, `api-startup-crash`, `feed-parse-regression`).

## Step 3 — Gather Specialist Input

Consult the `tech-lead` agent to identify which domain specialists should
contribute to the incident analysis. Provide the Tech Lead with the incident
description and the affected systems identified in Step 1.

The Tech Lead will:

1. Map affected systems to its Specialist Routing Table
2. Spawn sub-agent consultations with relevant specialists
3. Return domain-specific contributing factors, convention violations, and
   systemic improvement recommendations

Incorporate the specialist input into the analysis in Step 4. If the Tech Lead's
routing table is not yet configured for this project, skip this step and note
that specialist input was not gathered.

## Step 4 — Analyze the Incident

Assess the incident from an operational perspective, incorporating any specialist
input from Step 3:

- Operational patterns and systemic gaps revealed by the incident
- Detection and observability failures (what monitoring was absent or insufficient?)
- CI/CD pipeline gaps (what validation step would have caught this earlier?)
- Convention gaps identified by specialist consultations
- Maturity improvements to recommend as action items
- Runbook additions or updates needed

If the incident has architectural implications (one-way-door decisions, forward-
compatibility risks, ADR candidates), note them in the action items and
recommend consulting the Chief Architect as a follow-up.

## Step 5 — Write the Postmortem Document

Produce the full 13-section postmortem document. Incorporate all findings from
Steps 3 and 4.

**Blameless language rules (non-negotiable):**

- Never name an individual as a causal subject. Abstract to "the responding
  engineer", "the team", or "the deployment pipeline" when describing human
  actions.
- Use "contributing factors" — never "root cause" (implies a single cause and
  invites blame).
- Use "what" and "how" questions in analysis. Never "who" or "why" in a
  blame-seeking frame.
- When describing a human action that contributed to the incident, always
  explain why it made sense at the time given the information available.
- No emotional or animated language, no subjective judgments, no exclamation
  marks.

**Quality criteria (every section must meet these):**

- Every impact claim has a number (no vague language like "some users affected").
- Contributing factor analysis goes at least three levels deep.
- Action items are balanced: near-term fixes AND systemic improvements.
- At least one action item is P0 or P1.
- The "Where we got lucky" subsection is non-empty.
- The document could be understood by someone outside the immediate team.

**Required document structure:**

```markdown
# Postmortem: <title>

| Field | Value |
|-------|-------|
| **POST-ID** | POST-NNN |
| **Date of incident** | YYYY-MM-DD |
| **Date of postmortem** | YYYY-MM-DD |
| **Author** | <name> (assisted by Claude Code) |
| **Status** | Draft |
| **Severity** | SEV-N — <short description> |

---

## Executive Summary

<1-3 sentences. What happened, severity, duration, impact. Write last.
CEO-readable.>

---

## Impact

| Metric | Value |
|--------|-------|
| <metric> | <quantified value> |

---

## Timeline

All times UTC, YYYY-MM-DD.

| Time | Event |
|------|-------|
| ~HH:MM | <event> |

---

## Detection

<How discovered. Time-to-detection. How could detection have been faster?>

---

## Contributing Factors

### Factor 1 — <title>

<Multi-level causal analysis. Systems-focused. Explain why it made sense at
the time.>

### Factor N — <title>

...

---

## Resolution

| Bug/Issue | Immediate Fix | Commit/PR | Systemic Fix |
|-----------|---------------|-----------|--------------|

<Narrative of resolution steps.>

---

## Lessons Learned

### What went well

<Processes and actions that worked as intended. Reinforce good practices.>

### What went wrong

<Processes, tools, or conditions that contributed to the incident.>

### Where we got lucky

<Near-misses and fortunate coincidences. Surface hidden risks.>

---

## Action Items

| # | Action | Type | Priority | Status | Resolution |
|---|--------|------|----------|--------|------------|
| 1 | <verb-led, specific, bounded> | Prevent/Detect/Mitigate/Investigate/Process | P0-P3 | Open | — |

Types: **Prevent** (stop recurrence), **Detect** (catch earlier),
**Mitigate** (reduce blast radius), **Investigate** (understand further),
**Process** (workflow/culture change).

---

## Backlog Check

<Was there existing work that could have prevented this? Prior decisions
that set up the conditions?>

---

## Recurrence Check

<Have past incidents shared these contributing factors? If so, why did the
problem recur?>

---

## Follow-Up Actions Taken

<Populated after the postmortem review meeting. Empty at draft time.>

---

## Supporting Information

- **PR/Commit:** <link>
- **Issue:** <link>
- **Related postmortem:** <link if applicable>
```

## Step 6 — File the Document (if configured)

If a postmortem directory was found in Step 2:

1. Write the postmortem to `<directory>/POST-NNN-YYYY-MM-DD-<slug>.md`
2. Update the index table in `<directory>/README.md` by appending a new row:

```markdown
| [POST-NNN](POST-NNN-YYYY-MM-DD-<slug>.md) | YYYY-MM-DD | <title> | SEV-N |
```

If no directory is configured, display the document as output and remind the
user:

> To enable automatic filing, add a `postmortem_directory` entry to the DevOps
> Lead's project memory
> (`.claude/agent-memory/engineering-leaders-devops-lead/MEMORY.md`) with the
> path where postmortem documents should be stored.

## Step 7 — Recommend Follow-Up Actions

For each action item in the Action Items table, recommend whether it should be
filed as an issue in the project's issue tracker. Present the recommendations
for human approval — do not create issues automatically.

For each recommended issue, provide:

- **Title:** Verb-led action item title
- **Body:**

```markdown
**Postmortem:** POST-NNN — <postmortem title>
**Category:** <Prevent | Detect | Mitigate | Investigate | Process>

## Context

<1-2 sentences explaining why this action item was identified.>

## Acceptance Criteria

- [ ] <specific, testable criterion>
- [ ] <specific, testable criterion>
```
