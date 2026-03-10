---
name: decompose-requirement
description: "Decompose a requirement into well-sequenced child items. Takes an epic and produces stories, or takes a story and produces subtasks."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob
argument-hint: "[requirement title/description to decompose]"
---

# Decompose Requirement

Break a requirement into sequenced child items.

## Input

`$ARGUMENTS` = title or description of the requirement to decompose.

## Process

### 1. Handle Missing Input

If `$ARGUMENTS` is empty or contains no actionable description, prompt the user for the requirement to decompose. Present a single consolidated prompt:

- **What requirement needs decomposition?** — Paste the epic, story, or describe the requirement in a few sentences.

Do not proceed until the user has provided a requirement description.

### 2. Gather Context

- Read the project's CLAUDE.md for architecture, conventions, and domain context
- Scan for a roadmap or backlog file if one exists (Glob for roadmap*, backlog*, TODO*)
- Understand the domain well enough to identify meaningful vertical slices

### 3. Parse the Input

Determine the decomposition level:

- If the input describes an **epic-level scope** → decompose into **stories** (5-15 children)
- If the input describes a **story-level scope** → decompose into **subtasks/tasks** (2-8 children)
- If ambiguous, ask the user or infer from scope signals (breadth of outcomes, number of user roles involved, estimated delivery span)

### 4. Apply Decomposition Strategy

Use **vertical slicing** (mandatory) — each child delivers a thin, user-visible slice of functionality across all layers. Pick the best-fit strategy:

- **Workflow steps**: One child per step in a user workflow
- **Business rules**: One child per rule variation
- **User roles**: One child per role's interaction with the feature
- **CRUD**: One child per operation (when each has distinct value)
- **Happy path first**: Core flow as child 1, then edge cases and error handling

Explicitly avoid horizontal slicing (e.g., "build the database layer", "build the API", "build the UI") — these produce children with no standalone user value.

### 5. Sequence the Children

Order by priority, applying these criteria in order:

1. **Dependencies** — what must exist before other children can start?
2. **Risk** — what has the most technical uncertainty? Do it early.
3. **Value** — front-load children that deliver user-visible value.
4. **Learning** — children that resolve unknowns enable better estimates for later ones.

### 6. Produce Structured Output

For each child, produce a brief markdown body with:

- User story statement
- 2-4 acceptance criteria as `- [ ]` checkboxes

These are **outlines, not full specifications**. The user can run `/write-story` on individual items for full INVEST validation and detail.

### 7. Validate the Decomposition

- [ ] Each child is independently deliverable
- [ ] Each child has standalone user value (for stories) or is a clear action (for subtasks)
- [ ] Stories fit within a single sprint; subtasks fit within a day
- [ ] Total count is appropriate: 5-15 for epic→story, 2-8 for story→subtask
- [ ] No horizontal slicing — every child touches the full stack where relevant
- [ ] Dependencies are explicit and the sequence is logical
- [ ] First child is actionable with no blockers

## Output

Each child's markdown body MUST use `###` headings in this order:

1. `### User Story`
2. `### Acceptance Criteria`

Optional fields: omit entirely if empty. Never include blank bullets or placeholder text.

A summary table first, then individual child specs.

```
## Decomposition Summary

**Parent**: [input requirement title]
**Level**: epic → stories | story → subtasks
**Children**: N items

| # | Title | Type | Size | Depends On | Parallel With |
|---|-------|------|------|------------|---------------|
| 1 | Title | story | S | — | — |
| 2 | Title | story | M | #1 | — |
| 3 | Title | story | S | — | #2 |

---

## Child 1

### User Story

As a [role], I want [capability], so that [benefit].

### Acceptance Criteria

- [ ] Given X, when Y, then Z
- [ ] ...

---

## Child 2

[... same pattern ...]
```
