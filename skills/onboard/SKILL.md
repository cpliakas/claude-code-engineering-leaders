---
name: onboard
description: "Use when setting up the engineering-leaders plugin for the first time on a project, or when re-running onboarding to update shared project context. Gathers shared project context for all agents (one question at a time) and discovers specialist plugins for the Tech Lead to consult. Run this before per-agent onboarding skills like /onboard-product-owner."
user-invokable: true
argument-hint: ""
allowed-tools: Read, Glob, Grep, Write, Bash
context: fork
---

# Onboard

Gather shared project context for all engineering-leaders agents and discover
specialist plugins for the Tech Lead to consult.

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

Per-project agent model overrides (written only when the user selects a
non-default trade-off during the Model Selection step) are written to:

```
.claude/agents/<agent-name>.md
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
>     straight to updating the Tech Lead specialist registry."

**If the user chooses (a):**

Show the list of sections in the existing file (Project Overview, Tech Stack,
Team, Key Constraints, Specialists, Model Selection) and ask: "Which sections
would you like to update?" Re-ask only the questions that correspond to the
sections they name (Q1, Q2, and Q6 for Project Overview; Q3 for Tech Stack;
Q4 and Q5 for Team; Q7 for Key Constraints; Step 4 for Specialists; Step 5
for Model Selection), then merge the new answers into the existing file by
replacing only those sections. Sections not selected are preserved verbatim
from the original. Any content in the file that does not correspond to a
template section (e.g., manually added sections) must also be preserved
verbatim — do not discard unrecognized content.

For the Specialists section, run Step 4 (Specialist Discovery) and update the
`## Registered Specialists` and `## Project Code Area Overrides` sections in
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md` accordingly.

Write the merged file and track: `context_written = true`.

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

> "Now let's register any specialist agents the Tech Lead should know about.
> Specialists are consulted during implementation planning, incident analysis,
> and retrospectives. The Tech Lead will match issues to specialists based on
> each agent's own description — you only need to name the agents."

**Q8 — Installed specialist agents**

> "Do you have any specialist agents installed that the Tech Lead should know
> about? These might come from other plugins (e.g., a backend-developer,
> terraform-engineer, security-specialist, react-specialist).
>
> List any agent names you'd like to register, or say 'none' to skip."

If none or skip: note that specialists can be added later with `/add-specialist`
and move to Step 5.

If agents are listed, invoke `/add-specialist` for each one with the agent name
only:

```
/add-specialist [agent-name]
```

Trigger keywords and file globs are not collected here. Users who want
project-local code-area overrides can add them after onboarding with:

```
/add-specialist [agent-name] "src/example/**"
```

**Note:** `/add-specialist` will verify that `agents/<agent-name>.md` exists in
the current project. If the named agent comes from another plugin and is not in
the local `agents/` directory, it will pause and ask for confirmation. Answer
"yes" to register the specialist anyway.

Track results for each invocation:

- If `/add-specialist` completes successfully: mark the specialist as **registered**.
- If it does not complete (validation rejected or user cancelled): mark the
  specialist as **failed** and continue processing remaining specialists.

### Step 5: Model Selection

<!-- OVERRIDE MECHANISM NOTE
  Claude Code loads agent definitions from `.claude/agents/<agent-name>.md` in
  the project directory with precedence over same-named agents from installed
  plugins. This is the project-local agent customization path: if a file at
  `.claude/agents/tech-lead.md` exists, Claude Code uses it instead of the
  plugin-supplied `agents/tech-lead.md`. If Anthropic formally documents this
  path, link that documentation here so future maintainers can verify it.

  If you observe that override files written by this step are NOT taking effect
  (i.e., the plugin's shipped default model is still used after the override
  file is written), the fallback path in this step emits manual frontmatter
  edit instructions instead of writing files. See the VERIFICATION FAILURE
  FALLBACK section below.
-->

<!-- TRADE-OFF-TO-MODEL MAPPING TABLE
  This table maps the user-facing trade-off labels to concrete model IDs.
  Update this table when Anthropic ships new models or renames existing ones.
  Do NOT expose these model names to the user in question text.

  | Agent          | Plugin default  | "Faster and lower cost" | "Higher-quality planning" |
  |----------------|-----------------|-------------------------|---------------------------|
  | tech-lead      | sonnet          | haiku                   | opus                      |
  | chief-architect| opus            | sonnet                  | opus (same as default)    |
  | product-owner  | opus            | sonnet                  | opus (same as default)    |

  Concrete model IDs (as of plugin authoring; update as catalog evolves):
  - haiku  → claude-haiku-4-5-20251001  (date-stamped format; check for a non-dated alias)
  - sonnet → claude-sonnet-4-6
  - opus   → claude-opus-4-7

  For "higher-quality planning" where the agent already defaults to opus,
  selecting this option is equivalent to "default": no override file is
  written for that agent.
-->

Transition to this step after Specialist Discovery completes.

Ask the following preamble question **first**, and do not ask anything else
until the user answers:

> "Would you like to configure the model bias for key agents (Tech Lead,
> Chief Architect, and Product Owner)? I'll ask one question per agent using
> trade-off terms (faster and lower cost vs. higher-quality planning). You
> can skip any individual agent or skip the whole step.
>
> (a) Yes: walk me through the per-agent questions
> (b) No: keep the plugin defaults, skip this step"

**If the user answers (b) or skips:** Track `model_selection_skipped = true`.
Write no files. Proceed to Step 6.

**If the user answers (a):** Track `model_selection_skipped = false`.
Proceed through the per-agent questions below, one at a time.

#### Per-agent question: Tech Lead

Check whether `.claude/agents/tech-lead.md` already exists in the project.

**If the file exists:** Read the first five lines to determine whether it is a
previously generated override (look for the `<!-- Generated by /onboard` marker):

- If it is a generated override, check whether the file hash in the header
  still matches the current plugin agent file (see HASH COMPUTATION below).
  - If the hashes **match**, present the existing trade-off label and ask:
    "Tech Lead already has an override (no drift detected). Keep it or
    replace it with a fresh override?
    (a) Keep existing  (b) Replace with a new choice"
  - If the hashes **differ**, show the user:
    "Tech Lead's plugin file has changed since the override was generated.
    Would you like to: (a) Regenerate the override (your previous choice will
    be prompted again)  (b) Keep the current override as-is (accepting drift)"
    If the user chooses (b), update the `File hash:` field in the override
    file's header to the current plugin file hash so the drift prompt does
    not re-fire on the next `/onboard` run.
- If it is NOT a generated override (hand-written or from another source),
  show the user: "A `.claude/agents/tech-lead.md` file already exists and was
  not generated by /onboard. Replace it with a generated override, or leave
  it unchanged?  (a) Replace  (b) Leave unchanged"

If the user chooses to keep the existing file (any path above), track
`tech_lead_action = kept_existing` and move to the Chief Architect question.

**If no pre-existing file exists, or if the user chose to proceed with a new
override:** Ask:

> "For the **Tech Lead** agent: pick the model bias you want for
> implementation planning.
>
> (a) Faster and lower cost: optimizes for speed and reduced spend; may
>     produce lighter implementation plans on complex stories
> (b) Default: the plugin's shipped default; no override file will be written
> (c) Higher-quality planning: strongest planning on complex multi-domain
>     work; higher spend per invocation
>
> Tech Lead is the agent that deconstructs stories, routes to specialists, and
> synthesizes their input. It is the most invoked planning agent in the plugin."

- **(a) selected:** Write override with `model: haiku`. Track
  `tech_lead_action = wrote_override(haiku)`.
- **(b) selected:** Write no file. Track `tech_lead_action = default`.
- **(c) selected:** Write override with `model: opus`. Track
  `tech_lead_action = wrote_override(opus)`.

#### Per-agent question: Chief Architect

Check whether `.claude/agents/chief-architect.md` already exists (same
pre-existing-file detection logic as Tech Lead above).

If proceeding with a new override, ask:

> "For the **Chief Architect** agent: pick the model bias you want for
> architecture reviews and ADR authorship.
>
> (a) Faster and lower cost: optimizes for speed and reduced spend; useful
>     if you consult the Architect frequently on smaller decisions
> (b) Default: the plugin's shipped default (already the strongest model);
>     no override file will be written
> (c) Higher-quality planning: same as the default for this agent; no
>     additional upgrade is available
>
> Chief Architect already defaults to the strongest available model. Selecting
> (a) downshifts it for cost and speed."

- **(a) selected:** Write override with `model: sonnet`. Track
  `chief_architect_action = wrote_override(sonnet)`.
- **(b) or (c) selected:** Write no file. Track
  `chief_architect_action = default`.

#### Per-agent question: Product Owner

Check whether `.claude/agents/product-owner.md` already exists (same
pre-existing-file detection logic as Tech Lead above).

If proceeding with a new override, ask:

> "For the **Product Owner** agent: pick the model bias you want for story
> authorship and roadmap sequencing.
>
> (a) Faster and lower cost: optimizes for speed and reduced spend; useful
>     if you run frequent lightweight roadmap checks
> (b) Default: the plugin's shipped default (already the strongest model);
>     no override file will be written
> (c) Higher-quality planning: same as the default for this agent; no
>     additional upgrade is available
>
> Product Owner already defaults to the strongest available model. Selecting
> (a) downshifts it for cost and speed."

- **(a) selected:** Write override with `model: sonnet`. Track
  `product_owner_action = wrote_override(sonnet)`.
- **(b) or (c) selected:** Write no file. Track
  `product_owner_action = default`.

#### Writing override files

For each agent where an override file is to be written:

1. **Read the plugin agent file** at `agents/<agent-name>.md` (relative to
   the plugin root, i.e. the `agents/` directory in this repo).

2. **Compute the file hash** (see HASH COMPUTATION below).

3. **Construct the override file content.** Start with the header comment,
   then write the full content of the plugin agent file with only the
   `model:` frontmatter field changed.

   Header comment format (must be the very first lines of the file):

   ```
   <!-- Generated by /onboard. Source: agents/<agent-name>.md
        File hash: <sha256-of-plugin-agent-file>
        Do not edit this header. It is used by /onboard to detect plugin updates.
   -->
   ```

   The rest of the file is a verbatim copy of the plugin agent file with the
   `model:` line replaced by the user's chosen value.

4. **Write the file** to `.claude/agents/<agent-name>.md` in the current
   project (not in the plugin directory). Create the `.claude/agents/`
   directory if it does not exist.

5. The plugin's `agents/<agent-name>.md` file **must remain byte-identical**
   after this operation. Never write to the `agents/` plugin directory.

#### HASH COMPUTATION

Run these commands with the plugin repository root as the working directory
(the directory containing the `agents/` folder).

Use Bash to compute the SHA-256 hash of the plugin agent file:

```bash
shasum -a 256 agents/<agent-name>.md | awk '{print $1}'
```

On systems where `shasum` is unavailable, use:

```bash
openssl dgst -sha256 agents/<agent-name>.md | awk '{print $NF}'
```

Record the resulting hex digest in the header comment's `File hash:` field.

On a subsequent `/onboard` run, recompute the hash the same way and compare
it against the value in the header. If they differ, the plugin file has
changed since the override was generated.

#### VERIFICATION FAILURE FALLBACK

If you observe evidence that `.claude/agents/` overrides are not being loaded
(for example, if the user reports that the model does not change after running
this step), activate the fallback path:

Do NOT write any override files. Instead, emit the following instruction block
for each agent where the user selected a non-default trade-off:

> **Manual override for `<agent-name>`** (override file mechanism unavailable):
>
> Open `agents/<agent-name>.md` in the plugin directory and change the
> `model:` field in the frontmatter to `<target-model>`. For example:
>
> ```
> model: <target-model>
> ```
>
> **Warning:** This edit is inside the plugin directory and will be
> overwritten when the plugin is updated. Re-apply the edit after each
> plugin update, or re-run `/onboard` to check whether the override file
> mechanism is available in the newer version.

### Step 6: Summary and Next Steps

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

**Model overrides:**

Report one of the following, based on what occurred in Step 5:

- If `model_selection_skipped = true`: "Model Selection: skipped. Plugin
  defaults remain in effect. No override files were created."

- If `model_selection_skipped = false`: List each of the three agents and
  the outcome:

  ```
  Model overrides:
    tech-lead:        <wrote .claude/agents/tech-lead.md (model: haiku)>
                   OR <kept existing override>
                   OR <default (no override written)>
    chief-architect:  <wrote .claude/agents/chief-architect.md (model: sonnet)>
                   OR <kept existing override>
                   OR <default (no override written)>
    product-owner:    <wrote .claude/agents/product-owner.md (model: sonnet)>
                   OR <kept existing override>
                   OR <default (no override written)>
  ```

  If all three agents received the default trade-off: "Model overrides: none
  written. All agents are using plugin defaults."

  If the fallback path was activated: "Model overrides: override file
  mechanism unavailable. Manual frontmatter edits were emitted above."

**Next steps:**

The following per-agent onboarding skills are available in this plugin:

```
/onboard-product-owner   — configure the Product Owner for your issue
                           tracker, backlog norms, and current phase
```

To add project-local code-area overrides for a registered specialist, or to
register additional specialists later:

```
/add-specialist <agent-name> ["src/example/**"]
```

To verify routing health after onboarding or after adding specialists:

```
/audit-routing-table
```
