---
name: write-epic
description: "Write an epic specification with a problem statement, success criteria, and scope boundaries."
user-invokable: true
allowed-tools: Read, Grep, Glob
context: fork
argument-hint: "[epic title and description]"
---

# Write Epic

Write a complete epic specification with scope, success criteria, and scope boundaries.

## Input

`$ARGUMENTS` = epic title and high-level description of the initiative.

## Process

### 1. Handle Missing Input

If `$ARGUMENTS` is empty or contains no actionable description, prompt the user for the minimum information needed:

- **Epic title** — a concise name for the initiative.
- **Brief description** — what problem or opportunity does this epic address?

Do not proceed until the user has provided at least a title and a one-sentence description.

### 2. Gather Context

- Read the project's CLAUDE.md for architecture, conventions, and strategic context
- Scan for a roadmap or backlog file if one exists (Glob for roadmap*, backlog*, TODO*)
- Identify existing work that this epic relates to or depends on

### 3. Define the Epic

**Title**: Scoped and outcome-oriented.

- Good: "User Authentication — Email and OAuth Login"
- Bad: "Auth stuff" or "Sprint 4 work"

**Epic specification body**:

```
## Problem Statement
[1-2 sentences: What problem does this solve? Who is affected? What happens if
we do nothing?]

## Desired Outcome
[1-2 sentences: What does success look like when this epic is complete?]

## Success Metrics
- [Measurable indicator 1]
- [Measurable indicator 2]

## Scope

**In scope:**
- [Capability or deliverable that IS included]

**Out of scope:**
- [Capability explicitly excluded — prevents scope creep]

**Non-goals:**
- [Things this epic intentionally does NOT try to achieve]

## Dependencies and Risks
- **Depends on**: [other epics, services, decisions, or infrastructure]
- **Blocks**: [what downstream work is waiting on this epic]
- **Risks**: [technical unknowns, external dependencies, capacity concerns]
```

### 4. Validate the Epic

Check the overall epic before finalizing:

- [ ] **Right-sized**: spans multiple sprints but delivers value each sprint
- [ ] **Strategically aligned**: connects to a clear user or business need
- [ ] **Measurable**: success metrics are specific and verifiable
- [ ] **Scoped**: in-scope and out-of-scope are explicit — no ambiguity about boundaries

## Output

The markdown body MUST follow this exact section order with `##` headings:

1. `## Problem Statement`
2. `## Desired Outcome`
3. `## Success Metrics`
4. `## Scope`
5. `## Dependencies and Risks`

Additional rules:

- **Optional fields** (`dependencies`): omit entirely if empty. Never include blank bullets, "None", or placeholder text.

Print the markdown body. Example:

```markdown
## Problem Statement
[...]

## Desired Outcome
[...]

## Success Metrics
[...]

## Scope

**In scope:** [...]

**Out of scope:** [...]

**Non-goals:** [...]

## Dependencies and Risks
[...]
```
