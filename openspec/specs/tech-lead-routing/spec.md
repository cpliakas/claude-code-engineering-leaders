# Spec: Tech Lead Specialist Routing

## Identity

- **Owner agent:** `tech-lead`
- **Consumers:** `/plan-implementation`, `/conduct-postmortem`,
  `/facilitate-retrospective`, any caller that invokes the Tech Lead for
  routing
- **Memory file:** `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`

## Purpose

Define how the Tech Lead selects specialist agents to consult during Phase 1
of the two-phase consultation protocol. The routing model uses agent
descriptions as the source of truth for trigger vocabulary and a thin
project-local overrides table for code-area and project-specific signals.

## Memory File Sections

### `## Registered Specialists`

A markdown list. Every registered specialist is a candidate for routing. The
list contains no trigger metadata.

Entry format:

```markdown
- `<agent-name>` — `<path-to-agent-file>`
```

- `<agent-name>` is the kebab-case name that matches the agent's `name`
  frontmatter field.
- `<path-to-agent-file>` is optional. When omitted, the Tech Lead uses
  `agents/<agent-name>.md`.

Invariants:

- Every specialist referenced in `## Project Code Area Overrides` must appear
  in this list.
- The Tech Lead does not invent routing for agents not in this list. Missing
  domain coverage is surfaced as a gap, not an invented consultation request.

### `## Project Code Area Overrides`

A two-column markdown table. Each row identifies a project-local signal that
should route to a registered specialist regardless of description match.

Row format:

```markdown
| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
| `<signal>`         | <agent-name>    |
```

- Signals that look like file paths or globs are backtick-delimited; plain
  keywords are not.
- Signals should be project-local — file globs, repo-specific module names,
  internal terminology not found in any agent description.
- Duplicating trigger vocabulary from an agent description into this table is
  discouraged; the audit skill flags redundant rows.

## Routing Procedure

### Step 1 — Load Registered Specialists

Read `## Registered Specialists`. If the section is missing or empty, emit the
no-specialists notice already documented at `agents/tech-lead.md:71-76` and
produce Phase 1 output with zero consultation requests.

### Step 2 — Load Agent Descriptions

For each entry in `## Registered Specialists`, read the referenced agent file:

- If the file is readable, extract the `description` field from the
  frontmatter block. Concatenate any multi-line description (the plugin's
  convention uses pipe-quoted YAML scalars for long descriptions, which
  preserves newlines).
- If the file is not readable (missing, unreadable, or malformed frontmatter),
  skip the specialist and record a routing warning. The warning is surfaced in
  the Phase 1 output under the `## Preliminary Constraints` section as a line:
  `Routing warning: could not read agent file for \`<agent-name>\` at
  \`<path>\`.`

### Step 3 — Build Match Candidate Set

A specialist is a match candidate if either condition holds:

- **Description match.** A case-insensitive substring of any trigger phrase,
  example-context phrase, or jurisdiction keyword extracted from the agent's
  `description` appears in the issue text.
- **Override match.** The issue text, any file paths the issue mentions, or
  any file the issue scope would edit matches a row in `## Project Code Area
  Overrides` whose target is this specialist. Glob matching uses standard
  shell glob semantics; plain-keyword overrides use case-insensitive
  substring match.

A specialist matched by both mechanisms appears once in the match candidate
set.

### Step 4 — Emit Phase 1 Output

Produce Phase 1 output in the exact format documented at
`agents/tech-lead.md:114-149`. The output is unchanged by this spec:

- `## Engagement Depth`
- `## Consultation Requests` with one `### <Specialist Name>` subsection per
  match candidate, each containing `**Agent:**` and `**Prompt:**` anchors
- `## Preliminary Constraints` — includes any routing warnings from Step 2
- `## Next Step`

### Step 5 — Gap Handling

If the Tech Lead's own assessment of the issue identifies a relevant domain
that no registered specialist covers, the gap is surfaced as follows:

- During Phase 1: as a bullet in `## Preliminary Constraints` noting the gap
  and recommending that the user register a specialist.
- During Phase 2: as a bullet in `## Escalation Flags` when the gap is
  load-bearing for the plan.

The Tech Lead never invents a consultation request for an unregistered agent.

## Invariants

- Trigger vocabulary lives in agent descriptions. The routing memory file
  does not contain trigger vocabulary.
- Every override row targets a registered specialist. Orphan rows are audit
  findings, not routing inputs; the Tech Lead skips them at runtime.
- The Phase 1 output format is unchanged by this spec. Existing parsers
  (notably `/plan-implementation`) continue to work.
- Specialist descriptions are read at routing time, not cached across
  invocations. The Tech Lead always sees the current description content.
- Specialists with unreadable agent files produce a visible warning in Phase 1
  output; they are never silently dropped.

## Non-Requirements

- Keyword extraction from descriptions does not need to be semantic or
  NLP-based. Case-insensitive substring matching against the raw description
  body is sufficient.
- The routing memory file does not need a version field. Migration from the
  previous format is human-driven via `/audit-routing-table`.
- The Tech Lead does not need to deduplicate across description and override
  matches beyond producing a single consultation request per specialist.

## Acceptance Criteria

- [ ] Registering a new specialist with `/add-specialist <name>` makes the
      Tech Lead consult that specialist on an issue whose text matches the
      specialist's description, without any additional table edits.
- [ ] Adding a project-local override with `/add-specialist <name>
      "<override>"` causes the Tech Lead to consult the specialist on an
      issue that references the override signal even when the issue text
      does not match the agent description.
- [ ] An override row pointing at an unregistered specialist does not
      produce a consultation request at runtime. `/audit-routing-table`
      flags the row as orphan.
- [ ] A registered specialist whose agent file cannot be read is skipped at
      routing time with a warning in `## Preliminary Constraints`, and the
      remaining specialists still route correctly.
- [ ] Running `/plan-implementation` on the same issue before and after the
      migration produces Phase 1 output in the same format (same anchors,
      same consultation-request shape), so the skill's parser continues to
      work.
- [ ] `/audit-routing-table` reports orphan overrides, broken pointers,
      redundant overrides, and thin descriptions with recommended actions
      for each finding.
