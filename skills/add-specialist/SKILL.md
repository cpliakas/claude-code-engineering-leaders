---
name: add-specialist
description: "Register a specialist agent in the Tech Lead's routing model. Use when adding a new agent to the project that the Tech Lead should consult during implementation planning, incident analysis, or retrospectives."
user-invokable: true
allowed-tools: Read, Glob, Edit, Write
argument-hint: "<agent-name> [<target-type> <path-or-slug>] [code-area-override ...]"
---

# Add Specialist

Register a specialist agent so the Tech Lead considers it during implementation
planning, incident analysis, and retrospectives. Trigger vocabulary for the
specialist lives in the agent's own `description` field. This skill registers
the agent and optionally adds project-local code-area overrides.

## Input

`$ARGUMENTS` = agent name, optional target type, path-or-slug value, and zero
or more project-local code-area override signals.

**Register only (subagent, most common case):**

```
my-security-agent
payments-specialist
data-engineer
```

**Register with explicit target type (flag form):**

```
security-gate --target-type=human "Alice Chen (CISO)"
ops-runbook --target-type=doc docs/ops/incident-response.md
write-runbook-skill --target-type=skill write-runbook
external-analyst --target-type=external-agent plugin-x:analyst-agent
```

**Register with explicit target type (positional form):**

```
security-gate human "Alice Chen (CISO)"
ops-runbook doc docs/ops/incident-response.md
write-runbook-skill skill write-runbook
external-analyst external-agent plugin-x:analyst-agent
```

**Register subagent with project-local overrides:**

```
payments-specialist "src/payments/**" "src/billing/**"
data-engineer "src/etl/**"
```

Trigger keywords such as `authentication` or `pipeline` belong in the agent's
`description`, not in this argument list. If keyword-style arguments are
provided, a warning is shown (see backward compatibility below).

The five valid target types are: `subagent` (default), `skill`, `doc`,
`human`, `external-agent`. Omitting the target type registers a `subagent`
entry in the legacy format, preserving full backward compatibility.

## Process

### 1. Parse Arguments

Split `$ARGUMENTS` on whitespace, respecting quoted strings.

- **First token** = agent name (required).
- **Second token** = examined to determine whether it is a target-type token
  or an override signal:
  - If it is one of the five fixed strings (`subagent`, `skill`, `doc`,
    `human`, `external-agent`), treat it as the target type. The token
    immediately following it is the path-or-slug value for the registration.
  - If a `--target-type=<type>` flag appears anywhere in `$ARGUMENTS`, use
    that value as the target type. The non-flag tokens after the agent name
    are the path-or-slug value (if any) and override signals.
  - Otherwise, assume target type `subagent` and treat all remaining tokens
    as override signals (existing behavior).
- **Path-or-slug value** (required for non-`subagent` target types):
  - `skill`: the skill slug (e.g., `write-runbook`).
  - `doc`: the file path (e.g., `docs/security/review-gate.md`).
  - `human`: the contact identifier (name, role, or email address).
  - `external-agent`: the namespaced slug (e.g., `plugin-x:agent-y`).
- **Remaining tokens** = project-local code-area override signals (file
  globs or repo-specific keywords). May be empty.

### 2. Handle Missing Agent Name

If `$ARGUMENTS` is empty, ask the user for:

- **Agent name** — the kebab-case name matching the agent's `name` frontmatter
  field.

Do not proceed until the agent name is provided.

### 3. Validate the Target

Validation is performed per target type. All validation failures are
**warnings, not errors**: ask the user whether to continue and honor the
answer. This matches the existing duplicate and redundancy warning pattern.

**`subagent` (default):**

Use Glob to check for `agents/<agent-name>.md`. If the file does not exist:

- Warn: "No agent file found at `agents/<agent-name>.md`. Verify the agent
  name matches the `name` field in its frontmatter."
- List any agents in `agents/` whose filename contains the provided name as a
  substring (to help identify typos).
- Ask whether to continue (agents from external plugins may not have a local
  file).

**`skill`:**

Use Glob to check for `skills/<slug>/SKILL.md`. If not present locally:

- Warn: "No skill file found at `skills/<slug>/SKILL.md`. The skill may live
  in an external plugin. Proceed?"
- Ask whether to continue.

**`doc`:**

Use Glob to check that the path exists. If not found:

- Warn: "No file found at `<path>`. The doc path may be incorrect or the file
  may not yet exist. Proceed?"
- Ask whether to continue.

**`human`:**

No format check. Accept any non-empty string as the contact identifier.

**`external-agent`:**

Check that the slug contains a namespace separator (`:`). If not:

- Warn: "`<slug>` does not contain a `:` namespace separator. External-agent
  slugs should be in the form `plugin-name:agent-name`. Proceed?"
- Ask whether to continue.

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

**Register the specialist** (if not already in `## Registered Specialists`):
append using the format appropriate for the target type:

- **`subagent` (default or explicit):** Write in the legacy two-token format
  so existing memory files remain unchanged:
  ```
  - `<agent-name>` — `agents/<agent-name>.md`
  ```
  If the agent file path differs from the default, use the resolved path.

- **`skill`:**
  ```
  - `<name>` — `<skill-slug>` — `target-type: skill`
  ```

- **`doc`:**
  ```
  - `<name>` — `<file-path>` — `target-type: doc`
  ```

- **`human`:**
  ```
  - `<name>` — `<contact-identifier>` — `target-type: human`
  ```

- **`external-agent`:**
  ```
  - `<name>` — `<plugin:agent-slug>` — `target-type: external-agent`
  ```

Do **not** touch the `## Routing Outcomes` section; leave it unchanged if it
exists in the file.

**Append overrides:** for each non-skipped override argument (applies to
`subagent` entries only; non-subagent entries do not use code-area overrides),
append a row to `## Project Code Area Overrides`:

- If the signal contains `/` or `*`: wrap in backticks — `` `src/auth/**` ``
- Otherwise: use plain text — `authentication`

Row format:

```
| <formatted-signal> | <agent-name> |
```

Write the updated file back to disk.

## Output

Confirm the result with a summary appropriate to the target type.

**`subagent`: register only:**

```
Registered `<agent-name>` in `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`.

Target type: subagent (default)

The Tech Lead will now consult `<agent-name>` when the issue text matches
phrases in the agent's description.

To add project-local code-area overrides later:
  /add-specialist <agent-name> "src/example/**"

Run `/audit-routing-table` to verify routing health.
```

**`subagent`: register plus overrides:**

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

**`skill` target:**

```
Registered `<name>` as a skill routing target.

Target type: skill
Skill: <skill-slug>

When the Tech Lead matches this entry during Phase 1, it emits:
  **Target Type:** skill
  **Skill:** <skill-slug>

For manual orchestration: invoke `/[skill-slug]` with the emitted prompt and
feed the result back to Phase 2 for synthesis. Note: `/plan-implementation`
currently surfaces `skill` targets to the user rather than dispatching them
automatically; full target-type dispatch is a planned follow-up change. See
the README "Routing Target Types" section for the full dispatch pattern.

Run `/audit-routing-table` to verify routing health.
```

**`doc` target:**

```
Registered `<name>` as a doc routing target.

Target type: doc
Doc: <file-path>

When the Tech Lead matches this entry during Phase 1, it emits:
  **Target Type:** doc
  **Doc:** `<file-path>`

The plan will note "Read `<file-path>` before starting." No automated dispatch.

Run `/audit-routing-table` to verify routing health.
```

**`human` target:**

```
Registered `<name>` as a human escalation target.

Target type: human
Contact: <contact-identifier>

When the Tech Lead matches this entry during Phase 1, it emits:
  **Target Type:** human
  **Contact:** <contact-identifier>

The plan will pause with an explicit escalation notice. The user owns the
handoff to <contact-identifier>.

Run `/audit-routing-table` to verify routing health.
```

**`external-agent` target:**

```
Registered `<name>` as an external-agent routing target.

Target type: external-agent
Agent: <plugin:agent-slug>

When the Tech Lead matches this entry during Phase 1, it emits:
  **Target Type:** external-agent
  **Agent:** `<plugin:agent-slug>`

The caller should spawn the agent via the Agent tool with the namespaced slug.

Run `/audit-routing-table` to verify routing health.
```

If any overrides were skipped (redundant), list them and explain what was
preserved.

For the full per-type handling patterns, see the
[Routing Target Types](../../README.md#routing-target-types) section of the
top-level README.
