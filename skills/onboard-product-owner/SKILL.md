---
name: onboard-product-owner
description: "Use when configuring the Product Owner agent for a specific project. Gathers issue tracker details, backlog norms, and current roadmap state, then writes them to the Product Owner's project memory. Run /onboard first to establish shared project context. This is the reference implementation for per-agent onboarding skills."
user-invokable: true
argument-hint: ""
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

Track whether this file exists as `shared_context_exists`. If it **does not
exist**, note:

> "Shared project context hasn't been set up yet. I can continue with
> Product Owner-specific questions, but running /onboard first will give all
> agents a better foundation. Would you like to continue anyway?"

Respect the user's choice.

## Output Location

Product Owner project memory is written to:

```
.claude/agent-memory/engineering-leaders-product-owner/MEMORY.md
```

If this file **already exists**, show the user a brief summary of what is
recorded (issue tracker platform, current phase, sizing convention) and ask:

> "Product Owner memory already exists. Would you like to:
>
> (a) Update specific sections — I'll ask which sections to replace and re-run
>     only those questions. All other sections are preserved unchanged.
> (b) Start fresh — I'll run the full interview and replace the entire file
>     when complete. If you abandon the interview before finishing, the original
>     file is left unchanged."

**If the user chooses (a):**

Show the list of sections (Issue Tracker, Roadmap and Phases, Team Norms) and
ask which to update. Re-ask only the questions for those sections (Q1-Q3 for
Issue Tracker, Q4-Q6 for Roadmap and Phases, Q7-Q9 for Team Norms), then merge
the new answers into the existing file by replacing only those sections.
Sections not selected are preserved verbatim from the original.

**If the user chooses (b):**

Proceed through the full interview below. Write the file only after all
questions are answered. If the user abandons before completing, do not write
anything and tell the user: "Interview not completed. The original file is
unchanged."

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

After collecting all answers, write the memory file. Use the structure below,
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
```

If `shared_context_exists = true`, append this section to the file:

```markdown
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
  - Issue tracker: [platform from Q1] at [url from Q2, or "not specified"]
  - Current focus: [phase/milestone from Q4]
  - Top priorities: [first item from Q5, or "see memory"]
  - Sizing: [convention from Q7]
  - DoD: [one-line summary from Q8, or "not specified"]

The Product Owner agent is ready. Invoke it by saying "consult the product
owner" or asking about roadmap, sequencing, or story authoring.
```
