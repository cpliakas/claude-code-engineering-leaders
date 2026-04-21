# Change Proposal: Re-Onboarding Drift Detection Skill

## Why

The plugin's `/onboard` skill (and the per-agent `/onboard-<agent>`
companions) collect project context in a single pass at install time.
Projects then evolve: team size changes, the tech stack shifts, a new
ADR lands at a different path, a convention file gets renamed,
specialists come and go, the issue tracker changes hands. Onboarding
answers persist in agent memory, but no mechanism tells the user when
those answers no longer match reality.

The failure mode is quiet. Agents keep giving advice that was correct
six months ago but is subtly wrong today. A Product Owner references
an issue tracker the team migrated away from. A Tech Lead routes to a
specialist file that moved. A Chief Architect cites an ADR directory
that was reorganized. No single invocation fails loudly; trust in the
agents just degrades over time. Users have no command that surfaces
the diff between what memory claims and what the project now looks
like.

## What Changes

- Introduce a new user-invokable skill: `skills/re-onboard/`. The
  skill takes no required arguments and, by default, audits every
  onboarded agent's project memory for drift against cheaply
  derivable project signals. An optional agent-name argument narrows
  the audit to a single agent.
- Derivable signal sources the skill compares against memory:
  - File and directory existence (conventions directory, ADR
    directory, test directory claimed by QA Lead, specialist routing
    files).
  - Presence of CI configuration files when memory claims CI is in
    use (for example, `.github/workflows/`, `.circleci/`, `.gitlab-ci.yml`).
  - Git remote URL when memory claims a hosting platform (for
    example, GitHub vs GitLab).
  - Issue tracker detection via presence of `.beads/`, `.github/`,
    project-level config hints.
  - Specialist agent files present in `agents/` compared against the
    specialists listed in the Tech Lead's routing table.
- Emit a per-agent diff report that groups items into three buckets:
  **changed** (memory says X, filesystem suggests Y), **unchanged**
  (memory still matches), and **new** (signal exists that memory does
  not mention). Each changed item is phrased as a question the user
  confirms or dismisses, never as a fact.
- Confirm interactively before writing any update. The skill never
  edits memory without an explicit user confirmation per item. A
  batch-confirm option is available for users who want to accept all
  findings at once.
- Integrate with the Layer 1 shared context at
  `.claude/agent-memory/engineering-leaders/PROJECT.md` so that drift
  detected in shared context propagates the audit to agents whose
  memory references it.
- Document the skill in the top-level `README.md` alongside the
  existing `/onboard` and audit skills. Include guidance on when to
  run it (periodic cadence, after a structural project change, when
  an agent gives advice that feels out of date).

## Capabilities

### New Capabilities

- `reonboard-drift-detection-skill`: a user-invokable skill that
  compares each onboarded agent's project memory against cheaply
  derivable project signals, produces a diff report per agent, and
  updates memory only after explicit user confirmation. Covers the
  shared `PROJECT.md` layer and the per-agent memory layers. Derives
  signals from the filesystem, git remote, and presence of
  tracker-specific directories. Never modifies memory without
  confirmation.

### Modified Capabilities

<!-- No existing capability is modified. The new skill is additive and
reads existing onboarding outputs without changing their shape. -->

## Impact

- **Users:** One command surfaces onboarding drift across all
  onboarded agents with concrete deltas instead of open-ended
  "anything changed?" questions. Re-onboarding takes a fraction of
  the original time because only drifted items are surfaced. Users
  can run it on demand and drive it into whatever cadence suits them.
- **Agents:** No agent definition changes. Every agent that uses
  `memory: project` becomes drift-auditable. Agents that reference
  the shared `PROJECT.md` inherit drift coverage for the shared
  layer automatically.
- **`/onboard` and `/onboard-<agent>` skills:** No behavior change.
  The new skill is a diff pass on top of the data those skills
  produce, not a replacement for re-running them. Users who want a
  full refresh continue to re-run the relevant onboarding skill.
- **`/audit-agent-memory` skill:** No behavior change. The two
  skills are complementary: audit-agent-memory asks "what should
  stay?" while re-onboard asks "what is still accurate?" They can
  be run independently.
- **`/audit-routing-table` skill:** No behavior change. If the
  re-onboard skill detects specialist drift, it points the user at
  `/audit-routing-table` for a deeper routing-specific audit rather
  than duplicating that skill's checks.
- **Existing projects:** No migration required. The skill is
  additive and reads existing memory shapes. Projects that never
  ran `/onboard` see a friendly message and exit.
- **Token cost:** Running the skill has a per-invocation cost. The
  payoff is that agent advice stays aligned with project reality
  over the project lifetime, reducing the cost of rework when an
  agent routes to a renamed file or cites a defunct tracker. The
  skill itself does not add to any agent's memory.
- **Non-goals:** Continuous background drift monitoring, automatic
  drift fixes without confirmation, drift detection for content
  that is not derivable from files (team norms, philosophy,
  preferences remain un-diffable without user input), memory schema
  migration, and replacement of `/onboard`. These remain out of
  scope.
