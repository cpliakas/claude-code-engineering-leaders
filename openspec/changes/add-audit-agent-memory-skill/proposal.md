# Change Proposal: Audit Agent Memory Skill

## Why

Every agent in the plugin uses `memory: project`. Each invocation pays a
per-turn token cost for whatever has accumulated in that agent's memory
directory, and there is no tool that helps a user audit what has
accumulated or why.

Two failure modes are visible in practice. First, memory drifts from
strategic context (policy, routing, philosophy) toward operational state
(dated phase trackers, enumerated coverage-gap lists, lists of file
paths) that belongs in an issue tracker or a dated artifact rather than
in an every-turn prompt. A real observation: one deployment's QA Lead
memory grew to twelve coverage-gap files that duplicated tracker
content. Another deployment's Product Owner memory held a phase-status
file that went stale within weeks. Second, orphaned files accumulate
when `MEMORY.md` stops referencing a file but the file still sits in
the directory and still loads on invocation.

Users have no audit command. There is no report that flags suspicious
content, surfaces files nobody indexes anymore, or measures the
cumulative size of a given agent's memory. The existing
`/audit-routing-table` skill audits the Tech Lead's routing model but
does not look at the rest of the memory surface. The gap is a
per-agent memory audit with the same recommend-not-prescribe posture.

## What Changes

- Introduce a new user-invokable skill: `skills/audit-agent-memory/`.
  The skill accepts an agent name as its single argument (for example,
  `/audit-agent-memory qa-lead`) and inspects that agent's project
  memory directory.
- Produce a structured report with four finding categories: state-like
  content, issue-tracker overlap, dead-link files, and oversized memory
  directories. Each finding carries a severity marker and a recommended
  action the user can confirm or dismiss.
- The skill does not delete, move, or rewrite any file. All actions are
  advisory. The skill prints the report and exits.
- Document detection heuristics inline in the skill so the thresholds
  are inspectable and tunable. Initial heuristics cover dated-phrase
  patterns, enumerated-path patterns, dead-link detection by scanning
  `MEMORY.md` for references, and a size-based trigger for whole
  directories.
- Document the skill in the top-level `README.md` alongside the other
  audit skills. Include guidance on when to run it (periodic hygiene,
  before re-onboarding, when an agent feels bloated).

## Capabilities

### New Capabilities

- `audit-agent-memory-skill`: a user-invokable skill that inspects one
  agent's project memory directory and produces an advisory report
  covering state-vs-strategy classification, issue-tracker overlap,
  dead-link files, and size signals. Does not modify any file.

### Modified Capabilities

<!-- No existing capability is modified. The skill is additive and
reads only. -->

## Impact

- **Users:** A single command surfaces memory hygiene issues per agent.
  The audit does not change any file; the user decides what to act on.
  Over time, repeated audits are expected to drive agent memory toward
  smaller, strategy-focused content and push operational state into the
  appropriate tracker.
- **Agents:** No agent definition change. Every agent that uses
  `memory: project` becomes auditable. The reference implementation
  targets the set of agents shipped by this plugin, but the skill
  accepts any agent name so external agents using the same memory
  layout are also auditable.
- **`/onboard` and `/onboard-<agent>` skills:** No behavior change. The
  audit is complementary: onboarding refreshes content, the audit
  classifies what should stay.
- **`/audit-routing-table` skill:** No behavior change. The two audits
  are complementary and can be run independently. The new skill does
  not duplicate routing-table checks; it focuses on the rest of the
  memory surface (strategy vs state, dead links, size).
- **Token cost:** Running the audit has a one-time cost per invocation.
  The payoff is a reduction in per-invocation cost for the audited
  agent once the user acts on the recommendations. The audit itself
  does not add to any agent's memory.
- **Existing projects:** No migration required. The skill is additive
  and read-only. Projects that have not yet run an audit are unaffected
  until the user chooses to run it.
- **Non-goals:** Automatic pruning, automatic migration of memory to a
  tracker, cross-project memory analysis, per-tracker integration, or
  enforced memory size limits. These remain out of scope.
