---
name: audit-agent-memory
description: "Audit a single agent's project memory directory for hygiene issues. Use when you want to run agent memory hygiene checks, audit memory, inspect bloated memory, or detect state-like content, dead links, or oversized memory files. Complements /audit-routing-table, which audits the Tech Lead's specialist routing model. This skill is read-only and advisory: it does not modify any file."
user-invokable: true
argument-hint: "<agent-name>"
allowed-tools: Read, Glob, Grep
---

# Audit Agent Memory

Audit one agent's project memory directory for four categories of hygiene
issues. Produces a structured advisory report with recommended actions. Does
not modify any files.

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
Run /onboard or /onboard-<agent-name> to create one.
```

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

Run the four checks below against the collected files. Each check records
findings independently. A single file can produce findings under multiple
checks.

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

### 3. Compute Size Summary

After running all checks, compute the summary figures:

- Total files scanned (count of `*.md` files)
- Total estimated tokens (`directory_token_count`)
- Findings per check: state-like count, mixed count, dead-link count,
  size-flag count

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

## Next Step

[Single sentence pointing to the highest-priority action:]

[If dead links exist:] Review the dead-link files first. Orphaned files may
be loading on every invocation without being indexed.

[Else if state-like or mixed findings exist:] Review the state-like files and
consider moving dated content to the project's issue tracker.

[Else if only size findings exist:] Review the largest files and consider
condensing or pruning content that is no longer load-bearing.

[If no findings:] No action required. Run this audit again after the next
onboarding session or when the agent feels slower than expected.
```

All output is advisory. No file is read twice; no file is written, edited, or
deleted. The user decides what to act on.
