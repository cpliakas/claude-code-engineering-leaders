---
name: onboard
description: "Use when setting up the engineering-leaders plugin for the first time on a project, or when re-running onboarding to update shared project context. Gathers shared project context for all agents (one question at a time) and discovers specialist plugins for the Tech Lead routing table. Run this before per-agent onboarding skills like /onboard-product-owner."
user-invokable: true
argument-hint: ""
allowed-tools: Read, Glob, Grep, Write, Bash
context: fork
---

# Onboard

Gather shared project context for all engineering-leaders agents and discover
specialist plugins for the Tech Lead routing table.

This skill runs a guided interview. It asks one question at a time and writes
the results to a shared memory file that every agent in this plugin reads.

## Output Location

Shared context is written to:

```
.claude/agent-memory/engineering-leaders/PROJECT.md
```

Specialist routing entries are written to:

```
.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md
```

## Process

### Step 1: Check for Existing Context

Read `.claude/agent-memory/engineering-leaders/PROJECT.md` if it exists.

If it **does not exist**, proceed directly to Step 2. Track: `context_written = false`.

If it **exists**, show the user a brief summary of what is recorded (project
name, tech stack, current phase) and ask:

> "Shared project context already exists. Would you like to:
>
> (a) Update specific sections — I'll ask which sections to replace and re-run
>     only those questions. All other sections are preserved unchanged.
> (b) Start fresh — I'll run the full interview and replace the entire file
>     when complete. If you abandon the interview before finishing, the original
>     file is left unchanged.
> (c) Skip to specialist discovery — skip the project context interview and go
>     straight to updating the Tech Lead routing table."

**If the user chooses (a):**

Show the list of sections in the existing file (Project Overview, Tech Stack,
Team, Key Constraints) and ask: "Which sections would you like to update?"
Re-ask only the questions that correspond to the sections they name (Q1, Q2,
and Q6 for Project Overview; Q3 for Tech Stack; Q4 and Q5 for Team; Q7 for
Key Constraints), then merge the new answers into the existing file by
replacing only those sections. Sections not selected are preserved verbatim
from the original. Any content in the file that does not correspond to a
template section (e.g., manually added sections) must also be preserved
verbatim — do not discard unrecognized content. Write the merged file and
track: `context_written = true`.

**If the user chooses (b):**

Proceed to Step 2. Write the file only after the full interview completes in
Step 3. The interview is considered abandoned if the user explicitly says to
stop (e.g., "stop", "cancel", "never mind", "let's come back to this") or
leaves the conversation without completing Step 3. If abandoned, do not write
anything and tell the user: "Interview not completed. The original file is
unchanged." Track: `context_written = true` only if the file was actually
written.

**If the user chooses (c):**

Skip Steps 2 and 3. Jump directly to Step 4. Track: `context_written = false`.

### Step 2: Project Overview Interview

Introduce yourself before asking anything:

> "I'll ask you a few questions about your project — one at a time — so the
> engineering-leaders agents have the context they need to give you useful
> advice. You can skip any question by saying 'skip' or 'not sure yet'."

Then ask these questions, **one at a time**, waiting for the answer before
asking the next. Use multiple-choice options where shown.

**Q1 — Project name and description**

> "What is this project? Give me a one or two sentence description of what it
> does and who uses it."

**Q2 — Business domain**

> "Which domain best describes this project?
>
> (a) Developer tools / infrastructure
> (b) SaaS / B2B software
> (c) Consumer / B2C product
> (d) Internal tooling / platform
> (e) Data / analytics / ML platform
> (f) Other — I'll describe it"

**Q3 — Tech stack**

> "What languages, frameworks, and key infrastructure does this project use?
> (e.g., 'Python/FastAPI, React, PostgreSQL, deployed on AWS')"

**Q4 — Team structure**

> "How would you describe the team?
>
> (a) Solo / just me
> (b) Small team (2–5 engineers)
> (c) Mid-size team (6–15 engineers)
> (d) Larger team (15+ engineers)"

Follow up with: "Any specific disciplines on the team I should know about?
(e.g., dedicated QA, platform/SRE, design)" — only if they answered (b), (c),
or (d).

**Q5 — SDLC process**

> "How does the team manage and deliver work?
>
> (a) Scrum with regular sprints
> (b) Kanban / continuous flow
> (c) Ad hoc / no formal process
> (d) Other — I'll describe it"

If (a): "What's the sprint cadence? (1 week, 2 weeks, other)"

**Q6 — Current project phase**

> "Where is the project right now?
>
> (a) Pre-launch / building toward MVP
> (b) Early product / recently launched, iterating fast
> (c) Growth / scaling features and team
> (d) Mature / maintenance and incremental improvement
> (e) In transition — I'll describe it"

**Q7 — Key constraints**

> "Are there any constraints the agents should always keep in mind? For example:
> compliance requirements, performance targets, architectural boundaries, or
> things the team has decided not to do.
>
> (Skip if nothing significant comes to mind)"

### Step 3: Write Shared Context

After collecting all answers, write the following file. Omit any section where
the user skipped or had nothing to say.

```markdown
# Project Context

> Generated by /onboard. Update by re-running /onboard or editing this file.

## Project Overview

- **Name:** [from Q1]
- **Description:** [from Q1]
- **Business Domain:** [from Q2]
- **Current Phase:** [from Q6]

## Tech Stack

[from Q3 — use bullet points if multiple items]

## Team

- **Size:** [from Q4]
- **Structure / Disciplines:** [from Q4 follow-up, if provided]
- **SDLC Process:** [from Q5]
- **Sprint Cadence:** [from Q5 follow-up, if scrum]

## Key Constraints

[from Q7, or omit section if skipped]
```

Create the directory `.claude/agent-memory/engineering-leaders/` if it does
not exist, then write the file. Track: `context_written = true`.

### Step 4: Specialist Discovery

Transition with:

> "Now let's set up the Tech Lead's routing table. This tells the Tech Lead
> which specialist agents to consult during implementation planning, incident
> analysis, and retrospectives."

**Q8 — Installed specialist agents**

> "Do you have any specialist agents installed that the Tech Lead should know
> about? These might come from other plugins (e.g., a backend-developer,
> terraform-engineer, security-specialist, react-specialist).
>
> List any agent names you'd like to register, or say 'none' to skip."

If none or skip: note that specialists can be added later with `/add-specialist`
and move to Step 5.

If agents are listed, for **each agent**, ask:

> "What code areas or topics should route work to `[agent-name]`? You can use
> file paths (e.g., `src/api/**`), technology keywords (e.g., `terraform`), or
> concern keywords (e.g., `authentication`). List as many as useful."

After collecting signals for all agents, invoke `/add-specialist` for each one:

```
/add-specialist [agent-name] [signal-1] [signal-2] ...
```

**Note:** `/add-specialist` will verify that `agents/<agent-name>.md` exists in
the current project. If the named agent comes from another plugin and is not in
the local `agents/` directory, it will pause and ask for confirmation. Answer
"yes" to register the specialist anyway.

Track results for each invocation:

- If `/add-specialist` completes successfully: mark the specialist as **registered**.
- If it does not complete (validation rejected or user cancelled): mark the
  specialist as **failed** and continue processing remaining specialists.

### Step 5: Summary and Next Steps

Present a summary based on what actually happened in this run.

**Shared context:**

- If `context_written = true`: "Shared context written to:
  `.claude/agent-memory/engineering-leaders/PROJECT.md`"
- If `context_written = false`: "Shared context: unchanged (existing file
  retained, or skipped this run)"

**Specialists:**

- If all registrations succeeded: "Specialists registered: [N]"
- If some failed (including if all failed):

  ```
  Specialists: [N succeeded of N total requested] registered

  Failed registrations — complete these manually with /add-specialist:
    - [agent-name]: [reason — not found, cancelled, etc.]
  ```

- If none were requested: "Specialists: none registered. Add later with
  `/add-specialist`."

**Next steps:**

The following per-agent onboarding skills are available in this plugin:

```
/onboard-product-owner   — configure the Product Owner for your issue
                           tracker, backlog norms, and current phase
```
