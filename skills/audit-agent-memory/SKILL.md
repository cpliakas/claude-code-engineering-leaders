---
name: audit-agent-memory
description: "Audit a single agent's project memory directory for hygiene issues. Use when you want to run agent memory hygiene checks, audit memory, inspect bloated memory, or detect state-like content, dead links, or oversized memory files. When the audited agent is the tech-lead, also audits the specialist routing model: use it to audit the routing table, check routing health, or find orphan overrides, broken file pointers, redundant overrides, and thin agent descriptions — run it after onboarding, after adding specialists, or when /plan-implementation appears to be missing specialist matches. This skill is read-only and advisory: it does not modify any file."
user-invokable: true
argument-hint: "<agent-name>"
allowed-tools: Read, Glob, Grep
---

# Audit Agent Memory

Audit one agent's project memory directory for four categories of hygiene
issues. When the audited agent is the `tech-lead`, additionally audit the
specialist routing model in its memory for four more categories. Produces a
structured advisory report with recommended actions. Does not modify any
files.

If invoked without an argument, report:

```
Usage: /audit-agent-memory <agent-name>

Example: /audit-agent-memory qa-lead

Provide the agent name (e.g. qa-lead, tech-lead, product-owner) to audit
that agent's project memory directory.
```

And exit without reading any file.

## Process

### 1. Read Memory

Derive the memory directory path from the argument:

```
.claude/agent-memory/engineering-leaders-<agent-name>/
```

Attempt to read `.claude/agent-memory/engineering-leaders-<agent-name>/MEMORY.md`.

If the directory or `MEMORY.md` does not exist, report:

```
No memory directory found at .claude/agent-memory/engineering-leaders-<agent-name>/.
Run /onboard to create one.
```

Tailor the second sentence to skills that actually exist:

- When `<agent-name>` is `tech-lead`, say instead: "Run /onboard or
  /add-specialist to create one." (Registering a specialist also creates the
  Tech Lead's memory file.)
- Append "or /onboard-<agent-name>" only when the plugin ships a companion
  onboarding skill for that agent (currently only `/onboard-product-owner`).
  Never name an `/onboard-<agent-name>` skill that does not exist.

And exit.

Glob the directory for all `*.md` files:

```
.claude/agent-memory/engineering-leaders-<agent-name>/*.md
```

Read every `*.md` file found. Collect:

- The content of `MEMORY.md` (used for dead-link detection)
- The content and byte size of every `*.md` file (used for Check 4 (size))
- A list of all `*.md` file paths found (used for dead-link detection)

### 2. Run Checks

Run the four hygiene checks below against the collected files. Each check
records findings independently. A single file can produce findings under
multiple checks. When the audited agent is `tech-lead`, also run the routing
model checks (Checks 5–8).

#### Check 1: State-Like Content

**Heuristic:** A file contains state-like content if it matches any of the
following patterns:

**Dated phrases (any of these strings, case-insensitive):**

- `as of`
- `last quarter`
- `last month`
- `last sprint`
- `this quarter`
- `this month`
- `this sprint`
- `current sprint`
- `current phase`
- `in progress`
- `blocked by`
- `Q1`, `Q2`, `Q3`, `Q4` followed by a four-digit year (e.g. `Q3 2025`)

**Enumerated file paths:** Three or more lines in the file that match the
pattern `path/to/file` (a sequence of path segments separated by `/`, not
starting with `http`). Count consecutive or near-consecutive path-formatted
lines; if three or more appear in the file, this heuristic triggers.
Threshold: **3 or more enumerated paths**.

**Enumerated issue IDs:** Three or more tokens matching the pattern
`[A-Z][A-Z0-9]+-\d+` or `[a-z][a-z0-9]+-\d+` (e.g. `PROJ-42`, `bd-7`,
`INGEST-123`). Threshold: **3 or more issue IDs**.

**Work-item tables:** A markdown table whose column headings contain any of:
`owner`, `due`, `status`, `assignee`, `priority`, `eta`.

For each finding:

- Quote the triggering phrase, count, or column name.
- Record severity as **state** (downgraded to **mixed** if Check 2 also
  triggers on the same file (see below).
- Recommended action: "Consider moving this content to the project's issue
  tracker or a dated artifact. If the content is no longer current, consider
  removing it."

#### Check 2: Strategy-Like Content (Negative Check)

**Heuristic:** A file contains strategy-like content if it matches any of
the following patterns (case-insensitive):

- Contains a line or heading with `why` followed by a rationale paragraph
  (e.g. `## Why`, `**Why:**`, `why:`)
- Contains the word `invariant` or `invariants`
- Contains the word `principle` or `principles`
- Contains `routing rule` or `routing:`
- Contains `policy` or `policies`
- Contains `definition:` or `definition of`

**Downgrade rule:** If a file triggers Check 1 (state-like) AND Check 2
(strategy-like), report it at severity **mixed** rather than **state**.
Mixed findings still appear in the Findings section under their own subheading.

Strategy-like files that do NOT trigger Check 1 produce no finding; they are
healthy and expected.

#### Check 3: Dead Links

**Heuristic:** A `*.md` file in the memory directory is a dead link (orphan)
if it is not referenced from `MEMORY.md`.

Detection procedure:

1. Parse `MEMORY.md` for all relative file references. A reference is any
   markdown link of the form `[text](filename.md)` or a bare filename ending
   in `.md` that appears on its own line or as a list item.
2. Also collect any filenames that appear in the frontmatter or in plain text
   that clearly match the `*.md` glob (e.g. `memory.md`, `routing.md`).
3. Build the set of referenced filenames (basename only, case-sensitive).
4. Compare against the full list of `*.md` files found by the glob in Process Step 1 (Read Memory).
5. Flag any file whose basename is NOT in the referenced set. `MEMORY.md`
   itself is excluded from this check (it is the index, not a linked file).

For each orphan file:

- Name the file path.
- Recommended action: "This file is not referenced from MEMORY.md. Consider
  adding a link in MEMORY.md if the content is still relevant, or removing
  the file if it is stale."

#### Check 4: Size

**Heuristic thresholds (tokens estimated as byte count divided by 4):**

- **Single-file threshold:** 4,000 tokens (approximately 16,000 bytes)
- **Directory threshold:** 10,000 tokens (approximately 40,000 bytes)

Procedure:

1. For each `*.md` file, compute `byte_count` from the file content length.
   Estimate `token_count = byte_count / 4` (integer division).
2. Sum all per-file token estimates to produce `directory_token_count`.
3. Flag any individual file whose `token_count` exceeds **4,000 tokens**.
4. Flag the directory if `directory_token_count` exceeds **10,000 tokens**.

For each size finding:

- State the observed estimate and the threshold (e.g. "estimated 5,200 tokens;
  threshold is 4,000 tokens per file").
- Recommended action: "Consider reviewing this file for content that can be
  moved to an issue tracker, removed as stale, or condensed. Large memory files
  raise per-turn token costs for every agent invocation."

#### Routing Model Checks (tech-lead only)

Run Checks 5–8 only when the audited agent is `tech-lead`. For any other
agent, skip them and omit their rows and report sections entirely.

These checks audit the Tech Lead's specialist routing model — the registry
that `/plan-implementation` reads to match and dispatch specialists. Run them
after onboarding, after adding specialists, or when `/plan-implementation`
appears to be missing specialist matches.

Parse two sections from `MEMORY.md`:

- **Registered Specialists** — extract the list of `<agent-name>` and optional
  `<path>` from each bullet. Default path is `agents/<agent-name>.md` when no
  path is given.
- **Project Code Area Overrides** — extract each `| signal | agent-name |` row
  from the table, ignoring the header and separator rows.

If neither section exists, skip Checks 5–8 and, in the report, emit the
following notice in place of the routing summary lines, routing table, and
routing findings subsections:

```
No routing model sections found in the Tech Lead's memory. Run /onboard or
/add-specialist to register specialists. (If this memory file still uses the
pre-0.12.0 `## Specialist Routing Table` format, see MIGRATION.md in this
skill's directory for the conversion path.)
```

##### Check 5: Orphan Overrides

For each row in `## Project Code Area Overrides`, verify the target agent name
appears in `## Registered Specialists`.

**Finding:** override row targets `<agent-name>` which is not in `## Registered
Specialists`.

**Recommended action:** Either register the agent with `/add-specialist
<agent-name>` or remove the orphan override row.

##### Check 6: Broken Pointers

For each entry in `## Registered Specialists`, attempt to read the agent file
at the specified path (or `agents/<agent-name>.md`).

Use Glob to check whether the file exists. If the file is not found:

**Finding:** registered specialist `<agent-name>` points to `<path>` which does
not exist.

**Recommended action:** Correct the path in `## Registered Specialists`, or
remove the entry if the specialist is no longer used. If the agent is from an
external plugin that is not installed locally, this may be expected — verify
with the plugin author.

##### Check 7: Redundant Overrides

For each row in `## Project Code Area Overrides` where the target agent's file
is readable:

1. Read the agent file.
2. Extract the `description` field from the frontmatter.
3. Check whether the override signal appears verbatim (case-insensitive) in the
   description body.

If found:

**Finding:** override signal `<signal>` for `<agent-name>` already appears in
the agent's description.

**Recommended action:** Remove this override row. `/plan-implementation` will
match the signal via description matching, so the override is unnecessary and
creates maintenance surface. This row will be re-flagged on every audit until
removed.

##### Check 8: Thin Descriptions

For each entry in `## Registered Specialists` where the agent file is readable:

1. Extract the `description` field from the frontmatter.
2. Count the non-whitespace word count of the description body. Exclude the
   YAML scalar delimiter (`|`), the `name:` header line, and `<example>` /
   `<commentary>` blocks.

If the word count is below 60:

**Finding:** registered specialist `<agent-name>` has a thin description (fewer
than 60 words after stripping markup).

**Recommended action:** Enrich the agent's description with more trigger
phrases, example-context phrases, and jurisdiction keywords so
`/plan-implementation` can match it reliably via description matching. A thin
description means the skill may miss relevant consultations.

### 3. Compute Size Summary

After running all checks, compute the summary figures:

- Total files scanned (count of `*.md` files)
- Total estimated tokens (`directory_token_count`)
- Findings per check: state-like count, mixed count, dead-link count,
  size-flag count
- When auditing `tech-lead`: registered specialist count, override row count,
  and findings per routing check (orphan overrides, broken pointers,
  redundant overrides, thin descriptions)

### 4. Emit Report

Output the report in the following fixed structure. Omit any `## Findings`
subheading for which no finding was produced.

```markdown
## Summary

Memory directory: .claude/agent-memory/engineering-leaders-<agent-name>/
Files scanned: <N>
Estimated tokens: <T> (threshold: 10,000 for the directory)

| Check         | Findings |
|---------------|----------|
| State-like    | <N>      |
| Mixed         | <N>      |
| Dead links    | <N>      |
| Size          | <N>      |

[When auditing tech-lead, append these lines and rows. If no routing model
sections were found (see Process Step 2), emit the no-routing-model notice
here instead and omit the routing lines, table, and findings subsections:]

Registered specialists: <N>
Override rows: <M>

| Routing check       | Findings |
|---------------------|----------|
| Orphan overrides    | <N>      |
| Broken pointers     | <N>      |
| Redundant overrides | <N>      |
| Thin descriptions   | <N>      |

## Findings

### State-like content

- **`<file-path>`**: <triggering phrase or count quoted verbatim>
  Consider moving this content to the project's issue tracker or a dated
  artifact. If the content is no longer current, consider removing it.

### Mixed content (state + strategy signals)

- **`<file-path>`**: contains both state signals (<trigger>) and strategy
  signals (<trigger>). Review to confirm which parts remain load-bearing.
  Consider extracting the state portion to a tracker entry and keeping only
  the strategic rationale.

### Dead links

- **`<file-path>`**: not referenced from MEMORY.md.
  Consider adding a link in MEMORY.md if the content is still relevant, or
  removing the file if it is stale.

### Size

- **`<file-path>`**: estimated <T> tokens (threshold: 4,000 per file).
  Consider reviewing for content that can be moved to a tracker, removed as
  stale, or condensed.

- **Directory total**: estimated <T> tokens (threshold: 10,000 for the
  directory). Review the memory directory as a whole for accumulation.

### Orphan overrides (tech-lead only)

- **`<signal>` → `<agent-name>`**: agent not in Registered Specialists.
  Register with `/add-specialist <agent-name>` or remove this row.

### Broken pointers (tech-lead only)

- **`<agent-name>`**: agent file not found at `<path>`.
  Correct the path or remove the entry.

### Redundant overrides (tech-lead only)

- **`<signal>` → `<agent-name>`**: signal appears in the agent's description.
  Remove this override row.

### Thin descriptions (tech-lead only)

- **`<agent-name>`**: description is <W> words (threshold: 60).
  Add trigger phrases, example contexts, and jurisdiction keywords to the
  agent's description.

## Recommendations

[If no findings: "No hygiene issues detected. The memory directory for
<agent-name> appears healthy."]

[If findings exist, list options using suggestive language:]

- If any state-like files are no longer current, consider removing them or
  moving their content to the project's issue tracker.
- If any mixed files contain both strategic context and dated state, consider
  splitting them: keep the invariant or policy language in memory and move the
  dated items to a tracker or dated artifact.
- If dead-link files contain content you want to keep, add a reference in
  MEMORY.md. If the content is stale, consider deleting the file.
- If the directory or individual files exceed the size thresholds, review for
  accumulation. Smaller, strategy-focused memory reduces per-invocation token
  cost for every session.
- If any routing findings exist (tech-lead only), address each one manually —
  no auto-fix occurred — then re-run `/audit-agent-memory tech-lead` to
  verify.

## Next Step

[Single sentence pointing to the highest-priority action:]

[If dead links exist:] Review the dead-link files first. Orphaned files may
be loading on every invocation without being indexed.

[Else if state-like or mixed findings exist:] Review the state-like files and
consider moving dated content to the project's issue tracker.

[Else if only size findings exist:] Review the largest files and consider
condensing or pruning content that is no longer load-bearing.

[Else if only routing findings exist:] Address the routing findings above,
then re-run `/audit-agent-memory tech-lead` to verify routing health.

[If no findings:] No action required. Run this audit again after the next
onboarding session or when the agent feels slower than expected.
```

All output is advisory. No file is read twice; no file is written, edited, or
deleted. The user decides what to act on.

## Migration Use

The routing checks double as a migration helper for projects converting the
Tech Lead's memory from the old pre-0.12.0 `## Specialist Routing Table`
format. See `MIGRATION.md` in this skill directory for the step-by-step
migration path.
