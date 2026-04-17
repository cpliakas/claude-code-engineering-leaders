# Design: Unify Specialist Routing Around Agent Descriptions

## Context

The Tech Lead's routing behavior depends on the `## Specialist Routing Table` in
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`. That table
currently stores two kinds of information in a single structure:

1. **Trigger vocabulary** — keywords and phrases that signal "this specialist
   is relevant" (examples: `authentication`, `test strategy`, `pipeline`).
2. **Project-specific code-area signals** — file globs and project-local
   keywords that identify where in this specific codebase a specialist applies
   (examples: `src/payments/**`, `webhooks/**`).

The first kind is already expressed in each specialist's `description` field.
The second kind is genuinely project-local.

By conflating the two, the current design forces contributors to restate
trigger vocabulary in a second location, which introduces silent drift.

## Design Principles

1. **One source of truth per piece of information.** Trigger vocabulary lives
   in the agent description. Project-specific code-area signals live in the
   project memory. Neither is restated in the other.
2. **Keep the Phase 1 output format stable.** The
   `/plan-implementation` skill's parser is contract-tied to the Phase 1
   markdown shape. Nothing in this change modifies that contract.
3. **Make the common case one-step.** Adding a specialist should be one
   command and touch one place.
4. **Fail loudly on missing pointers.** If `## Registered Specialists` points
   at an agent file that does not exist, the Tech Lead surfaces the condition
   and skips the specialist rather than silently omitting consultation.
5. **Audit, do not auto-mutate.** Hygiene tooling reports divergence and
   candidate removals; humans decide.

## Data Model

### `## Registered Specialists`

A bulleted list. Each entry identifies one specialist agent registered for this
project. Entries are formatted as:

```markdown
- `<agent-name>` — `<path-to-agent-file>`
```

The path is optional; if omitted, the default is `agents/<agent-name>.md`. The
path form supports specialists whose agent definitions live outside the current
repo (for example, installed from another plugin).

The list contains no trigger metadata. Every registered specialist is a
candidate for routing; the Tech Lead decides whether to emit a consultation
request based on the match against the agent's description and the overrides
table below.

### `## Project Code Area Overrides`

A markdown table with exactly two columns. Each row identifies a project-local
signal that should route to a specific registered specialist even if the
agent's description would not have matched:

```markdown
| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
| `src/payments/**`  | payments-specialist |
```

Invariants:

- Every specialist named in this table must appear in `## Registered
  Specialists`. Orphan rows are flagged by the audit skill.
- Signals should be project-local (file globs, repo-specific module names,
  internal terminology). Generic trigger phrases already in the specialist's
  description belong in the agent file, not here; the audit skill flags
  redundant rows.

## Matching Procedure

When the Tech Lead receives an issue and needs to produce Phase 1 routing
output, the new procedure is:

1. Read `## Registered Specialists` from the Tech Lead memory file. If the
   section is empty, emit the no-specialists notice documented in
   `agents/tech-lead.md:71-76` and proceed without consultation requests.
2. For each registered specialist, read the referenced agent file. If the file
   cannot be read, record a routing warning for that specialist and continue.
3. Build a match candidate set. A specialist is a match candidate if at least
   one of the following holds:
   - The issue text contains any of the trigger phrases, example-context
     phrases, or jurisdiction keywords from the agent's `description` field
     (case-insensitive substring match against a trimmed, lowercased copy of
     both sides)
   - The issue text or referenced file paths match any row in
     `## Project Code Area Overrides` whose target is this specialist
4. Emit a consultation request for each match candidate using the Phase 1
   output format already documented in `agents/tech-lead.md:114-149`.
5. If the Tech Lead's own assessment identifies a relevant domain that no
   registered specialist covers, record the gap in `## Implementation
   Constraints` (Phase 1) or `## Escalation Flags` (Phase 2) but do not invent
   a consultation request for a specialist that is not registered.

### Matching Precision

Substring matching against the full description body is intentionally loose in
this design. The alternatives considered below discuss why.

## Skill Changes

### `/add-specialist`

New argument handling:

- **1 argument** — `<agent-name>`. Register the agent with no overrides.
- **2+ arguments** — `<agent-name> <override-1> [<override-2> ...]`. Register
  the agent and add one overrides row per trailing argument.

Validation:

- Agent name must resolve to a readable file at the default or provided path.
- Each override argument is checked against the target agent's description; if
  the override text appears in the description (case-insensitive), the skill
  warns the user and asks whether to proceed (since the row would be redundant
  per the audit rules).

### `/onboard` Step 4

The per-specialist signal question is removed. The new flow:

> "List any specialist agent names the Tech Lead should know about, or say
> 'none'."

For each name, the skill calls `/add-specialist <name>` with no overrides.
Users who want code-area overrides add them after onboarding with explicit
`/add-specialist` calls.

### `/audit-routing-table` (new)

Inputs: none.

Checks:

1. **Orphan overrides** — rows in `## Project Code Area Overrides` whose
   target specialist is not in `## Registered Specialists`.
2. **Broken pointers** — entries in `## Registered Specialists` whose
   referenced file cannot be read.
3. **Redundant overrides** — override rows whose signal string appears
   verbatim (case-insensitive) in the target agent's description.
4. **Thin descriptions** — registered specialists whose description body is
   under a small threshold (suggested: fewer than 60 non-whitespace words).
   A thin description weakens substring matching; this check exists so users
   can proactively enrich the description rather than relying on the overrides
   table as a workaround.

Output: a human-readable report with each finding, an explanation, and a
recommended action. No auto-fix.

## Tech Lead Memory File Migration

A migration path, not automated:

1. Run `/audit-routing-table` against the current project.
2. For each row in the current `## Specialist Routing Table`:
   - If the signal is a file glob or project-local keyword not already in the
     agent description, move it to `## Project Code Area Overrides`.
   - If the signal duplicates trigger vocabulary already in the agent
     description, delete it.
   - If the specialist is not yet in `## Registered Specialists`, add it.
3. Re-run `/audit-routing-table`. Address any remaining findings.

This is intentionally manual. Automated migration risks silently deleting rows
whose purpose is not obvious.

## Failure Modes

| Condition | Behavior |
| --- | --- |
| `## Registered Specialists` missing or empty | Tech Lead emits the existing no-specialists notice; Phase 1 produces no consultation requests. |
| Registered specialist's agent file unreadable | Skip the specialist; record a routing warning in Phase 1 output. Do not fall back to the overrides table alone. |
| Overrides table references an unregistered specialist | Skip the row; audit skill flags it as orphan. Do not auto-register. |
| Issue text does not match any description but matches an override | Emit a consultation request for the override's target specialist. This is the intended use of the overrides table. |
| Issue text matches multiple specialists | Emit a consultation request for each. Phase 1 output already supports multiple specialists. |
| `/add-specialist` called with trigger-keyword style arguments (e.g., `authentication`) | Accept the input (backward compatible) but warn that trigger vocabulary belongs in the agent description. |

## Alternatives Considered

- **Structured routing metadata in agent frontmatter.** Out of scope per issue
  #6. Would be the cleanest long-term design but requires coordinated changes
  to every specialist plugin.
- **Generate the routing table from agent descriptions at refresh time (issue
  Option 1).** Produces a derived file that invites hand-edits. The audit skill
  would have to detect edits to the derived file and roll them back, which
  creates an awkward user experience. Better to skip the derived file
  entirely.
- **Exact-keyword matching against a curated list extracted from each agent
  description.** Considered for matching precision, but requires authors to
  mark keywords explicitly (schema change) or the Tech Lead to guess which
  tokens are keywords (heuristic fragility). Substring matching against the
  whole description trades a small amount of recall precision for zero schema
  burden.
- **Keep the current table and add `/audit-routing-table` only (issue Option
  3).** Surfaces drift but does not stop it. Chosen as a supplementary tool
  rather than the whole solution.
- **Delete the project memory file entirely and rely on agent descriptions
  alone.** Loses project-local code-area signals, which are genuinely project-
  specific and have no other home.

## Open Questions

- Should the audit skill run automatically at the end of `/onboard` and
  `/add-specialist`? Current design: no, but the skills can print a one-line
  hint ("Run `/audit-routing-table` to verify routing health.") on exit.
- Should `## Registered Specialists` support a per-entry disabled flag for
  temporarily suppressing a specialist without removing it? Deferred; can be
  added without breaking the format.
- Should the Tech Lead cache agent description reads within a single Phase 1
  invocation? Likely yes; files are read once at the start of routing. Not a
  design-level constraint, though.
