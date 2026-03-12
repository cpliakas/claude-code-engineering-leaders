---
name: add-specialist
description: "Register a specialist agent in the Tech Lead's routing table. Use when adding a new agent to the project that the Tech Lead should consult during implementation planning, incident analysis, or retrospectives."
user-invokable: true
allowed-tools: Read, Glob, Edit, Write
argument-hint: "<agent-name> <code-area-or-signal> [code-area-or-signal ...]"
---

# Add Specialist

Register a specialist agent in the Tech Lead's Specialist Routing Table so it is consulted during implementation planning, incident analysis, and retrospectives.

## Input

`$ARGUMENTS` = agent name followed by one or more code areas or signal phrases to route to that agent.

Examples:

- `my-security-agent "src/auth/**" authentication "token validation"`
- `payments-specialist "src/payments/**" "billing/**" stripe`
- `data-engineer "src/etl/**" pipeline "data migration"`

## Process

### 1. Handle Missing Input

If `$ARGUMENTS` is empty or contains only an agent name with no signals, prompt the user for the missing information in a single consolidated message:

- **Agent name** — the kebab-case name matching the agent's `name` frontmatter field
- **Code areas or signals** — one or more file glob patterns (e.g., `src/auth/**`) or keyword signals (e.g., `authentication`) that should trigger routing to this agent

Do not proceed until both an agent name and at least one signal are provided.

### 2. Parse Arguments

Split `$ARGUMENTS` on whitespace, respecting quoted strings:

- First token = agent name
- Remaining tokens = signals (file globs or keyword phrases)

### 3. Validate the Agent Exists

Use Glob to check for `agents/<agent-name>.md`. If the file does not exist:

- Warn the user: "No agent file found at `agents/<agent-name>.md`. Verify the agent name matches the `name` field in its frontmatter."
- List any agents in `agents/` whose filename contains the provided name as a substring (to help identify typos).
- Do not proceed until the user confirms they want to continue anyway, or provides a corrected name.

### 4. Read the Tech Lead Memory File

The routing table lives at:

```
.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md
```

Attempt to read it. Three possible states:

**A. File does not exist:** Create it with this initial structure:

```markdown
# Tech Lead Project Memory

## Specialist Routing Table

| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
```

**B. File exists but has no `## Specialist Routing Table` section:** Append the section and table header after the existing content.

**C. File exists with a `## Specialist Routing Table` section:** Read it and proceed to Step 5.

### 5. Check for Duplicate Entries

Scan the existing routing table for rows that already map any of the provided signals to any agent. If duplicates exist:

- List them and note the current agent they route to.
- Ask the user whether to overwrite, skip, or add alongside the existing entry.
- Apply the user's choice before writing.

### 6. Append Routing Table Rows

For each signal provided, append a row to the routing table:

- If the signal looks like a file path or glob (contains `/` or `*`): wrap it in backticks — `` `src/auth/**` ``
- Otherwise: use plain text — `authentication`

Row format:

```
| <formatted-signal> | <agent-name> |
```

### 7. Write the Updated File

Write the updated memory file back to disk. If the file did not previously exist, create the necessary directory structure first.

## Output

Confirm the result with a summary:

```
Added <N> routing entries for `<agent-name>`:

| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
| <signal-1>         | <agent-name>    |
| <signal-2>         | <agent-name>    |

Routing table updated at: .claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md

The Tech Lead will now consult `<agent-name>` when any of these signals appear
in an issue, story, or incident description.
```

If any signals were skipped due to duplicates, list them and explain what was preserved.
