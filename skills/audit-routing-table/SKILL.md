---
name: audit-routing-table
description: "Audit the Tech Lead's specialist routing model for orphan overrides, broken file pointers, redundant overrides, and thin agent descriptions. Reports findings for human review — does not auto-correct. Use after onboarding, after adding specialists, or when the Tech Lead appears to be missing consultation requests."
user-invokable: true
argument-hint: ""
allowed-tools: Read, Glob, Grep
---

# Audit Routing Table

Audit the Tech Lead's specialist routing model in
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md` for four
categories of hygiene issues. Produces a report with recommended actions.
Does not modify any files.

## Process

### 1. Read the Memory File

Read `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`.

If the file does not exist or is empty, report:

```
No Tech Lead memory file found. Run /onboard or /add-specialist to create one.
```

And exit.

Parse two sections:

- **Registered Specialists** — extract the list of `<agent-name>` and optional
  `<path>` from each bullet. Default path is `agents/<agent-name>.md` when no
  path is given.
- **Project Code Area Overrides** — extract each `| signal | agent-name |` row
  from the table, ignoring the header and separator rows.

### 2. Run Four Checks

For each check, collect findings into a list. A finding includes:

- The specific entry that triggered it
- A one-line explanation of why it is a problem
- A recommended action

#### Check 1: Orphan Overrides

For each row in `## Project Code Area Overrides`, verify the target agent name
appears in `## Registered Specialists`.

**Finding:** override row targets `<agent-name>` which is not in `## Registered
Specialists`.

**Recommended action:** Either register the agent with `/add-specialist
<agent-name>` or remove the orphan override row.

#### Check 2: Broken Pointers

For each entry in `## Registered Specialists`, attempt to read the agent file
at the specified path (or `agents/<agent-name>.md`).

Use Glob to check whether the file exists. If the file is not found:

**Finding:** registered specialist `<agent-name>` points to `<path>` which does
not exist.

**Recommended action:** Correct the path in `## Registered Specialists`, or
remove the entry if the specialist is no longer used. If the agent is from an
external plugin that is not installed locally, this may be expected — verify
with the plugin author.

#### Check 3: Redundant Overrides

For each row in `## Project Code Area Overrides` where the target agent's file
is readable:

1. Read the agent file.
2. Extract the `description` field from the frontmatter.
3. Check whether the override signal appears verbatim (case-insensitive) in the
   description body.

If found:

**Finding:** override signal `<signal>` for `<agent-name>` already appears in
the agent's description.

**Recommended action:** Remove this override row. The Tech Lead will match the
signal via description matching, so the override is unnecessary and creates
maintenance surface. This row will be re-flagged on every audit until removed.

#### Check 4: Thin Descriptions

For each entry in `## Registered Specialists` where the agent file is readable:

1. Extract the `description` field from the frontmatter.
2. Count the non-whitespace word count of the description body. Exclude the
   YAML scalar delimiter (`|`), the `name:` header line, and `<example>` /
   `<commentary>` blocks.

If the word count is below 60:

**Finding:** registered specialist `<agent-name>` has a thin description (fewer
than 60 words after stripping markup).

**Recommended action:** Enrich the agent's description with more trigger
phrases, example-context phrases, and jurisdiction keywords so the Tech Lead
can match it reliably via description matching. A thin description means the
Tech Lead may miss relevant consultations that the old routing table would have
caught.

### 3. Produce the Report

Output a structured report. Organize by check. For each check, list findings
or confirm it is clean.

```markdown
# Routing Table Audit Report

Audited: .claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md
Registered specialists: <N>
Override rows: <M>

---

## Check 1: Orphan Overrides

[PASS — no orphan override rows found.]

OR

[N finding(s):]
- **`<signal>` → `<agent-name>`** — agent not in Registered Specialists.
  Action: register with `/add-specialist <agent-name>` or remove this row.

---

## Check 2: Broken Pointers

[PASS — all registered specialists have readable agent files.]

OR

[N finding(s):]
- **`<agent-name>`** — agent file not found at `<path>`.
  Action: correct the path or remove the entry.

---

## Check 3: Redundant Overrides

[PASS — no redundant override rows found.]

OR

[N finding(s):]
- **`<signal>` → `<agent-name>`** — signal appears in the agent's description.
  Action: remove this override row.

---

## Check 4: Thin Descriptions

[PASS — all registered specialists have descriptions with 60+ words.]

OR

[N finding(s):]
- **`<agent-name>`** — description is <W> words (threshold: 60).
  Action: add trigger phrases, example contexts, and jurisdiction keywords to
  the agent's description.

---

## Summary

| Check                  | Status |
|------------------------|--------|
| Orphan overrides       | PASS / N finding(s) |
| Broken pointers        | PASS / N finding(s) |
| Redundant overrides    | PASS / N finding(s) |
| Thin descriptions      | PASS / N finding(s) |

Total findings: <total>

[If findings > 0:]
No files were modified. Address each finding above manually, then re-run
`/audit-routing-table` to verify.
```

## Migration Use

This skill doubles as a migration helper for projects converting from the old
`## Specialist Routing Table` format. See `MIGRATION.md` in this skill
directory for the step-by-step migration path.
