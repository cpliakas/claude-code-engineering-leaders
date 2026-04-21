# Tasks

## 1. Scaffold the skill directory

- [ ] 1.1 Create `skills/re-onboard/` with `SKILL.md`
- [ ] 1.2 Add YAML frontmatter with `name: re-onboard`, a
      `description` field that names the triggering phrases
      ("re-onboard", "drift", "refresh project context",
      "onboarding drift"), `user-invokable: true`,
      `argument-hint: "[agent-name]"` (bracketed to denote
      optional), and `allowed-tools: Read, Glob, Grep, Bash, Edit`
- [ ] 1.3 Confirm the frontmatter matches the conventions used by
      `skills/audit-routing-table/SKILL.md` and
      `skills/audit-agent-memory/SKILL.md`, adjusting for the
      optional argument and the extra `Bash` and `Edit` tools this
      skill requires

## 2. Implement agent discovery

- [ ] 2.1 Document the process as a numbered section "Discover
      onboarded agents"
- [ ] 2.2 Glob `.claude/agent-memory/engineering-leaders-*/` and
      treat any directory with a readable `MEMORY.md` as an
      onboarded agent
- [ ] 2.3 Handle the zero-argument case (audit every discovered
      agent) and the single-argument case (restrict to the named
      agent's directory)
- [ ] 2.4 Document the friendly exit messages for "no onboarded
      agents found" and "named agent memory directory does not
      exist"
- [ ] 2.5 Also read
      `.claude/agent-memory/engineering-leaders/PROJECT.md` (the
      Layer 1 shared context) for shared-context drift detection

## 3. Implement the four signal checks

- [ ] 3.1 Document a numbered "Run drift checks" section with four
      named subsections matching the signal sources
- [ ] 3.2 **Filesystem path presence**: parse memory for
      directory and file path claims, check existence, glob for
      plausible alternates using a documented candidate list (for
      example, `docs/adr/` -> `docs/adrs/`, `docs/decisions/`,
      `architecture/`)
- [ ] 3.3 **Specialist agent files**: enumerate `agents/*.md`,
      compare against the specialist list parsed from the Tech
      Lead's routing table, and record both missing-from-disk and
      missing-from-memory items
- [ ] 3.4 **Git remote URL**: run `git remote get-url origin`,
      classify the hostname (GitHub, GitLab, Bitbucket, other),
      compare against the memory-claimed host, and surface the
      classification mismatch when it differs
- [ ] 3.5 **Tracker directory probes**: document the canonical
      footprints (`.beads/` for Beads, `.github/ISSUE_TEMPLATE/`
      as a hint for GitHub Issues, and so on), probe for the
      memory-claimed tracker's footprint, and surface both missing
      expected footprints and unexpected new ones
- [ ] 3.6 Confirm none of the checks require network access,
      credentials, or authentication

## 4. Implement the question-phrased findings format

- [ ] 4.1 Document that every finding carries the memory-claimed
      value, the derived value or signal observation, and a
      yes-or-no question
- [ ] 4.2 Document the prohibited phrasing ("the path is now",
      "memory should say") and the required phrasing (question
      form: "Does X still look right?")
- [ ] 4.3 Document the free-text override path so the user can
      supply a value different from the derived one

## 5. Implement shared-context propagation

- [ ] 5.1 Document that drift detected in `PROJECT.md` appears
      under a dedicated `## Shared Context` section of the report
- [ ] 5.2 Document that the section lists every per-agent memory
      that references `PROJECT.md` (parsed by looking for the
      shared-context pointer line that the onboarding skills
      write)
- [ ] 5.3 Document that a confirmed shared-context update is
      applied exactly once to `PROJECT.md` and is not re-prompted
      per dependent agent memory

## 6. Implement the confirmation flow

- [ ] 6.1 Document that the default flow is one yes-or-no
      confirmation per drift item
- [ ] 6.2 Document that `Edit` applies accepted updates in place
      to the existing memory file and never creates a new file
- [ ] 6.3 Document that dismissed findings leave the corresponding
      memory file unchanged
- [ ] 6.4 Document that the batch-accept option is offered only
      after the user has answered at least two individual
      findings in the current run

## 7. Implement the un-diffable content guardrail

- [ ] 7.1 Document the un-diffable categories (team norms, persona
      preferences, stakeholder relationships, philosophy,
      free-text rationales) and state that the skill does not
      prompt drift questions for them
- [ ] 7.2 Document the optional end-of-run reminder that lists
      the un-diffable categories the user may wish to refresh
      manually

## 8. Implement the fixed report structure

- [ ] 8.1 Document the section order in `SKILL.md`:
      `## Summary`, `## Shared Context` (omitted when empty),
      `## Per-Agent Drift`, `## Confirmation`, `## Next Step`
- [ ] 8.2 Document the per-agent subsection structure: drifted,
      unchanged-notable, new items, each under a named subheading
- [ ] 8.3 Document the `## Next Step` rule: when more than half
      of an agent's onboarding-derived memory surface has
      drifted, suggest a full `/onboard-<agent>` re-run instead
      of item-by-item confirmation

## 9. Document the skill in the top-level README

- [ ] 9.1 Add a short entry to the README onboarding section
      introducing `/re-onboard` with one paragraph of framing and
      a one-sentence "when to use it"
- [ ] 9.2 Cross-reference `/onboard`, `/audit-routing-table`, and
      `/audit-agent-memory` so readers see the four skills as a
      family
- [ ] 9.3 State that the skill edits memory only after explicit
      user confirmation and does not replace a full
      `/onboard-<agent>` re-run

## 10. Author unit-like validation of the skill shape

- [ ] 10.1 Manually read `SKILL.md` and confirm the numbered
      process sections (discover, run checks, propagate shared
      context, confirm, report) are present
- [ ] 10.2 Confirm `allowed-tools` in the frontmatter matches
      what the body requires: Read, Glob, Grep, Bash, Edit. No
      Write
- [ ] 10.3 Confirm `argument-hint` names the optional
      `[agent-name]` parameter
- [ ] 10.4 Confirm each of the four signal-source descriptions
      documents its heuristic and its fallback behavior
- [ ] 10.5 Confirm every example finding in `SKILL.md` uses
      question-form phrasing and quotes both the memory value and
      the derived value

## 11. Dry-run the skill against shipped agents

- [ ] 11.1 Dry-run `/re-onboard` against a project with two
      onboarded agents and confirm the report lists both under
      `## Per-Agent Drift`
- [ ] 11.2 Dry-run `/re-onboard tech-lead` against a project with
      a specialist removed from disk and confirm the specialist
      check surfaces the drift
- [ ] 11.3 Dry-run against a project whose ADR path was renamed
      from `docs/adr/` to `docs/adrs/` and confirm the filesystem
      path check surfaces the rename with the alternate as a
      suggestion
- [ ] 11.4 Dry-run against a project whose git remote moved from
      GitHub to GitLab and confirm the git remote check surfaces
      the hostname classification mismatch
- [ ] 11.5 Dry-run against a project that switched from Beads to
      GitHub Issues and confirm the tracker probe surfaces the
      absent `.beads/` footprint
- [ ] 11.6 Dry-run with a missing memory directory for a named
      agent and confirm the skill exits cleanly with the
      documented friendly message
- [ ] 11.7 Dry-run on a project with no onboarded agents and
      confirm the skill exits cleanly with the documented
      friendly message

## 12. Validate question-phrased findings and confirmation flow

- [ ] 12.1 Confirm at least one drift finding in a dry-run emits
      question-form phrasing and quotes both values
- [ ] 12.2 Confirm dismissing a finding leaves the memory file
      byte-identical by comparing before-and-after content
- [ ] 12.3 Confirm accepting a finding edits the memory file in
      place without creating a new file (verify by listing the
      directory before and after)
- [ ] 12.4 Confirm the batch-accept option does not appear on the
      first finding of a run

## 13. Validate shared-context propagation

- [ ] 13.1 Seed `PROJECT.md` with a drifted value and two
      per-agent memories that reference it, then dry-run and
      confirm the `## Shared Context` section lists both
      dependents
- [ ] 13.2 Confirm accepting the shared-context update edits
      `PROJECT.md` once and does not re-prompt per dependent

## 14. Internal consistency review

- [ ] 14.1 Confirm no agent definition in `agents/` was modified
- [ ] 14.2 Confirm no existing skill in `skills/` was modified
- [ ] 14.3 Confirm the README entry references the skill by the
      same name used in the frontmatter (`re-onboard`)
- [ ] 14.4 Confirm the report format described in `SKILL.md`
      matches the format described in the spec file scenarios
- [ ] 14.5 Confirm the signal-source count in `SKILL.md` matches
      the four documented in the spec (filesystem path,
      specialist files, git remote, tracker probe)
