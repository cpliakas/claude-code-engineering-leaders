# Migration: Specialist Routing Table → Registered Specialists

This document explains how to migrate an existing Tech Lead memory file from
the old `## Specialist Routing Table` format to the new
`## Registered Specialists` + `## Project Code Area Overrides` format.

## Background

Before version 0.12.0, the Tech Lead's project memory stored routing
information in a single `## Specialist Routing Table` section:

```markdown
## Specialist Routing Table

| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
| authentication     | security-specialist |
| src/payments/**    | payments-specialist |
| pipeline           | data-engineer |
```

This conflated two kinds of information:

1. **Trigger vocabulary** — keywords and phrases the agent's description
   already contains (e.g., `authentication`, `pipeline`).
2. **Project-local code-area signals** — file globs and internal names not
   found in any agent description (e.g., `src/payments/**`).

Version 0.12.0 replaces this with two narrower sections:

- `## Registered Specialists` — a list of agent names to consult.
- `## Project Code Area Overrides` — only the project-local signals.

Trigger vocabulary now lives exclusively in agent `description` fields, where
both the Tech Lead and the Claude Code main loop read it.

## Migration Steps

This is intentionally manual. Automated migration risks silently deleting rows
whose purpose is not obvious.

### Step 1: Run the Audit

```
/audit-routing-table
```

The audit skill reads the current file and flags every row whose signal is
already present in the target agent's description (redundant row) or whose
target agent is not registered (orphan row). Use the report as your work list.

### Step 2: Identify Agents

Collect the unique specialist agent names from the routing table. For each
agent, add it to `## Registered Specialists`:

```markdown
## Registered Specialists

- `security-specialist` — `agents/security-specialist.md`
- `payments-specialist` — `plugins/payments/agents/payments-specialist.md`
- `data-engineer` — `agents/data-engineer.md`
```

Use the actual file path if the agent definition is not at the default
`agents/<name>.md` location.

### Step 3: Classify Rows

For each row in the old `## Specialist Routing Table`, decide:

**Keep as a code-area override** if the signal is:
- A file glob (`src/payments/**`)
- A repo-specific module name (`billing-service`, `webhook-processor`)
- Internal terminology not likely found in any agent description

Move these rows to `## Project Code Area Overrides`.

**Delete the row** if the signal is:
- A generic keyword or phrase (`authentication`, `pipeline`, `deployment`)
- Already present in the target agent's description body (flagged by Check 3)

Duplicating trigger vocabulary into the overrides table creates silent drift
and will be flagged by every future audit run.

### Step 4: Write the New File

Replace the entire `## Specialist Routing Table` section with both new sections.
The resulting file should look like:

```markdown
# Tech Lead Project Memory

## Registered Specialists

- `security-specialist` — `agents/security-specialist.md`
- `payments-specialist` — `plugins/payments/agents/payments-specialist.md`

## Project Code Area Overrides

| Code Area / Signal  | Specialist Agent     |
|---------------------|---------------------|
| `src/payments/**`   | payments-specialist  |
| `src/auth/**`       | security-specialist  |
```

### Step 5: Re-run the Audit

```
/audit-routing-table
```

Verify zero findings. If findings remain, address them and re-run until clean.

## Notes

- This migration is one-time. Once complete, adding a new specialist requires
  only one command: `/add-specialist <name>`.
- Specialists whose agent files cannot be found will be flagged by Check 2.
  For agents from external plugins not installed locally, this is expected.
- If you are uncertain whether a signal belongs in the agent description or
  in the overrides table, prefer the agent description. The overrides table
  is for signals that are genuinely project-specific — things a new team
  member would not recognize without knowing this specific codebase.
