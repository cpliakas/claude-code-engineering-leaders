---
name: add-specialist
description: "Register a specialist agent in the Tech Lead's routing model. Use when adding a new agent to the project that the Tech Lead should consult during implementation planning, incident analysis, or retrospectives."
user-invokable: true
allowed-tools: Read, Glob, Edit, Write
argument-hint: "<agent-name> [code-area-override ...]"
---

# Add Specialist

Register a specialist agent so the Tech Lead considers it during implementation
planning, incident analysis, and retrospectives. Trigger vocabulary for the
specialist lives in the agent's own `description` field. This skill registers
the agent and optionally adds project-local code-area overrides.

## Input

`$ARGUMENTS` = agent name followed by zero or more project-local code-area
override signals.

**Register only (most common case):**

```
my-security-agent
payments-specialist
data-engineer
```

**Register with project-local overrides (file globs or internal module names):**

```
payments-specialist "src/payments/**" "src/billing/**"
data-engineer "src/etl/**"
```

Trigger keywords such as `authentication` or `pipeline` belong in the agent's
`description`, not in this argument list. If keyword-style arguments are
provided, a warning is shown (see backward compatibility below).

## Process

### 1. Parse Arguments

Split `$ARGUMENTS` on whitespace, respecting quoted strings:

- First token = agent name
- Remaining tokens = project-local code-area override signals (file globs or
  repo-specific keywords). May be empty.

### 2. Handle Missing Agent Name

If `$ARGUMENTS` is empty, ask the user for:

- **Agent name** — the kebab-case name matching the agent's `name` frontmatter
  field.

Do not proceed until the agent name is provided.

### 3. Validate the Agent File

Use Glob to check for `agents/<agent-name>.md`. If the file does not exist:

- Warn the user: "No agent file found at `agents/<agent-name>.md`. Verify the
  agent name matches the `name` field in its frontmatter."
- List any agents in `agents/` whose filename contains the provided name as a
  substring (to help identify typos).
- Ask the user whether to continue anyway (agents installed from external
  plugins may not have a local file).

### 4. Read the Tech Lead Memory File

The routing model lives at:

```
.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md
```

Attempt to read it. Three possible states:

**A. File does not exist:** Create it with this initial structure:

```markdown
# Tech Lead Project Memory

## Registered Specialists

## Project Code Area Overrides

| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
```

**B. File exists but has no `## Registered Specialists` section:** Append both
new sections after the existing content.

**C. File exists with `## Registered Specialists` but no `## Project Code Area Overrides` section:**
Append only the overrides table after the `## Registered Specialists` block:

```markdown
## Project Code Area Overrides

| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
```

Read the updated file and proceed to Step 5.

**D. File exists with both sections:** Read it and proceed to Step 5.

### 5. Check for Duplicate Registration

Scan `## Registered Specialists` for an existing entry whose agent name matches
the provided name. If found:

- Tell the user the agent is already registered and show the current entry.
- Ask whether to update the entry path, skip, or proceed to Step 6 to
  add overrides only.

### 6. Check Override Arguments for Redundancy

If override arguments were provided, and the agent file exists locally (per the
Glob check in Step 3), read the agent's `description` field. If the file does
not exist locally (e.g., the agent is installed from an external plugin), skip
this redundancy check and proceed to Step 7; `/audit-routing-table` will surface
redundancies later once the file becomes accessible. For each override argument, check whether
the override string appears case-insensitively in the description body.

If a match is found, warn the user before writing:

> "Override `[signal]` already appears in `[agent-name]`'s description. The
> Tech Lead will match this signal via description matching without an explicit
> override. Adding this row is redundant and will be flagged by
> `/audit-routing-table`. Proceed with adding it anyway? (y/n)"

If the user says no, skip that override. Continue with non-redundant overrides.

### 7. Handle Backward-Compatible Trigger Keywords

If any override argument does not look like a file path or glob (no `/` or `*`)
and does not appear to be a project-local module name, emit a warning:

> "Note: `[keyword]` looks like a trigger keyword rather than a project-local
> code-area signal. Trigger vocabulary (e.g., `authentication`, `pipeline`)
> belongs in the agent's `description` so both the Tech Lead and the main
> loop use the same source of truth. Adding as an override anyway — consider
> whether this keyword should live in the agent file instead."

Still write the row (backward-compatible behavior). This warning is
informational only.

### 8. Write the Updated File

**Register the agent** — if not already in `## Registered Specialists`, append:

```
- `<agent-name>` — `agents/<agent-name>.md`
```

If the agent file path differs from the default (e.g., an external plugin),
use the actual resolved path.

**Append overrides** — for each non-skipped override argument, append a row to
`## Project Code Area Overrides`:

- If the signal contains `/` or `*`: wrap in backticks — `` `src/auth/**` ``
- Otherwise: use plain text — `authentication`

Row format:

```
| <formatted-signal> | <agent-name> |
```

Write the updated file back to disk.

## Output

Confirm the result with a summary:

**Register-only path:**

```
Registered `<agent-name>` in `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`.

The Tech Lead will now consult `<agent-name>` when the issue text matches
phrases in the agent's description.

To add project-local code-area overrides later:
  /add-specialist <agent-name> "src/example/**"

Run `/audit-routing-table` to verify routing health.
```

**Register-plus-overrides path:**

```
Registered `<agent-name>` with <N> code-area override(s):

| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
| <override-1>       | <agent-name>    |
| <override-2>       | <agent-name>    |

Routing model updated at: .claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md

The Tech Lead will consult `<agent-name>` when the issue text matches
the agent's description phrases OR when the issue references any of the
overrides above.

Run `/audit-routing-table` to verify routing health.
```

If any overrides were skipped (redundant), list them and explain what was
preserved.
