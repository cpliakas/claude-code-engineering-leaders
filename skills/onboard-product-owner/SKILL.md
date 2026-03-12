---
name: onboard-product-owner
description: "Use when configuring the Product Owner agent for a specific project. Gathers issue tracker details, backlog norms, and current roadmap state, then writes them to the Product Owner's project memory. Run /onboard first to establish shared project context. This is the reference implementation for per-agent onboarding skills."
user-invokable: true
allowed-tools: Read, Glob, Write
context: fork
---

# Onboard — Product Owner

Configure the Product Owner agent for your project by capturing issue tracker
details, backlog norms, and current roadmap state.

## Prerequisites

This skill layers on top of shared project context. Before starting, read:

```
.claude/agent-memory/engineering-leaders/PROJECT.md
```

If the file does not exist, note:

> "Shared project context hasn't been set up yet. I can continue with
> Product Owner-specific questions, but running /onboard first will give all
> agents a better foundation. Would you like to continue anyway?"

Respect the user's choice.

## Output Location

Product Owner project memory is written to:

```
.claude/agent-memory/engineering-leaders-product-owner/MEMORY.md
```

If this file already exists, show the user a summary of what is recorded and
ask whether to update specific sections or start fresh.

## Process

Introduce yourself before asking anything:

> "I'll ask you a few questions about how your team tracks and manages work —
> one at a time. This gives the Product Owner agent the context it needs to
> advise on sequencing, write well-structured stories, and track your roadmap.
> Skip any question with 'skip' or 'not sure yet'."

### Issue Tracker

**Q1 — Issue tracker platform**

> "Which issue tracker does your team use?
>
> (a) GitHub Issues
> (b) Jira
> (c) Linear
> (d) Notion
> (e) Other — I'll describe it
> (f) None / we don't use one"

**Q2 — Project or board URL**

> "What's the URL for your project board or repository? (e.g.,
> `https://github.com/org/repo` or `https://linear.app/team/project`)"

Skip this question if the user answered (f) above.

**Q3 — Issue structure**

> "How are work items organized in your tracker? For example: do you use epics,
> labels, milestones, sprints, or story points? Describe what you actually use."

### Roadmap and Phases

**Q4 — Current phase or milestone**

> "What is the team focused on right now? Is there a named phase, milestone, or
> goal you're working toward?"

**Q5 — Immediate priorities**

> "What are the top 2–3 things the team is trying to ship or complete in the
> near term?"

**Q6 — Known blockers or risks**

> "Are there any known blockers, open decisions, or risks that could affect
> sequencing? (Skip if none)"

### Team Norms

**Q7 — Story sizing convention**

> "How does your team size or estimate work items?
>
> (a) T-shirt sizes (XS/S/M/L/XL)
> (b) Story points (Fibonacci or similar)
> (c) Days / hours
> (d) Just small/medium/large
> (e) We don't size work items"

**Q8 — Definition of Done**

> "What does 'done' mean on your team? Are there specific criteria a story must
> meet before it's closed? (e.g., code reviewed, tests passing, deployed to
> staging, acceptance tested)"

**Q9 — Anything else**

> "Is there anything else the Product Owner should know about how your team
> works — norms, constraints, or preferences that aren't captured above?
> (Skip if nothing comes to mind)"

### Write Product Owner Memory

After collecting answers, write the memory file. Use the structure below,
omitting sections where the user skipped or had nothing to say.

```markdown
# Product Owner — Project Memory

> Configured by /onboard-product-owner. Update by re-running the skill or
> editing this file directly.

## Issue Tracker

- **Platform:** [from Q1]
- **Project URL:** [from Q2, if provided]
- **Issue Structure:** [from Q3]

## Current Roadmap State

- **Current Phase / Milestone:** [from Q4]
- **Immediate Priorities:** [from Q5 — bullet list]
- **Known Blockers / Risks:** [from Q6, if provided]

## Team Norms

- **Story Sizing:** [from Q7]
- **Definition of Done:** [from Q8]
- **Other Norms:** [from Q9, if provided]

## Shared Project Context

See `.claude/agent-memory/engineering-leaders/PROJECT.md` for project
overview, tech stack, team structure, and SDLC process.
```

Create the directory `.claude/agent-memory/engineering-leaders-product-owner/`
if it does not exist, then write the file.

### Confirmation

Present a confirmation summary:

```
Product Owner configured.

Memory written to:
  .claude/agent-memory/engineering-leaders-product-owner/MEMORY.md

The Product Owner now knows:
  - Issue tracker: [platform] at [url or "not specified"]
  - Current focus: [phase/milestone]
  - Sizing: [convention]
  - DoD: [summary or "not specified"]

The Product Owner agent is ready. Invoke it by saying "consult the product
owner" or asking about roadmap, sequencing, or story authoring.
```
