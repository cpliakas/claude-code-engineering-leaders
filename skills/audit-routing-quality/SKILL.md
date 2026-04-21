---
name: audit-routing-quality
description: "Audit the Tech Lead's specialist routing quality by reading the ## Routing Outcomes history and recommending narrowing actions for over-routed specialists. Complements /audit-routing-table (structural hygiene) with outcome-based data. Advisory only: never edits the routing table. Use when you want data-driven evidence for tightening specialist trigger descriptions or removing over-broad Code Area Overrides."
user-invokable: true
argument-hint: ""
allowed-tools: Read, Glob, Grep, Edit
---

# Audit Routing Quality

Read the Tech Lead's `## Routing Outcomes` history and produce a report
recommending narrowing actions for specialists that are consistently over-routed.
Advisory only: this skill never modifies `## Registered Specialists`,
`## Project Code Area Overrides`, or any specialist agent file.

## How This Complements `/audit-routing-table`

| Skill | Input | Purpose | When to run |
|-------|-------|---------|-------------|
| `/audit-routing-table` | Memory file structure and agent files | Structural hygiene (orphan overrides, broken pointers, redundant overrides, thin descriptions) | After onboarding, after adding specialists, when routing seems broken |
| `/audit-routing-quality` | `## Routing Outcomes` history | Outcome-based narrowing (specialists consulted frequently but adding no value) | After accumulating outcome history, when routing feels noisy |

The two skills complement each other. Run `/audit-routing-table` to fix
structural problems; run `/audit-routing-quality` to tighten trigger fit based
on data.

## Process

### Step 1: Read the Memory File

Read `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`.

**Missing memory file:**

```
No Tech Lead memory file found. Run /onboard or /add-specialist to create one.
```

Exit without error.

**Missing or empty `## Routing Outcomes` section:**

```
No routing outcome history recorded yet. Run /plan-implementation on a story
that routes to specialists, then return to /audit-routing-quality once outcome
rows have been appended.
```

Exit without error.

### Step 2: Parse the `## Routing Outcomes` Table

Extract every data row from the `## Routing Outcomes` table. Ignore the header
row and the separator row. For each data row, parse the five columns:
`Date`, `Story Slug`, `Specialist`, `Value`, `Note`.

Skip ROLLUP rows (where `Story Slug` is `ROLLUP`) for the purpose of
aggregation. They summarize already-compressed history and their counts are
not double-counted.

### Step 3: Aggregate Per Specialist

For each unique specialist, compute:

- **Total consultations:** row count (excluding ROLLUP rows).
- **Per-value counts:** `high`, `medium`, `low`, `none`.
- **Narrowing-signal score:** `(low + none)` expressed as a percentage of
  total consultations. Also record the absolute `(low + none)` count.
- **Most-recent low/none notes:** up to five `Note` values from `low` and
  `none` rows, ordered by `Date` descending, for use in the recommendations
  section.

### Step 4: Check Retention Threshold

If the total row count (excluding ROLLUP rows) exceeds 200, offer the user
a roll-up before producing the report:

```
The ## Routing Outcomes table contains <N> rows (threshold: 200). A roll-up
would condense the oldest <N-50> rows (everything except the most-recent 50)
into one summary row per specialist.

Would you like to proceed with a roll-up before reviewing recommendations?
(yes / no)
```

Wait for a user response.

- **If the user declines (or does not respond affirmatively):** Skip the
  roll-up and proceed to Step 5 using the full history.
- **If the user confirms:** Perform the roll-up as described in the Roll-Up
  Procedure section below, then reload the table and proceed to Step 5 using
  the condensed history.

### Step 5: Apply Recommendation Thresholds

A specialist is flagged for a narrowing recommendation when both conditions
hold:

1. **Minimum consultations:** total >= 5.
2. **Narrowing-signal threshold:** `(low + none)` >= 50% of total.

A specialist below either threshold is recorded in the "Specialists Below
Threshold" section of the report (no recommendation, just the data summary).

### Step 6: Build Recommendations

For each flagged specialist, produce a recommendation block. To build specific
narrowing-action suggestions:

1. Read the specialist's agent file (at the path recorded in
   `## Registered Specialists`, or `agents/<slug>.md` by default).
2. Extract the `description` field from the frontmatter.
3. Read `## Project Code Area Overrides` and extract any rows targeting this
   specialist.
4. Suggest one or more narrowing actions:

   - **Tighten description vocabulary:** identify trigger phrases in the
     description that appear over-broad relative to the stories this specialist
     over-matched. Suggest the specific phrase to remove or restrict.
   - **Remove redundant overrides:** list any `## Project Code Area Overrides`
     rows for this specialist that contributed to over-matching. Suggest the
     specific row to remove.
   - **Consider deregistering:** when the narrowing-signal score is >= 80%
     and total >= 10, note that deregistering the specialist is worth
     considering if no narrowing action sufficiently scopes the trigger.
   - **Add a negative-match pattern:** if the specialist matches many stories
     in a specific area it consistently grades `none`, suggest adding a
     negative-scope clause to the description (for example, "not relevant for
     documentation-only changes").

If the specialist's agent file cannot be read, surface a warning and produce a
general recommendation to review the agent's description and overrides
manually.

### Step 7: Produce the Report

Output a structured markdown report in this order and format. Running the
skill twice against the same memory file and threshold MUST produce reports
with the same flagged specialists and the same recommendations.

**Ordering rules (deterministic):**

- Narrowing Recommendations section: flagged specialists ordered by
  narrowing-signal score descending; ties broken by total consultation count
  descending; ties broken by specialist name alphabetically.
- Specialists Below Threshold section: ordered by total consultation count
  descending; ties broken by specialist name alphabetically.

```markdown
# Routing Quality Audit Report

Audited: .claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md
Total outcome rows: <N> (excluding ROLLUP rows)
Date range: <earliest-date> to <latest-date>
Specialists in history: <M>

---

## Narrowing Recommendations

[One subsection per flagged specialist, ordered by narrowing-signal score
descending.]

### <Specialist Name>

- **Consultations:** <total> (<high> high / <medium> medium / <low> low /
  <none> none)
- **Narrowing-signal score:** <X>% (`low` + `none` out of total)
- **Recent low/none notes:** <up to 5 notes from low/none rows, most recent
  first>
- **Suggested actions:**
  - <Specific narrowing action 1 — name the exact phrase or override row>
  - <Specific narrowing action 2>

---

## Specialists Below Threshold

[Specialists with data but below the minimum consultation count or
narrowing-signal threshold. Data shown so users can judge manually.]

| Specialist | Total | High | Medium | Low | None | Signal % |
|------------|-------|------|--------|-----|------|----------|
| <name>     | <N>   | <H>  | <M>    | <L> | <N0> | <X>%     |

---

## Next Actions

- To narrow over-routed specialists: apply the suggested actions above
  manually, then re-run `/audit-routing-quality` to verify the change.
- To fix structural issues (broken pointers, orphan overrides): run
  `/audit-routing-table`.
- To record more outcome history: run `/plan-implementation` on additional
  stories. Recommendations improve with more data (minimum five consultations
  per specialist).
```

## Roll-Up Procedure

Perform this procedure only when the user has explicitly confirmed the roll-up
offer in Step 4.

1. Determine the rows to roll up: all rows except the most-recent 50 by
   `Date` column (ascending sort; ties on date broken by file order). When the
   total row count is exactly 200 or fewer, do not offer a roll-up.
2. For each unique specialist among the rows to roll up, aggregate:
   - `high` count, `medium` count, `low` count, `none` count.
   - Source row count.
   - Date range: `<earliest-date>/<latest-date>` for the rows being rolled up.
3. Replace the rolled rows in the memory file with one summary row per
   specialist, using this format:

   ```markdown
   | <earliest-date>/<latest-date> | ROLLUP | <specialist> | high=<H> medium=<M> low=<L> none=<N> | summarized <count> rows |
   ```

   Roll-up rows sit above the preserved recent rows in file order so the
   table reads oldest-to-newest.
4. Preserve the most-recent 50 rows verbatim after the roll-up rows.
5. Write the updated table back to the memory file.
6. Confirm to the user: "Roll-up complete. <K> rows condensed into <J> summary
   rows. <50 or fewer> recent rows preserved."

If the write fails, surface a notice and continue to Step 5 using the full
history without roll-up.

## Graceful Degradation

- **Memory file missing:** emit the "No Tech Lead memory file found" notice
  and exit without error.
- **`## Routing Outcomes` section missing or empty:** emit the "No routing
  outcome history recorded yet" notice and exit without error.
- **Specialist agent file unreadable:** emit a warning, produce a general
  recommendation to manually review the specialist's description and overrides,
  and continue with remaining specialists.
- **All specialists below threshold:** produce the report with an empty
  Narrowing Recommendations section and the full below-threshold table. Note
  that more outcome history is needed before recommendations can be made.
