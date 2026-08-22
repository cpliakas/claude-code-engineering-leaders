---
name: onboard
description: "Use when setting up the engineering-leaders plugin for the first time on a project, or when re-running onboarding to update shared project context. Gathers shared project context for all agents (one question at a time) and discovers specialist plugins for the Tech Lead to consult. Run this before per-agent onboarding skills like /onboard-product-owner. Invoke with --check-drift when you want to re-onboard, detect onboarding drift, refresh project context, check for stale memory, or run an onboarding drift check: it compares each agent's project memory against cheaply derivable local signals (filesystem paths, specialist agent files, git remote URL, tracker directory probes) and confirms any updates with the user before writing — a diff pass, not a full re-interview."
user-invokable: true
argument-hint: "[--check-drift [agent-name]]"
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Skill
context: fork
---

# Onboard

Gather shared project context for all engineering-leaders agents and discover
specialist plugins for the Tech Lead to consult.

This skill runs a guided interview. It asks one question at a time and writes
the results to a shared memory file that every agent in this plugin reads.

## Modes

**Default (no flag):** run the guided onboarding interview under `## Process`
below. Re-running `/onboard` later updates shared project context — Step 1
detects the existing file and offers targeted updates. `--check-drift` is the
lightweight alternative when you only want to reconcile memory with what is on
disk.

**`--check-drift`:** skip the interview entirely and run the drift-check pass
under `## Drift-Check Mode` below. It compares each onboarded agent's project
memory against cheaply derivable live signals and confirms every proposed
update with the user before writing. It is a diff pass, not a full
re-interview. An optional agent name scopes the check to one agent (for
example, `/onboard --check-drift tech-lead`). Also enter this mode when the
user asks for a drift check without the flag (for example, "check for drift"
or "is agent memory stale?"). A request to "re-onboard" (e.g., "re-onboard
the tech lead") maps to this mode — it is the successor of the standalone
`/re-onboard` skill — not to the full interview.

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
> Specialists are matched and dispatched by `/plan-implementation` during
> implementation planning, and the Tech Lead advises on them during incident
> analysis and retrospectives. Matching is based on each agent's own
> description — you only need to name the agents."

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
> Tech Lead is the agent that synthesizes specialist input into implementation
> plans. It is the most invoked planning agent in the plugin."

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
/audit-agent-memory tech-lead
```

## Drift-Check Mode

Entered with `--check-drift`. Audit onboarded agent project memory for drift
against live project signals. Produces a per-agent diff report grouped into
drifted, unchanged-notable, and new items. Phrases every finding as a question
the user confirms or dismisses. Writes updates to memory only after explicit
user confirmation.

Run this mode after a structural project change (renamed directories, new CI
provider, migrated issue tracker, specialist agents added or removed), on a
periodic cadence, or when an agent gives advice that feels out of date.

If invoked without an agent name, audits every onboarded agent and the shared
Layer 1 context. If invoked with an agent name (for example, `/onboard
--check-drift tech-lead`), restricts the audit to that agent's memory
directory.

None of the interview steps above run in this mode.

Like the interview, this mode runs in the skill's forked context (`context:
fork` in the frontmatter). Forked skill contexts can still prompt the user
and wait for answers — the interview mode depends on the same property — so
the per-item confirmation loop below works unchanged: every proposed update
is confirmed with the user before any Edit is applied.

### 1. Discover Onboarded Agents

Determine the scope of the audit.

**Full run (no agent name):** Glob for all agent memory directories under the
project root:

```
.claude/agent-memory/engineering-leaders-*/MEMORY.md
```

Exclude `.claude/agent-memory/engineering-leaders/PROJECT.md`. That is the
Layer 1 shared context, not an agent memory directory. Treat any directory
matching `engineering-leaders-<agent-name>/` that contains a readable
`MEMORY.md` as one onboarded agent. Collect the agent names from the directory
suffix (for example, `engineering-leaders-tech-lead` yields `tech-lead`).

Also check for the Layer 1 shared context at:

```
.claude/agent-memory/engineering-leaders/PROJECT.md
```

If found, include it in the audit as the shared context layer (handled in
drift-check Step 3).

If no agent memory directories exist and no `PROJECT.md` exists, report:

```
No onboarded agents found. Run /onboard without --check-drift, or
/onboard-<agent-name>, to create project memory for this project.
```

And exit without further checks.

**Scoped run (agent name provided):** Check for a memory directory at:

```
.claude/agent-memory/engineering-leaders-<agent-name>/MEMORY.md
```

If the directory does not exist or contains no readable `MEMORY.md`, report:

```
No memory directory found at .claude/agent-memory/engineering-leaders-<agent-name>/.
Run /onboard without --check-drift, or /onboard-<agent-name>, to create one.
```

And exit without further checks.

### 2. Run Drift Checks

For each discovered memory file (per-agent `MEMORY.md` and, where present,
the shared `PROJECT.md`), apply the four signal checks below. Collect all
findings before emitting the report.

**Un-diffable content is excluded.** Skip all memory content that has no
derivable local signal: team norms, review practices, persona preferences,
stakeholder relationships, philosophy, free-text rationale paragraphs, and
narrative prose. Do not raise drift questions about these. They remain the
domain of `/onboard-<agent>` for a full refresh.

#### Signal 1: Filesystem Path Presence

Parse each memory file for directory and file path claims. A path claim is any
string that:

- Looks like a relative filesystem path (contains `/`, does not start with
  `http`)
- Is mentioned in the context of a directory or file location (for example,
  "ADR directory", "conventions file", "test directory", "routing file")

For each claimed path:

1. Check whether the path currently exists using Glob.
2. If it exists, the item is **unchanged**; note it only if plausible
   alternates also exist (see below).
3. If it does not exist, glob for plausible alternates using this candidate
   map:

   | Claimed path pattern  | Candidate alternates to glob for |
   |-----------------------|----------------------------------|
   | `docs/adr/`           | `docs/adrs/`, `docs/decisions/`, `architecture/adr/`, `architecture/decisions/` |
   | `docs/adrs/`          | `docs/adr/`, `docs/decisions/`, `architecture/adr/` |
   | `docs/decisions/`     | `docs/adr/`, `docs/adrs/`, `architecture/decisions/` |
   | `docs/conventions/`   | `docs/`, `CONVENTIONS.md`, `.claude/conventions/` |
   | `tests/`              | `test/`, `spec/`, `__tests__/` |
   | `test/`               | `tests/`, `spec/`, `__tests__/` |
   | Any other path        | Parent directory variants with common plural/singular alternates |

4. Phrase the finding as a question (see Signal Phrasing below).

#### Signal 2: Specialist Agent Files

This check applies only when auditing the Tech Lead's memory (the
`engineering-leaders-tech-lead` directory) or the shared `PROJECT.md` if it
lists specialists.

1. Parse the `## Registered Specialists` section of the memory file. Extract
   each specialist's agent name (for example, `frontend-engineer`) and its
   expected file path (default: `agents/<agent-name>.md`).
2. Glob `agents/*.md` to enumerate all agent files currently present on disk.
3. Compare the two sets:
   - Specialists in memory but not found on disk: **drifted** (file removed
     or moved).
   - Agent files on disk not listed in memory: **new** (file added since
     onboarding).
4. Phrase each finding as a question (see Signal Phrasing below).

#### Signal 3: Git Remote URL

This check applies when memory claims a source-control hosting platform.
Look for phrases such as "GitHub", "GitLab", "Bitbucket", "hosted on", "git
remote", or a `github.com`/`gitlab.com`/`bitbucket.org` URL in memory.

1. Run `Bash: git remote get-url origin` to retrieve the current remote URL.
   Extract the hostname from both HTTPS (`https://github.com/...`) and SSH
   (`git@github.com:...`) forms before classifying.
2. Classify the hostname from the remote URL:
   - `github.com` → GitHub
   - `gitlab.com` → GitLab
   - `bitbucket.org` → Bitbucket
   - Any other hostname → "other (`<hostname>`)"
3. Compare the memory-claimed platform against the classified hostname.
4. If they differ, phrase a drift finding as a question (see Signal Phrasing).
5. If `git remote get-url origin` exits non-zero (no remote configured), skip
   the check silently; do not raise an error.

#### Signal 4: Tracker Directory Probes

This check applies when memory claims an issue tracker. Look for tracker names
or references (for example, "Beads", "GitHub Issues", "Linear", "Jira",
"`.beads/`", "`.github/`") in memory.

Use this canonical footprint map to probe for each claimed tracker:

| Tracker       | Probe path(s)                               |
|---------------|---------------------------------------------|
| Beads         | `.beads/`                                   |
| GitHub Issues | `.github/ISSUE_TEMPLATE/` or `.github/`     |
| Linear        | `.linear/`                                  |
| Jira          | `jira.properties`, `.jira/`                 |
| Other         | No probe; skip silently                     |

If the tracker probe returns no match for the memory-claimed tracker, surface
a drift finding. Also probe for unexpected tracker directories: if a tracker
directory is found on disk that does not match the memory-claimed tracker,
surface that as a **new** finding.

Do not issue any network requests. If the tracker is recorded only as a URL
(no local directory footprint is known), skip the probe silently.

### 3. Apply Shared-Context Propagation

This step consolidates `PROJECT.md` findings from drift-check Step 2; it does
not run additional signal checks.

**Full run only.** After running the four signal checks against `PROJECT.md`:

1. List every per-agent `MEMORY.md` that references `PROJECT.md`. A reference
   is detected by Grep for the string `PROJECT.md` in the file.
2. If `PROJECT.md` produced any drift findings, report them once in a
   dedicated `## Shared Context` section and list the dependent agent memories
   so the user sees the full blast radius.
3. When the user confirms a shared-context update, apply it to `PROJECT.md`
   once using Edit. Do not re-prompt the user for the same item when visiting
   dependent agent memories.

**Scoped run.** If the named agent's `MEMORY.md` references `PROJECT.md`,
include the `## Shared Context` section as described above. If it does not
reference `PROJECT.md`, omit the `## Shared Context` section entirely.

### 4. Emit Report

After all checks are complete, emit the drift report in the fixed structure
below. Sections appear in this order. Omit `## Shared Context` when there are
no shared-context findings and PROJECT.md was not probed (or does not exist).
For signals not applicable to the current agent or run scope (Signal 2 when
auditing a non-Tech-Lead agent, Signal 3 when memory claims no hosting
platform), show "N/A" in the summary table row rather than 0. Omit per-agent
subsection headings (Drifted, Unchanged-Notable, New) when that category is
empty for an agent; emit a brief "No items." line only if all three are empty.

```markdown
## Summary

Agents scanned: <N>
Shared context: [found and audited | not found | not probed (scoped run)]
Total drift items: <total across all agents and shared context>

| Signal source          | Drift items |
|------------------------|-------------|
| Filesystem paths       | <N>         |
| Specialist agent files | <N>         |
| Git remote             | <N>         |
| Tracker probes         | <N>         |

---

## Shared Context

> Drift detected in `.claude/agent-memory/engineering-leaders/PROJECT.md`.
> The following per-agent memories reference this file and will inherit any
> confirmed updates:
> - `.claude/agent-memory/engineering-leaders-<agent-name>/MEMORY.md`

### Drifted

**[Finding N]** Memory says `<memory-value>`, but `<derived-value>` was
observed on disk. Does `<derived-value>` still look right for this project?
_(Type the correct value to use a different one, or press Enter to accept
`<derived-value>`)_

### Unchanged

No unchanged-notable items detected in shared context.

### New

No new signals detected in shared context.

---

## Per-Agent Drift

### <agent-name>

#### Drifted

**[Finding N]** Memory says `"<memory-value>"`, but `"<derived-value>"` was
observed. Does `"<derived-value>"` still look right?

#### Unchanged-Notable

**[Item N]** Memory says `"<memory-value>"`. `<path>` still exists, but
`<alternate-path>` also exists. Please confirm which path is current.

#### New

**[Item N]** `"<new-value>"` was found on disk but is not recorded in memory.
Should this be added?

---

## Confirmation

Answer each numbered item below. For each finding, enter:

- **y**: accept the derived value (or the value you typed) and update memory
- **n**: dismiss this finding; memory is left unchanged

**[1]** Memory says `"<memory-value>"`, observed `"<derived-value>"`. Accept?
[y/n/type a different value]

**[2]** …

---

## Next Step

[If total drift items = 0:]
No drift detected across all audited agents. No action required. Run
`/onboard --check-drift` again after the next structural project change.

[If total drift items > 0 and no agent has more than 50% of its items drifted:]
Review and confirm the findings in `## Confirmation` above. Run
`/onboard --check-drift` again after applying updates to verify the changes.

[If any agent has more than 50% of its auditable items drifted:]
More than half of `<agent-name>`'s onboarding-derived memory appears to have
drifted. Consider re-running `/onboard-<agent-name>` for a full refresh rather
than confirming item by item.

[If any un-diffable content categories were present in memory:]
Note: the following onboarding categories have no local signal source and were
not audited: team norms, review practices, persona preferences, stakeholder
relationships, philosophy, and free-text rationale. Re-run `/onboard-<agent>`
if those may have changed.
```

### 5. Apply Confirmed Updates

For each finding the user accepts:

1. Use `Edit` to apply the update in place to the existing memory file.
2. Locate the exact memory-claimed value as it appears in the file and replace
   it with the accepted value. Do not rewrite the surrounding content.
3. Do not create a new file. All writes are in-place edits to existing files.

For each finding the user dismisses:

1. Do not edit the memory file.

**Batch-accept.** After the user has answered at least two individual findings
in the current run, offer the batch-accept option: "All remaining items can
also be accepted at once. Enter **accept-all** to confirm every remaining
finding, or continue answering individually." Do not offer batch-accept on the
first finding of any run. When the user enters `accept-all`, apply edits for
all remaining accepted items in sequence without further per-item prompts.

### Signal Phrasing

Every drift finding MUST follow question form. The forbidden and required
patterns are:

**Prohibited phrasing (never use):**

- "The path is now `<value>`."
- "Memory should say `<value>`."
- "This value has changed to `<value>`."
- Any declarative statement about the derived value being correct.

**Required phrasing for drift findings (always use):**

- "Memory says `"<memory-value>"`, but `"<derived-value>"` was observed.
  Does `"<derived-value>"` still look right?"
- "Memory records `"<memory-value>"`, but `<condition>`. Does this still
  look right for this project?"
- "Memory lists `"<memory-value>"`, which was not found on disk. Did the
  location change?"

**Required phrasing for unchanged-notable items (ambiguity confirmation):**

- "Memory says `"<memory-value>"`. `<path>` still exists, but `<alternate-path>`
  was also found. Which path is current for this project?"

Each finding must quote both the memory-claimed value and the derived value
(or signal observation) before asking the question. The user's answer
determines what, if anything, is written to memory.

All drift-check output is advisory until the user confirms each item. No file
is written, edited, or deleted without an explicit per-item (or explicit
batch-accept) confirmation from the user.
