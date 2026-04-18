# Change Proposal: Unify Specialist Routing Around Agent Descriptions

## Summary

Eliminate the duplication between the Tech Lead's Specialist Routing Table and
specialist agent descriptions by making the agent descriptions the single source
of truth for trigger phrases and jurisdiction. Replace the current routing table
with a thin per-project artifact that stores only two kinds of information:
which specialist agents are registered for this project, and project-specific
code-area overrides (file globs and local keywords) that are not derivable from
an agent's description. Adopt Option 2 from issue #6 as the primary mechanism,
augmented with a narrow code-area overrides block so project-local signals are
not lost.

## Motivation

The Tech Lead's project memory currently encodes a `## Specialist Routing Table`
whose rows map signals (code areas, trigger keywords) to specialist agents. The
same specialists also expose trigger phrases in the `description` field of their
agent markdown frontmatter, which Claude Code surfaces to the main loop through
the Agent tool. Contributors hand-maintain both sources.

On a project of any non-trivial size this creates three concrete problems:

1. **Drift.** Trigger phrases added to the agent description do not propagate to
   the routing table, and vice versa. The Tech Lead routes from the table; the
   main loop routes from the description; the two disagree silently.
2. **Invisibility of new specialists.** Contributors who add a specialist agent
   routinely forget the parallel hand-edit of the routing table. The Tech Lead
   never sees the new specialist until someone notices and patches the table.
3. **Unbounded table growth.** As specialists accumulate, the table grows past
   500 lines, encodes detail inconsistent with agent descriptions, and becomes
   untrustworthy as a routing source.

The current duplication exists mostly because the table predates the convention
that agent descriptions encode trigger vocabulary. Keeping both sources of truth
is a maintenance tax that delivers no additional correctness.

## Goals

- Establish a single source of truth for specialist trigger vocabulary: the
  agent `description` field
- Preserve the ability to express project-specific code-area signals (for
  example, `src/payments/**` in this project routes to `payments-specialist`)
  because that information is genuinely project-local and cannot be derived from
  an agent description
- Eliminate the "add a specialist, forget to update the table" failure mode
- Keep the Tech Lead's Phase 1 routing output format unchanged so the
  `/plan-implementation` skill parses the same contract
- Provide an audit mechanism that detects project-local signals referencing
  agents that are no longer registered (drift in the thin remaining artifact)

## Non-Goals

- Changing the schema of agent description frontmatter (issue #6 explicitly
  places this out of scope)
- Building automatic discovery of specialist agents from arbitrary file system
  locations — the `/onboard` specialist-discovery flow remains the registration
  mechanism
- Cross-project routing federation
- Removing the concept of a routing model entirely; the Tech Lead still needs
  something to match against, the question is only where that something lives

## Proposed Change

### 1. Replace the routing table with two narrower artifacts

The current `## Specialist Routing Table` section in
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md` is replaced by
two sections:

**`## Registered Specialists`** — a flat list of agent names the Tech Lead
should consider during routing, with optional pointers to each agent's
description file:

```markdown
## Registered Specialists

- `qa-lead` — `agents/qa-lead.md`
- `devops-lead` — `agents/devops-lead.md`
- `payments-specialist` — `plugins/payments/agents/payments-specialist.md`
```

**`## Project Code Area Overrides`** — a narrow table for project-local signals
that are not derivable from any agent description (file globs, project-specific
keywords):

```markdown
## Project Code Area Overrides

| Code Area / Signal | Specialist Agent |
|--------------------|-----------------|
| `src/payments/**`  | payments-specialist |
| `src/auth/**`      | auth-specialist |
```

Rows in the overrides table are **only** for signals that do not already appear
in the matched agent's description. Duplicating an agent's trigger vocabulary
into this table is explicitly discouraged; the audit skill flags such rows.

### 2. Update the Tech Lead's Phase 1 routing procedure

The Tech Lead's Implementation Planning, Incident Analysis, and Retrospective
Consultation response modes all read the routing model the same way. The new
procedure:

1. Read the `## Registered Specialists` list
2. For each registered specialist, read the agent file referenced by the list
   entry (or `agents/<name>.md` by default)
3. Match the issue's text against each agent's `description` body (trigger
   phrases, example contexts, jurisdiction paragraph)
4. Additionally, match the issue's explicit code-area references against the
   `## Project Code Area Overrides` table; any override match adds the
   specialist to the consultation list even if the description match missed
5. Emit consultation requests in the existing Phase 1 output format

The Phase 1 output contract documented in `agents/tech-lead.md:156-168` is not
changed. The `/plan-implementation` skill's parser continues to work.

### 3. Update `/add-specialist` to register without duplicating triggers

The skill stops asking for trigger phrases. It accepts an agent name and
optional project-local code-area signals. If code-area signals are provided, it
appends rows to `## Project Code Area Overrides`; otherwise it only registers
the agent under `## Registered Specialists`. The command becomes:

```text
/add-specialist <agent-name> [code-area-override ...]
```

Existing invocations that pass trigger keywords (e.g. `authentication`) still
work but emit a warning: "Trigger keywords like `authentication` should live in
the agent's description. Adding as a code-area override; consider whether this
belongs in the agent file instead."

### 4. Update `/onboard` specialist discovery

Step 4 (Specialist Discovery) stops asking for signals per specialist. It asks
only for the specialist agent names, confirms each agent file exists, and calls
`/add-specialist <name>` without signals. Users who want code-area overrides
add them explicitly with a follow-up `/add-specialist <name> <override>` call.

### 5. Add `/audit-routing-table` for hygiene

A new skill that:

- Flags `## Project Code Area Overrides` rows pointing at agents not in
  `## Registered Specialists` (orphan rows)
- Flags override rows whose signal already appears as a trigger in the target
  agent's description (redundant rows)
- Flags registered specialists whose agent file cannot be read (broken pointers)
- Reports but does not auto-correct; outputs a checklist for human review

## Success Metrics

- Adding a new specialist requires one action (register the agent) and zero
  trigger-phrase copying
- The routing table file stays within a small bound (number of registered
  specialists plus a short list of project-local code-area rows) regardless of
  specialist count
- No silent disagreement between the Tech Lead's routing and the main loop's
  description-matching — both read the same trigger vocabulary
- `/audit-routing-table` reports zero orphan rows and zero redundant rows on a
  healthy project

## Impact

- **Users:** One-step specialist registration. No parallel hand-edits.
- **Tech Lead:** Reads two narrower sections instead of one long table. Uses
  agent description content for trigger matching.
- **`/onboard`:** Simpler Q8 flow; no signal-per-agent follow-up unless the user
  explicitly wants code-area overrides.
- **`/add-specialist`:** Shorter argument list; warns on trigger-keyword inputs.
- **`/plan-implementation`:** No change; Phase 1 output contract is unchanged.
- **Specialist agents:** No schema changes to descriptions. Authors are
  encouraged to keep trigger phrases in the description body where they already
  live.
- **Existing projects:** A migration is required. The audit skill doubles as a
  migration helper by flagging every table row that is redundant with an agent
  description and should be removed.

## Risks

- **Description-matching quality.** Matching against natural-language
  descriptions is fuzzier than matching against explicit keyword lists. If an
  agent description is sparse, the Tech Lead may miss a match that the old
  table would have caught. Mitigation: document the guidance that specialist
  descriptions should include the key trigger phrases, code-area references,
  and jurisdiction keywords that make routing reliable. The audit skill can
  also surface agents with unusually short descriptions.
- **Migration burden on existing projects.** Projects with populated routing
  tables need to walk through each row, decide whether it belongs in an agent
  description (which is out of scope to edit for upstream agents) or in the
  overrides table. Mitigation: `/audit-routing-table` flags candidates for
  deletion, and the migration is one-time.
- **External-plugin specialists.** Agent files for specialists registered from
  other plugins may not live in the current repo. The `## Registered
  Specialists` pointer format handles this, but the Tech Lead must fail loudly
  (not silently) when it cannot read a referenced file.

## Dependencies

- Depends on the existing `/onboard` specialist discovery flow
- Related to issue #3 (the Tech Lead's two-phase consultation protocol) because
  Phase 1 output structure is unchanged
- Related to the `/plan-implementation` skill because the Phase 1 parsing
  contract is not changed

## Alternatives Considered

- **Option 1 from the issue (generate the routing table from agent
  descriptions).** Rejected as primary: generating a large derived file keeps
  the appearance of two artifacts and invites hand-edits that silently diverge
  from the generator input. The proposed design removes the derived file
  entirely and lets the Tech Lead read the source directly.
- **Option 3 from the issue (audit-only).** Rejected as primary: audit surfaces
  drift but does not eliminate the duplication. We keep the audit skill as a
  hygiene tool on the narrower remaining surface, but the core change is to
  remove the duplicated content.
- **Add structured routing metadata to agent frontmatter.** Explicitly out of
  scope per issue #6; the agent description schema stays as-is.
- **Full elimination of the project memory routing file.** Rejected: project-
  local code-area signals (like `src/payments/**`) are genuinely project-
  specific and have nowhere else to live. Keeping a thin overrides table
  preserves that capability without reintroducing trigger-phrase duplication.
