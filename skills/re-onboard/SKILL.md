---
name: re-onboard
description: "Audit onboarded agent memory for drift against live project signals. Use when you want to re-onboard, detect onboarding drift, refresh project context, check for stale memory, or run an onboarding drift check. Compares each agent's project memory against cheaply derivable local signals (filesystem paths, specialist agent files, git remote URL, tracker directory probes) and confirms any updates with the user before writing. Does not replace a full /onboard-<agent> re-run; it is a diff pass. Complements /audit-routing-table and /audit-agent-memory."
user-invokable: true
argument-hint: "[agent-name]"
allowed-tools: Read, Glob, Grep, Bash, Edit
---

# Re-onboard

Audit onboarded agent project memory for drift against live project signals.
Produces a per-agent diff report grouped into drifted, unchanged-notable, and
new items. Phrases every finding as a question the user confirms or dismisses.
Writes updates to memory only after explicit user confirmation.

Run this skill after a structural project change (renamed directories, new CI
provider, migrated issue tracker, specialist agents added or removed), on a
periodic cadence, or when an agent gives advice that feels out of date.

If invoked without an argument, audits every onboarded agent and the shared
Layer 1 context. If invoked with an agent name (for example, `/re-onboard
tech-lead`), restricts the audit to that agent's memory directory.

## Process

### 1. Discover Onboarded Agents

Determine the scope of the audit.

**Full run (no argument):** Glob for all agent memory directories under the
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

If found, include it in the audit as the shared context layer (handled in Step 3).

If no agent memory directories exist and no `PROJECT.md` exists, report:

```
No onboarded agents found. Run /onboard or /onboard-<agent-name> to create
project memory for this project.
```

And exit without further checks.

**Scoped run (argument provided):** Check for a memory directory at:

```
.claude/agent-memory/engineering-leaders-<argument>/MEMORY.md
```

If the directory does not exist or contains no readable `MEMORY.md`, report:

```
No memory directory found at .claude/agent-memory/engineering-leaders-<argument>/.
Run /onboard or /onboard-<argument> to create one.
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

This step consolidates `PROJECT.md` findings from Step 2; it does not run additional signal checks.

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
`/re-onboard` again after the next structural project change.

[If total drift items > 0 and no agent has more than 50% of its items drifted:]
Review and confirm the findings in `## Confirmation` above. Run
`/re-onboard` again after applying updates to verify the changes.

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

All output is advisory until the user confirms each item. No file is written,
edited, or deleted without an explicit per-item (or explicit batch-accept)
confirmation from the user.
