---
name: write-adr
description: >
  Produce a complete ADR (Architecture Decision Record) document in MADR format.
  Use when the user invokes /write-adr, the Chief Architect recommends recording
  a decision, or an architectural review surfaces decisions to document.
user-invokable: true
allowed-tools: Read, Grep, Glob
argument-hint: "<decision description>"
context: fork
---

# Write ADR

Produce a complete ADR document in MADR format for the decision described in
`$ARGUMENTS`.

## Step 1 — Check for Decision Description

If `$ARGUMENTS` is empty, ask the user to describe the decision before
proceeding. Do not continue until a decision description is provided.

## Step 2 — Determine Next ADR Number

Check the Chief Architect's project memory
(`.claude/agent-memory/engineering-leaders-chief-architect/MEMORY.md`) for a
configured ADR directory path.

If a directory is configured:

1. Read the index file (typically `README.md`) in that directory
2. Scan the ADR Index table for the highest existing number (e.g., `0011`)
3. Set `NEXT` to that number plus one, zero-padded to 4 digits (e.g., `0012`)

If no directory is configured:

1. Generate the ADR document as output only (do not write to disk)
2. Use `0001` as the ADR number
3. Note in the output that the Chief Architect's memory can be configured with
   an `adr_directory` path to enable automatic filing and sequential numbering

## Step 3 — Gather Context

Before filling in the template, read relevant project context:

- CLAUDE.md for architecture conventions and domain language
- Existing ADRs in the configured directory (if available) for precedent and
  consistency
- Chief Architect's project memory for related decisions and architectural
  trajectory
- Any files, schemas, or code referenced in the decision description

## Step 4 — Produce the ADR

Use this MADR template:

```markdown
---
status: proposed
date: YYYY-MM-DD
deciders: [who was involved in this decision]
---

# ADR-NNNN: [Short title of solved problem and solution]

## Context and Problem Statement

[What situation or problem forced this decision? What constraints, requirements,
or competing concerns existed? Keep to 2-4 sentences. May be phrased as a
question.]

## Decision Drivers

- [Driver 1 — e.g., cost constraint, latency requirement, team expertise]
- [Driver 2]

## Considered Options

- [Option 1]
- [Option 2]
- [Option 3]

## Decision Outcome

Chosen option: "[Option N]", because [justification — reference decision drivers].

### Consequences

- Good, because [positive consequence]
- Good, because [positive consequence]
- Bad, because [negative consequence or trade-off]
- Bad, because [negative consequence or trade-off]

## Pros and Cons of the Options

### [Option 1]

- Good, because [argument]
- Neutral, because [argument]
- Bad, because [argument]

### [Option 2]

- Good, because [argument]
- Bad, because [argument]

### [Option 3]

- Good, because [argument]
- Bad, because [argument]

## More Information

[Additional context, links to related ADRs, evidence gathered during
evaluation, or notes on when this decision should be revisited. Omit this
section if genuinely not applicable.]
```

Fill in the template using:

- The decision description from `$ARGUMENTS` as the primary input
- Relevant project context gathered in Step 3
- **status:** `proposed`
- **date:** today's date (ISO 8601: YYYY-MM-DD)
- **deciders:** the relevant team members or agents for this decision
  (e.g., "Chief Architect, Product Owner" for cross-cutting decisions)

Write the ADR document in full — all sections completed, no placeholder text
left unfilled. Optional sections (`Decision Drivers`, `Pros and Cons of the
Options`, `More Information`) may be omitted if genuinely not applicable, but
prefer including them — they add decision context that ages well.

## Step 5 — Output

If an ADR directory is configured, write the file and update the index:

1. Write to `<directory>/NNNN-short-title.md`
   (derive a short-title from the decision: lowercase, hyphen-separated,
   3-5 words; e.g., `0012-event-search-index-strategy`)
2. Add a row to the ADR Index in `<directory>/README.md`

If no directory is configured, display the following in order:

1. **Suggested filename:** `NNNN-short-title.md`

2. **Full ADR document body** ready to copy or write to the file.

3. **One-line reminder:**

   > To enable automatic filing, add an `adr_directory` entry to the Chief
   > Architect's project memory
   > (`.claude/agent-memory/engineering-leaders-chief-architect/MEMORY.md`) with
   > the path where ADR documents should be stored.
