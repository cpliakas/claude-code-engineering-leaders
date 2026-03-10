---
name: analyze-code-churn
description: "Analyze code churn and thrash patterns in a git repository. Produces a structured report with hotspot detection, rework classification, temporal coupling, and severity-rated findings. Use for SDLC health checks, sprint retrospectives, or when recurring friction surfaces in code reviews."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "[time window (e.g., '30 days', '2 sprints'), optional: path filter, optional: focus area]"
---

# Analyze Churn

Analyze code churn and thrash patterns in a git repository. Produces a structured
report with hotspot detection, rework vs. refactor classification, temporal
coupling analysis, and severity-rated findings with investigation recommendations.

## Input

`$ARGUMENTS` = analysis scope — time window (e.g., "30 days", "last sprint",
"since v2.1"), optional path filter (e.g., "src/api/"), and optional focus area
(e.g., "why is auth churning", "sprint-over-sprint comparison").

## Process

### 1. Parse Scope

Extract from `$ARGUMENTS`:

- **Time window**: Default to 30 days if not specified. Accept natural language
  ("last sprint", "since January") and convert to `--since`/`--after` git flags.
- **Path filter**: If a directory or file pattern is specified, scope all git
  commands to that path. Default to the entire repository.
- **Focus area**: If a specific question is asked, tailor the analysis toward
  answering it. Otherwise, produce the full report.

If `$ARGUMENTS` is empty, use a 30-day window across the entire repository.

### 2. Establish Baseline

Run the baseline period (the window immediately preceding the analysis window)
to enable trend comparison. For a 30-day analysis window, the baseline is the
prior 30 days.

**Gross churn (analysis window):**

```bash
git log --numstat --format="" --no-merges --since="<start>" -- <path> \
  | awk '{a+=$1; d+=$2} END {print "added:", a, "deleted:", d, "gross:", a+d}'
```

**Gross churn (baseline window):**

```bash
git log --numstat --format="" --no-merges --since="<baseline_start>" --until="<start>" -- <path> \
  | awk '{a+=$1; d+=$2} END {print "added:", a, "deleted:", d, "gross:", a+d}'
```

**Commit counts (both windows):**

```bash
git rev-list --count --no-merges --since="<start>" HEAD -- <path>
git rev-list --count --no-merges --since="<baseline_start>" --until="<start>" HEAD -- <path>
```

Record the baseline metrics for trend comparison in Step 7.

### 3. Detect Hotspots

Identify files with the highest change frequency, weighted by size as a
complexity proxy.

**Change frequency (top 20):**

```bash
git log --format=format: --name-only --no-merges --since="<start>" -- <path> \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -20
```

**Lines-based churn per file (top 20):**

```bash
git log --no-merges --numstat --format="" --since="<start>" -- <path> \
  | awk '{files[$3]+=$1+$2; added[$3]+=$1; deleted[$3]+=$2} END {for(f in files) printf "%d\t+%d\t-%d\t%s\n", files[f], added[f], deleted[f], f}' \
  | sort -rn | head -20
```

**Exclusions:** Filter out auto-generated files from results before ranking:

- Lock files (`package-lock.json`, `yarn.lock`, `Gemfile.lock`, `poetry.lock`,
  `go.sum`, `Cargo.lock`, `pnpm-lock.yaml`)
- Build artifacts and compiled output
- Formatting-only changes (if detectable from commit messages)
- Files matching patterns in `.gitignore` that are tracked

Rank files by a composite hotspot score:
`change_frequency × log2(max(lines_churned, 1))`. Use base-2 logarithm;
floor `lines_churned` to 1 to avoid undefined values when a file has only
renames or mode changes. The top 5 files are the **hotspot list**.

### 4. Detect Thrashing

Identify files modified with unusual frequency in short windows — a signal of
rework, unclear requirements, or architectural coupling.

**Files modified 5+ times in the last 7 days:**

```bash
git log --format=format: --name-only --no-merges --since="7 days ago" -- <path> \
  | grep -v '^$' | sort | uniq -c | sort -rn | awk '$1 >= 5 {print}'
```

**Files modified 3+ times in the last 3 days** (tighter window for acute thrash):

```bash
git log --format=format: --name-only --no-merges --since="3 days ago" -- <path> \
  | grep -v '^$' | sort | uniq -c | sort -rn | awk '$1 >= 3 {print}'
```

Files appearing in both lists are **thrashing candidates** — flag for
investigation.

### 5. Classify Changes (Rework vs. Refactor)

Use a 21-day age threshold to classify changes within the analysis window:

- **New Code**: Files created within the analysis window
- **Refactor**: Changes to code that was last modified more than 21 days ago
  (healthy maintenance)
- **Rework**: Changes to code that was last modified fewer than 21 days ago
  (potential waste signal — the same code was touched again before it had time
  to stabilize)

**Rework detection procedure:**

For each file in the hotspot list (Step 3), retrieve its commit dates within
the analysis window:

```bash
# For each hotspot file, list commit dates within the analysis window
git log --format="%H %ad" --date=short --no-merges --since="<start>" -- <file> \
  | head -20
```

Walk the date-sorted output and compare consecutive commits to the same file.
If two commits to the same file are fewer than 21 days apart, classify the
later commit as rework. A file with only one commit in the window, or with all
commits spaced more than 21 days apart, contributes zero rework commits.

Calculate:

- **Rework rate** = rework commits / total commits (across the analysis window)
- Compare against the baseline window's rework rate

**Revert detection:**

```bash
git log --oneline --grep="[Rr]evert" --no-merges --since="<start>" -- <path>
```

Reverts are the strongest rework signal. List each with the original commit
it reversed.

### 6. Detect Temporal Coupling

Identify files that change together — a signal of hidden dependencies or
architectural coupling when the files are in different modules.

```bash
git log --format='---' --name-only --no-merges --since="<start>" -- <path> \
  | awk '/^---$/{if(n>0){for(i=0;i<n;i++)for(j=i+1;j<n;j++)print files[i]"\t"files[j]}; n=0;next} /^$/{next} {files[n++]=$0}' \
  | sort | uniq -c | sort -rn | head -30
```

**Coupling threshold:** Flag pairs that appear together in >30% of either
file's total commits during the window. Coupling between files in the same
module is expected; coupling between files in different modules or layers is
a signal.

For each flagged pair, note:

- Co-change count and percentage
- Whether the files are in the same module/directory
- Whether the coupling is expected (e.g., a component and its test file) or
  unexpected (e.g., a controller and an unrelated model)

### 7. Assess Severity

Apply severity ratings based on deviation from the project's own baseline,
not industry averages.

| Severity | Pattern | Action |
| --- | --- | --- |
| **Normal** | Within baseline ±5%, early-sprint churn, expected refactoring | Monitor; note baseline for future comparison |
| **Watch** | 5–10% above baseline, 1–2 hotspot files, mid-sprint | Mention in standup; check requirements clarity for affected files |
| **Concerning** | >10% above baseline for current + prior window, 3+ hotspot files | 1:1s with contributors to the hotspot files; review affected PRs; assess deadline risk |
| **Critical** | Multiple reverts, same files thrashing 5+x/week, rework rate >2× baseline | Escalate delivery risk; recommend architecture review of affected area; consider scope reduction |

**Context modifiers** (adjust severity interpretation):

- Early-stage/MVP: Higher churn is normal (25–40%). Widen the Normal band.
- Major refactoring in progress: Elevated churn is expected. Note it but don't
  alarm.
- Near a deadline: Even moderate churn elevation is more concerning.
- New team members: Expect temporary rework elevation in their areas.

Always state the modifier when applying it, so the reader understands why
severity was adjusted.

### 8. Identify Root Cause Signals

For each finding rated Watch or above, map to likely root cause patterns:

| Signal | Likely Root Cause | Investigation Path |
| --- | --- | --- |
| Churn concentrated in 1–2 files | Architectural coupling or unclear ownership | Review temporal coupling data; check if file should be split |
| Churn scattered across codebase | Systemic issue (weak tests, unclear requirements) | Review test coverage trends; check story quality for affected work |
| Churn correlated with specific contributors | Knowledge gap or onboarding ramp | Review PR comments for guidance patterns; suggest pairing |
| Churn spiking near sprint end | Process problem (late requirements, scope creep) | Review story completion dates vs. sprint timeline |
| Revert patterns | Fundamental misalignment between intent and execution | Review the original PR and what it aimed to do vs. what happened |
| Unexpected temporal coupling | Hidden architectural dependency | Review whether the coupled files share a concept that should be extracted |

**Critical constraint:** Never attribute churn to individual developer
performance. Churn is a system signal. Frame contributor patterns as "areas
where additional support may help" — not as individual performance issues.

### 9. Produce Report

Format the output using the template below.

## Output

```markdown
# Code Churn Analysis

**Repository**: [repo name]
**Analysis window**: [start] – [end] ([N] days)
**Baseline window**: [start] – [end] ([N] days)
**Path scope**: [path or "entire repository"]
**Generated**: [date]

## Executive Summary

[2–3 sentences: overall severity, key finding, primary recommendation. Lead
with the most important signal.]

## Trend Comparison

| Metric | Baseline | Current | Change |
|--------| --- | --- | --- |
| Gross churn (lines) | [N] | [N] | [+/-N%] |
| Commits | [N] | [N] | [+/-N%] |
| Rework rate | [N%] | [N%] | [+/-N pp] |
| Reverts | [N] | [N] | [+/-N] |

**Trend assessment**: [Normal / Elevated / Concerning — with brief rationale]

## Hotspot Files

| Rank | File | Changes | Lines Churned | Hotspot Score | Severity |
|------|------|---------|---------------|---------------|----------|
| 1 | [path] | [N] | [N] | [score] | [severity] |
| 2 | [path] | [N] | [N] | [score] | [severity] |

[Up to 10 files. Only include files with Watch severity or above, plus the
top 5 regardless of severity for context.]

## Thrashing Files

[Files modified 5+ times in 7 days or 3+ times in 3 days.]

| File | Changes (7d) | Changes (3d) | Status |
|------|-------------|-------------|--------|
| [path] | [N] | [N] | [Thrashing / Elevated / —] |

[If no thrashing detected, state "No thrashing patterns detected in the
analysis window." and omit the table.]

## Rework Classification

**Rework rate**: [N%] (baseline: [N%])

| Classification | Commits | Percentage |
|----------------|---------|------------|
| New code | [N] | [N%] |
| Refactor (>21 days) | [N] | [N%] |
| Rework (<21 days) | [N] | [N%] |

**Reverts**: [N] in analysis window

[List each revert with the original commit reference if any were found.]

## Temporal Coupling

[Pairs of files that change together above the 30% threshold.]

| File A | File B | Co-changes | Coupling % | Expected? |
|--------|--------|-----------|------------|-----------|
| [path] | [path] | [N] | [N%] | [Yes/No — brief reason] |

[If no unexpected coupling detected, state "No unexpected temporal coupling
detected." and omit the table.]

## Findings

[Ordered by severity, highest first. Each finding follows this structure:]

### [Finding title] — [Severity]

**Signal**: [What was detected — specific files, metrics, patterns]

**Likely root cause**: [From the root cause mapping table]

**Investigation path**: [Specific next steps to confirm or dismiss]

**Context modifiers**: [Any factors that adjust severity interpretation]

[Repeat for each finding rated Watch or above.]

## Recommendations

[Prioritized list of suggested actions. Each traces to a specific finding.]

1. **[Action]** — [Which finding this addresses]. [Specific next step.]
2. **[Action]** — [Finding reference]. [Next step.]

[Maximum 5 recommendations. If everything is Normal, state "No action items.
Current churn patterns are within baseline expectations." and omit the list.]
```

After the report, include a brief **"Methodology Notes"** section (outside
the report body) explaining:

1. The 21-day rework window and why it was chosen (industry standard per
   LinearB, Code Climate)
2. That severity is calibrated against the project's own baseline, not
   industry benchmarks
3. Any files or patterns that were excluded and why
4. That churn metrics are signals for investigation, not verdicts — human
   context is required to interpret them correctly
