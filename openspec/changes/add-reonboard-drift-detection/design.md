# Design: Re-Onboarding Drift Detection Skill

## Context

The plugin's onboarding model has two layers. Layer 1 is
`/onboard`, which collects project-wide context and writes it to
`.claude/agent-memory/engineering-leaders/PROJECT.md`. Layer 2 is
per-agent: `/onboard-product-owner`, `/onboard-tech-lead`, and the
companions each gather agent-specific context on top of the shared
layer and write to
`.claude/agent-memory/engineering-leaders-<agent>/MEMORY.md`.

Both layers ask the user to answer questions once. The answers
become prompt fuel every time the relevant agent is invoked.
Projects evolve after onboarding: a team switches issue trackers, an
ADR directory is renamed, a specialist file moves, CI migrates from
one provider to another, a convention file is reorganized. The
memory does not self-update. Users have no way to see what has
drifted without re-running the full onboarding, which is expensive
enough that users put it off and tolerate the drift.

Two precedents exist for read-only audit skills in this plugin:

1. **`/audit-routing-table`** audits the Tech Lead's specialist
   routing model. It reads memory, runs named checks, prints a
   report, and does not modify anything.
2. **`/audit-agent-memory`** audits a single agent's memory
   directory for hygiene (state vs strategy, dead links, size). Same
   shape: read-only, report-only, user decides.

The new skill extends that pattern to onboarding content
specifically. The distinction from the existing audits:

- `audit-agent-memory` asks "what should stay?" (hygiene: is this
  content still the kind of thing memory should hold?).
- `audit-routing-table` asks "is the routing model internally
  consistent?" (routing-specific structural checks).
- The new `re-onboard` skill asks "is the content still accurate?"
  (does memory still match the project on disk?).

The three are complementary. The new skill focuses on accuracy
against derivable project signals and is the only one of the three
that, with user confirmation, writes updates back to memory.

## Goals / Non-Goals

**Goals:**

- Provide a single command that produces a diff-style report of
  onboarding drift per onboarded agent.
- Derive signals from cheap local sources only: filesystem presence
  and structure, git remote URL, presence of tracker-specific
  directories and files.
- Phrase every drift finding as a question the user confirms or
  dismisses. Never present a derived guess as fact.
- Write updates to memory only after an explicit per-item (or
  explicit batch) confirmation. The default is one confirmation per
  drifted item.
- Integrate with the Layer 1 shared context so drift in
  `PROJECT.md` surfaces for the shared layer and for every agent
  whose memory references the shared file.
- Keep the skill body heuristic-visible. Users who dispute a
  finding can open `SKILL.md` and see why the finding was raised.

**Non-Goals:**

- Continuous or background drift monitoring. The skill runs on
  demand; the user picks the cadence.
- Automatic drift fixes. The skill never writes memory without
  confirmation.
- Drift detection for content that is not derivable from local
  project signals. Team norms, persona definitions, philosophy, and
  stakeholder preferences are out of scope; the skill does not
  re-interrogate the user on those.
- Schema migration. If memory format itself changes between
  plugin versions, that is a different problem with a different
  skill.
- Replacing `/onboard` or the per-agent onboarding skills. Users
  who want a full refresh continue to re-run those. The new skill
  is a diff pass.
- Tracker API integration. Derivation stays local; the skill does
  not call Beads, GitHub, Linear, or Jira APIs.
- Cross-project analysis. One project per run.

## Decisions

### D1. One skill with an optional agent-name argument

The skill's primary form is zero-argument and audits every
onboarded agent in the project. An optional positional argument
narrows the audit to a single agent (for example,
`/re-onboard tech-lead`).

**Rationale:** The common case after a structural project change is
a full sweep, so the zero-argument form is the default. Per-agent
narrowing is useful when a user noticed one agent giving stale
advice and wants to confirm just that surface. Matching this shape
to `/audit-routing-table` (single-argument) and `/audit-agent-memory`
(single-argument) keeps the audit family predictable while still
allowing the bulk form where it helps.

**Alternatives considered:** Require an argument every time.
Rejected: forces users to loop manually for the common case. A
multi-agent flag (`--all`). Rejected: adds surface area without
clear benefit; the absence of an argument is a natural default.

### D2. Signal sources are filesystem, git remote, and tracker
probes

The skill derives signals from exactly four local sources:

1. **Filesystem paths claimed by memory.** Where memory claims a
   directory (for example, "ADRs live under `docs/adr/`"), the
   skill checks whether that path exists. If it does not, the skill
   globs for plausible alternatives (`docs/adrs/`, `docs/decisions/`,
   `architecture/`) and surfaces candidates.
2. **Specialist agent files in `agents/`.** Where the Tech Lead's
   routing table lists specialists, the skill compares that list
   against the files present under `agents/`. New files and missing
   files both surface as drift.
3. **Git remote URL.** Where memory claims a hosting platform (for
   example, "We use GitHub"), the skill runs `git remote get-url
   origin` and classifies the hostname. Mismatches surface.
4. **Tracker directory probes.** Where memory claims an issue
   tracker, the skill checks for the tracker's canonical footprint:
   `.beads/` for Beads, `.github/ISSUE_TEMPLATE/` as a hint for
   GitHub Issues, and so on. Absence of an expected footprint or
   presence of an unexpected one surfaces.

**Rationale:** These four sources cover the drift categories the
problem statement identifies (paths, specialists, hosting, tracker)
with cheap, local, inspectable checks. All four avoid network
dependencies and credentials.

**Alternatives considered:** Add ADR content scanning, CI provider
detection, or language/stack detection. Deferred: each of these is
a separate check that can be added later. Shipping four sources and
proving them out is preferable to eight half-tuned sources.

### D3. Every finding is a question, never a claim

The report never says "the ADR path is now `docs/adrs/`." It says
"memory says `docs/adr/` but `docs/adrs/` exists and `docs/adr/`
does not. Does this still look right?" Every drift item carries:

- What memory says.
- What the filesystem (or git remote, or tracker probe) suggests.
- A yes-or-no question the user answers to confirm or dismiss the
  update.

**Rationale:** Derived signals are heuristic by definition. A user
who reads the report as a set of facts will update memory
incorrectly when a heuristic misfires. Framing every item as a
question preserves the user's authority and makes heuristic
mistakes cheap to dismiss. This is the core posture of the
recommend-not-prescribe pattern the other audit skills already use.

**Alternatives considered:** Auto-apply high-confidence updates.
Rejected: "high confidence" is not measurable here without usage
data, and a silent write is the worst failure mode for a drift
skill. Revisit only after usage demonstrates which signal classes
are reliable enough to default-apply.

### D4. Per-item confirmation with an optional batch accept

The default write path is one confirmation per drift item. The user
answers yes or no for each. An explicit batch-accept option (for
example, a final "accept all remaining?" prompt after the user has
seen three or four items) is available for users who want to clear
a long list quickly.

**Rationale:** Per-item confirmation is the safe default. Batch
accept is a usability escape hatch for long reports, not the
default behavior.

**Alternatives considered:** One confirmation for all drift items
at once. Rejected: mixes high- and low-confidence items into a
single yes/no and encourages users to accept bad updates. Reject
all by default. Rejected: defeats the purpose of the skill; users
who run it want to update memory.

### D5. Shared-context drift propagates to dependent agents

If drift is detected in
`.claude/agent-memory/engineering-leaders/PROJECT.md`, the skill
reports the shared-context drift once, under a dedicated Shared
Context section of the report, and then lists which per-agent
memories reference the shared file (so the user sees the blast
radius in one view). The user confirms the shared-context update
once; the skill does not ask each dependent agent's memory to
confirm the same update again.

**Rationale:** The shared layer exists precisely so per-agent
memories do not each restate the same facts. Propagation of
confirmations matches that model. Asking per dependent memory would
turn one piece of drift into N repeated prompts.

**Alternatives considered:** Ignore the shared layer and only
audit per-agent memory. Rejected: misses the class of drift the
shared layer was introduced to absorb. Ask per dependent memory.
Rejected: noisy and rewards the user for having more agents.

### D6. Report format is a fixed markdown structure

The report emits sections in a fixed order:

1. `## Summary` with a count of drifted items per agent and a
   total.
2. `## Shared Context` with any drift detected in `PROJECT.md` and
   the list of dependent agent memories (empty subsection if
   nothing drifted).
3. `## Per-Agent Drift` grouped by agent name, each agent's
   section listing drifted, unchanged-notable, and new items.
4. `## Confirmation` listing each item as a numbered question for
   the user to answer.
5. `## Next Step` with a single-sentence call to action pointing
   the user at the highest-priority confirmation or suggesting
   they re-run the skill after applying updates.

**Rationale:** Mirrors the format used by `/audit-routing-table`
and `/audit-agent-memory`. Predictable structure is easier to skim
and easier to automate over later if a downstream skill wants to
consume the output.

**Alternatives considered:** Free-form narrative. Rejected:
inconsistent with the existing audit family. Table-only output.
Rejected: confirmations do not fit a table format well.

### D7. Allowed-tools: Read, Glob, Grep, Bash, Edit

The skill needs `Read` to load memory files, `Glob` to discover
candidate filesystem paths, `Grep` to match memory content against
signal patterns, `Bash` for the single `git remote get-url origin`
probe, and `Edit` to apply confirmed updates. `Write` is not
needed; all writes are in-place edits to existing memory files.

**Rationale:** This is the minimum tool surface that covers the
skill's documented behavior. The skill is the first in the audit
family that writes, so it necessarily takes `Edit`, but it does
not need broader surface than that.

**Alternatives considered:** Skip `Edit` and have the skill emit a
patch file the user applies manually. Rejected: breaks the
one-command experience and adds a step that users will forget.
Take `Write` as well for future-proofing. Rejected: `Write` is
broader than needed and the skill's scope is editing existing
files, not creating new ones.

### D8. Un-diffable content stays un-asked

Team size, persona preferences, review norms, philosophy, and
other onboarding content that has no local signal source are not
in the diff report at all. The skill does not re-ask those
questions. If a user wants to refresh those, they re-run the
relevant onboarding skill.

**Rationale:** The problem statement's risk section flags exactly
this case: if the skill re-interrogates everything, users abandon
it. Keeping the skill to diffable content keeps the cost of
running it low and the report scannable.

**Alternatives considered:** Emit a reminder at the end of the
report listing the un-diffable categories with a "you might want
to re-check these manually" note. Deferred: useful addition, but
the core behavior should stabilize first.

### D9. Skill lives alongside the audit family; no agent-definition
edits

The skill is added at `skills/re-onboard/SKILL.md`. No agent
definition changes. The README gains an entry under the onboarding
section that cross-references the audit skills.

**Rationale:** The skill is user-invoked. No agent needs to know
about it. Keeping the change out of agent definitions preserves
the stable agent surface and keeps the diff reviewable.

**Alternatives considered:** Have the Engineering Manager surface
a periodic drift reminder as part of SDLC health reports. Deferred:
worth considering once the skill has observed usage. Agent-driven
nudges tend to over-trigger before the heuristics settle.

## Risks / Trade-offs

- **False positives from signal heuristics.** A user restructures
  `docs/` intentionally, and the skill reports the new path as
  drift. **Mitigation:** every finding is a question the user
  dismisses with a single keystroke. The cost of a dismissed false
  positive is low. Users who want quiet runs can dismiss an entire
  category at once via the batch-accept flow inverted ("skip all
  remaining").
- **False negatives on content that looks stable but is wrong.**
  Memory claims the ADR path is `docs/adr/`, that path exists, but
  the team moved ADRs to a new directory and left the old
  directory in place. The skill sees the path and reports
  unchanged. **Mitigation:** the skill surfaces unchanged-notable
  items when the filesystem has plausible alternates that also
  exist; the user notices the discrepancy and confirms manually.
  This does not catch every case; the `/audit-agent-memory` and
  `/onboard` skills remain the backstops.
- **Over-reliance on the skill as a substitute for re-running
  `/onboard`.** A user treats the drift report as the full
  refresh and stops re-running the full onboarding even when the
  project has changed substantially. **Mitigation:** the report's
  `Next Step` periodically nudges users toward a full
  `/onboard-<agent>` run when more than half of a given agent's
  onboarding surface has drifted. The README explicitly frames
  `re-onboard` as a diff pass, not a replacement.
- **Write path introduces risk the read-only audits avoided.**
  The skill edits memory after confirmation, and a buggy edit
  could corrupt a memory file. **Mitigation:** confirmation is
  required per item (or explicit batch), the edit target is always
  a single existing file, and the skill does not create new memory
  files. A user can revert via git if they committed memory to
  version control.
- **Growth of the signal catalog.** Each new signal source (CI
  provider, language stack, container runtime, and so on) is a
  separate small check; the skill body could sprawl.
  **Mitigation:** v1 ships exactly four signal sources. Adding a
  fifth requires a separate change with rationale. Resist adding
  sources without evidence that they are load-bearing.
- **Batch-accept misuse.** Users accept a long batch without
  reading. **Mitigation:** the batch-accept option is introduced
  after the user has read and answered at least two items, not at
  the start of the report. This is a convention of the skill body,
  not an enforced gate.

## Migration Plan

No migration required. The change is additive.

- No existing skill or agent is modified.
- Existing onboarding memory files are the read inputs; the skill
  does not change their format.
- Rollback is removal of `skills/re-onboard/` and reversion of the
  README entry.

## Open Questions

- Should the skill eventually emit a machine-readable report
  alongside the markdown (for example, `--format=json`)? Deferred:
  markdown is sufficient for v1's interactive use case. Revisit if
  a hook or downstream skill wants to act on drift output
  programmatically.
- Should the skill prompt for a cadence on first run (for example,
  "run me every two weeks?") and store the cadence somewhere? No.
  That crosses into continuous monitoring, which is explicitly out
  of scope. Users can wire the skill into whatever scheduler they
  already use.
- Should the skill write a small "last audit" timestamp into
  memory on each run? Deferred. Useful for answering "when did we
  last check?" but not required for v1 behavior. If added, it
  lives in the shared context, not per-agent memory, to avoid
  multiplying the signal.
- Should the skill recommend specific file paths for confirmed
  updates, or let the user type the replacement? V1 proposes the
  derived value as a prefilled answer and accepts a one-keystroke
  confirmation. Free-text override is available for every item so
  the user can type a different value if the derived one is wrong.
- Should the Engineering Manager include drift counts in SDLC
  health reports? Deferred: integrate only after the skill has
  observed usage and the signal sources are stable.
