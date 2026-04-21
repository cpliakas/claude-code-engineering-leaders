# Design: Audit Agent Memory Skill

## Context

Every agent in this plugin declares `memory: project` in its frontmatter.
At invocation time Claude Code reads the agent's project memory
directory (`.claude/agent-memory/engineering-leaders-<agent>/`) and
loads `MEMORY.md` plus any files referenced by it. Over time these
directories grow. Because each invocation pays the token cost of the
entire loaded set, memory that is cheap to write can become expensive
to carry.

Two patterns recur in deployments:

1. **Operational state migrates into memory that should hold strategy.**
   A QA Lead accumulates coverage-gap files with specific module names
   and line counts. A Product Owner records a phase tracker with dated
   milestones. A DevOps Lead lists specific incidents with post-dated
   follow-ups. The content was useful when written; months later it is
   stale, duplicates tracker content, and still loads every turn.
2. **Dead links accumulate.** A memory file is written, referenced from
   `MEMORY.md`, then the index line is removed during a later edit.
   The file stays in the directory and Claude Code may or may not load
   it depending on path rules, but either way the user has no signal
   that it is orphaned.

There is no audit command. Users have `/audit-routing-table` for the
Tech Lead's specialist routing model, but no equivalent for the rest
of the memory surface. The gap is a read-only advisory skill that
looks at a single agent's memory directory and reports hygiene issues.

The existing `audit-routing-table` skill sets the precedent: read
memory files, run a small set of named checks, print a report with
recommended actions, do not modify anything. The new skill follows the
same shape and allowed-tools (`Read`, `Glob`, `Grep`).

## Goals / Non-Goals

**Goals:**

- Provide a single command that audits one agent's project memory
  directory and prints a structured report.
- Surface three hygiene categories: content that looks like state
  rather than strategy, files not referenced from `MEMORY.md`
  (dead links), and directories whose cumulative size crosses a
  documented threshold.
- Use heuristics the user can read in the skill body. The thresholds
  and vocabulary lists are inline in `SKILL.md` so a user who disputes
  a finding can inspect the rule.
- Stay advisory. The skill recommends actions; it never deletes,
  moves, or rewrites content.
- Integrate with existing conventions: allowed-tools limited to read
  and search, `user-invokable: true`, argument hint names the agent
  parameter, and documentation entry in the top-level `README.md`.

**Non-Goals:**

- Automatic remediation. The user confirms and acts; the skill never
  edits.
- Cross-project memory analysis. One agent, one project, one run.
- Issue-tracker integration. The skill does not call the tracker API
  to check for duplicates. It applies textual heuristics only.
- Enforcement of a memory schema. Memory content remains free-form.
  The audit flags, it does not reject.
- Agent-side automation. No agent's definition gains audit behavior.
  Users invoke the skill deliberately.
- Recommending specific tracker targets. The skill says "looks like
  state" and suggests the user consider a tracker; it does not
  generate a ticket or name a destination.

## Decisions

### D1. One skill, one agent argument, one report per run

The skill accepts exactly one argument: the agent name (for example,
`qa-lead`). On invocation it derives the memory directory path as
`.claude/agent-memory/engineering-leaders-<agent>/` and audits only
that directory. A single run produces a single report.

**Rationale:** Scoping to one agent keeps the output scannable and the
mental model clear. Bulk audits across all agents would produce noise
that users ignore. Running the command per agent preserves the pattern
of `/audit-routing-table` and lets users focus on one agent's memory
at a time.

**Alternatives considered:** A zero-argument "audit every agent" form.
Rejected: the output grows linearly with the number of agents, and
users are more likely to skim or ignore it. The per-agent form is
also composable: a user can script `for agent in ...; do
/audit-agent-memory $agent; done` if they want bulk behavior.

### D2. Four named checks with explicit heuristics

The skill runs four checks, each with a documented heuristic:

1. **State-like content.** Scan each memory file for any of: dated
   phrases (for example, "as of Q3", "as of 2026", "last month",
   "this sprint"), enumerated file paths (three or more paths in a
   row formatted as `path/to/file`), enumerated issue IDs (three or
   more IDs matching a project's tracker pattern), or tables whose
   rows look like work items (columns named "owner", "due", "status").
2. **Strategy-like content (negative check).** Files that contain at
   least one of: a "Why" rationale paragraph, a named invariant or
   principle, a routing rule, a named policy, or a definition. Files
   that trip check 1 but also satisfy this check are downgraded from
   "state" to "mixed" severity.
3. **Dead links.** Read `MEMORY.md` and collect every relative file
   reference it contains. Glob the directory for `*.md` files and
   flag any file not referenced from the index.
4. **Size.** Compute a byte-count and a rough token estimate (bytes
   divided by four) for each file and for the directory. Flag the
   directory if the total crosses a documented threshold (initial
   threshold: roughly ten thousand tokens). Flag any individual file
   whose size alone exceeds roughly four thousand tokens.

Each finding prints:

- The file path (or directory).
- The check that triggered.
- A one-line rationale that quotes the triggering phrase or count.
- A recommended action phrased as a suggestion, not a directive.

**Rationale:** Four named checks keep the report structured. Inline
heuristics let the user see why a file was flagged and override the
call if the heuristic is wrong. A negative "strategy-like" check
reduces false positives on files that mix policy with a few dated
references.

**Alternatives considered:** A single fuzzy classifier that scores
files continuously. Rejected: opaque to users and hard to tune. Named
checks with visible thresholds are preferable for a recommend-only
skill. Also considered: include an "AI judgment" step that reads each
file and classifies it. Rejected as over-engineered for v1; the
textual heuristics are cheap, inspectable, and good enough for the
hygiene signals the skill is meant to surface.

### D3. Report format is a fixed markdown structure

The report emits four sections in a fixed order:

1. `## Summary` with a one-line size summary and a finding count per
   check.
2. `## Findings` grouped by check, each finding rendered as a bulleted
   item with file path, rationale, and recommended action.
3. `## Recommendations` summarizing suggested next steps across the
   findings, phrased as options.
4. `## Next Step` with a single-sentence call to action pointing the
   user at the highest-priority recommendation.

**Rationale:** A fixed structure is machine-parseable for future
automation and predictable for human readers. Mirrors the structure
used by `/audit-routing-table` for consistency across audit skills.

**Alternatives considered:** Free-form narrative report. Rejected:
harder to skim and inconsistent with the existing audit skill's
style. Also considered: table-only output. Rejected: tables are hard
to read when rationale strings vary in length.

### D4. Heuristics are documented thresholds, not rigid gates

All numeric thresholds (ten thousand tokens for the directory, four
thousand for a single file, three or more paths to count as
"enumerated", and so on) live inline in the skill body with their
numeric values visible. A user who disputes a threshold can propose
a change to the skill body. The skill does not read thresholds from
a config file in v1.

**Rationale:** Inline thresholds keep the skill self-contained and
legible. A config file would invite per-project drift without
evidence that the thresholds need tuning. Revisit if two or more
projects report systematically mistuned defaults.

**Alternatives considered:** Per-project threshold overrides in
onboarding memory. Rejected as premature. The plugin-level defaults
are the right first draft.

### D5. Allowed-tools limited to Read, Glob, and Grep

Matches the `audit-routing-table` skill. The audit reads files,
globs the directory for orphan detection, and greps for vocabulary
matches. No `Bash`, `Write`, or `Edit`.

**Rationale:** The skill is read-only by design. Constraining
allowed-tools enforces that at the harness level and makes the
capability visible in the frontmatter.

**Alternatives considered:** Allow `Bash` so the skill can shell out
to `wc -c` or similar. Rejected: not needed, and broadens the
skill's blast radius unnecessarily.

### D6. Skill lives alongside existing audit skills; no agent-definition edits

The skill is added at `skills/audit-agent-memory/SKILL.md`. No agent
definition is modified. The README gains a one-paragraph entry under
the existing audit skills section that explains when to run it
(periodic hygiene, before re-onboarding, when an agent feels
bloated).

**Rationale:** The skill is user-invoked. No agent needs to know
about it. Keeping the change out of agent definitions keeps the
agent surface stable and the change reviewable.

**Alternatives considered:** Have one or more agents proactively
suggest running the audit (for example, the Engineering Manager
during SDLC health reports). Deferred: worth considering once the
skill has observed usage, but premature here.

### D7. Tracker-overlap detection is textual only in v1

The skill's "issue-tracker overlap" signal looks for enumerated issue
IDs matching common patterns (for example, uppercase prefix plus
hyphen plus digits, matching `bd-1234`, `INGEST-42`, `PROJ-7`). It
reports "looks like tracker content" when a file contains three or
more such IDs. It does not call any tracker API to verify that the
IDs exist.

**Rationale:** Tracker APIs are per-project, require credentials, and
drag the skill toward network dependencies it otherwise does not
need. A textual heuristic is cheap and sufficient to flag suspicious
content for human review. The user is the final judge.

**Alternatives considered:** Integrate with Beads, GitHub Issues,
Linear, and Jira. Rejected for v1. Revisit once the skill has proven
useful and user demand for tracker verification is demonstrated.

## Risks / Trade-offs

- **False positives on legitimate strategy files that happen to
  enumerate things.** A routing table with specialist names in a list,
  or an invariants doc that references file paths, may trip the
  "enumerated paths" heuristic. **Mitigation:** the strategy-like
  negative check downgrades mixed content from "state" to "mixed"
  severity. Users can dismiss findings they disagree with; the skill
  does not modify anything.
- **False negatives on truly stale content that uses abstract
  language.** A phase-tracker file written in prose ("we are in the
  discovery phase") may not match any dated-phrase pattern.
  **Mitigation:** size and dead-link checks still apply; the skill is
  one signal source, not the only one. Users running the audit as a
  conversation starter catch what the heuristics miss.
- **Threshold misfires across projects.** Ten thousand tokens for a
  directory may be too loose or too tight depending on project
  maturity. **Mitigation:** thresholds are visible in the skill body;
  projects with strong opinions can propose tuning. The audit is
  advisory, so a noisy threshold produces an ignorable warning, not a
  blocked workflow.
- **Users treat the audit output as instructions and prune too
  aggressively.** If the "Recommendations" section reads as
  prescriptive, users may remove content the heuristic flagged as
  state that is actually valuable. **Mitigation:** the report's
  `Recommendations` section is phrased as options with the words
  "consider" and "if", and the `Next Step` points to the single
  highest-priority item rather than a batch action.
- **Growth of the audit surface over time.** Future checks (for
  example, stale link detection against the filesystem, duplicate
  content across files) could balloon the skill. **Mitigation:** v1
  ships four named checks; additional checks require a separate
  change with rationale. Resist adding heuristics without evidence
  they are load-bearing.

## Migration Plan

No migration required. The change is additive.

- No existing skill or agent is modified.
- No existing memory file is touched.
- Rollback is removal of `skills/audit-agent-memory/` and reversion
  of the README entry.

## Open Questions

- Should the skill eventually accept a `--format=json` option so
  automation can consume the report? Deferred: the markdown report is
  sufficient for human hygiene runs. Revisit if a downstream skill or
  hook wants to act on audit output programmatically.
- Should the Engineering Manager's SDLC health report call this skill
  per agent and aggregate results? Deferred to a follow-up once the
  skill has observed usage. Integrating prematurely risks coupling the
  two surfaces before the audit's heuristics settle.
- Should the skill propose a specific destination for state-like
  content (for example, "move to beads as a `bd remember` entry" or
  "file as a ticket")? Deferred: projects use different trackers, and
  a single recommendation would misfire. V1 suggests "consider moving
  to the project's tracker" and leaves the destination to the user.
- Should dead-link detection distinguish between files Claude Code
  actually loads (indexed from `MEMORY.md`) and files that exist but
  are unreferenced? V1 treats unreferenced as the definition of dead
  link. Revisit if Claude Code's memory-loading rules change.
