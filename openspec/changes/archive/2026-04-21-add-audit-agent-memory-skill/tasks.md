# Tasks

## 1. Scaffold the skill directory

- [x] 1.1 Create `skills/audit-agent-memory/` with `SKILL.md`
- [x] 1.2 Add YAML frontmatter with `name: audit-agent-memory`,
      a `description` field that names the triggering phrases
      ("audit memory", "agent memory hygiene", "bloated memory"),
      `user-invokable: true`, `argument-hint: "<agent-name>"`, and
      `allowed-tools: Read, Glob, Grep`
- [x] 1.3 Confirm the frontmatter matches the conventions used by
      `skills/audit-routing-table/SKILL.md`

## 2. Implement the skill body

- [x] 2.1 Document the process in four numbered sections: read memory,
      run checks, compute size, emit report
- [x] 2.2 Step "Read memory" reads
      `.claude/agent-memory/engineering-leaders-<agent>/MEMORY.md` and
      globs the directory for all `*.md` files; exits with a friendly
      message if the directory does not exist
- [x] 2.3 Step "Run checks" documents the four checks (state-like,
      strategy-like negative, dead links, size) with the heuristic
      thresholds visible inline
- [x] 2.4 Include the state-like vocabulary list (dated phrases,
      enumerated file paths, enumerated issue IDs, work-item tables)
      and the numeric thresholds (three or more enumerated items,
      ten thousand tokens for directory, four thousand tokens for
      a single file)
- [x] 2.5 Include the strategy-like vocabulary list (why-rationale,
      invariant, principle, routing, policy, definition) and
      document the downgrade rule from "state" to "mixed" when both
      trigger
- [x] 2.6 Document dead-link detection: parse `MEMORY.md` for
      relative file references, glob the directory, flag files not
      referenced from the index
- [x] 2.7 Document size computation as byte count divided by four
      for the token estimate, with thresholds inline
- [x] 2.8 Step "Emit report" documents the fixed markdown structure
      (`## Summary`, `## Findings`, `## Recommendations`,
      `## Next Step`) and the phrasing style (options, not
      directives)

## 3. Document the skill in the top-level README

- [x] 3.1 Add a short entry to the README audit-skills section
      introducing `/audit-agent-memory` with one paragraph of
      framing and a one-sentence "when to use it"
- [x] 3.2 Cross-reference `/audit-routing-table` so readers see the
      two audits as complementary
- [x] 3.3 Note that the skill is read-only and advisory; the user
      confirms or dismisses each finding

## 4. Author unit-like validation of the skill shape

- [x] 4.1 Manually read `SKILL.md` and confirm the four process
      steps are numbered and scoped
- [x] 4.2 Confirm allowed-tools in the frontmatter matches what the
      body requires: Read, Glob, Grep. No Bash, Write, or Edit
- [x] 4.3 Confirm the argument-hint names the single `<agent-name>`
      parameter and the skill errors cleanly when invoked without
      one
- [x] 4.4 Confirm the heuristic thresholds are numeric and inline
      (not abstract advice)

## 5. Dry-run the skill against shipped agents

- [x] 5.1 Dry-run `/audit-agent-memory tech-lead` and confirm the
      skill reads the existing Tech Lead memory layout, emits a
      structured report, and does not produce false positives on the
      specialist routing table (which is legitimate strategy content)
- [x] 5.2 Dry-run `/audit-agent-memory qa-lead` against a memory
      directory seeded with a plausible state-like file (dated
      coverage-gap list) and confirm the state check triggers
- [x] 5.3 Dry-run with a seeded orphan file (file exists in the
      directory but is not referenced from `MEMORY.md`) and confirm
      the dead-link check triggers
- [x] 5.4 Dry-run against a memory directory whose cumulative size
      exceeds ten thousand tokens and confirm the size check
      triggers with the correct threshold quoted
- [x] 5.5 Dry-run with a missing memory directory and confirm the
      skill exits cleanly with the documented friendly message

## 6. Internal consistency review

- [x] 6.1 Confirm no agent definition in `agents/` was modified
- [x] 6.2 Confirm no existing skill in `skills/` was modified
- [x] 6.3 Confirm the README entry references the skill by the same
      name used in the frontmatter (`audit-agent-memory`)
- [x] 6.4 Confirm the report format described in `SKILL.md` matches
      the format described in the spec file scenarios
