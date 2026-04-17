# Tasks: Plan-Implementation Skill

## 1. Tech Lead Phase 1 Output Contract

- [x] 1.1 Audit the current Phase 1 markdown emitted by tech-lead.md:114-149 against the parseable contract in `design.md`. Confirm field anchors (`**Agent:**`, `**Prompt:**`, blockquoted prompt body, `## Consultation Requests`, `## Next Step`) are reliably emitted.
- [x] 1.2 If the audit reveals drift, add a "Parseable Phase 1 Output Contract" subsection to `agents/tech-lead.md` that documents the exact field anchors and formatting rules the skill depends on. Do not expand or change the existing output format.
- [x] 1.3 Cross-reference the Phase 1 contract from the skill's SKILL.md so the dependency is discoverable from both sides.

## 2. Skill Scaffolding

- [x] 2.1 Create `skills/plan-implementation/` directory.
- [x] 2.2 Author `skills/plan-implementation/SKILL.md` with:
  - Frontmatter: `name`, `description`, `user-invokable: true`, `context: fork`, `allowed-tools: Read, Grep, Glob, Agent, Bash`, `argument-hint`, plus any other fields the project's skill convention requires.
  - Input handling: accept story body, file path, or issue reference via `$ARGUMENTS`; prompt when empty.
  - Phase 1: Tech Lead invocation with the resolved story.
  - Phase 1 parse: extract `## Consultation Requests` subsections, fields `**Agent:**` and `**Prompt:**`.
  - No-match branch: return the Phase 1 output as the final plan with an explicit "no specialists matched" notice.
  - Parse-failure branch: surface the raw Phase 1 output with an explicit parse-failure notice.
  - Parallel fan-out: spawn every matched specialist in a single batch using the verbatim prompts.
  - Empty/error response handling: mark the slot with a "No response received" notice in the Phase 2 input.
  - Phase 2: re-invoke the Tech Lead with the structured specialist-responses block defined in `design.md`.
  - Return the Phase 2 synthesis to the user.

## 3. Input Contract

- [x] 3.1 Document accepted input forms in SKILL.md: inline story markdown, file path, issue reference.
- [x] 3.2 Decide and document how the skill resolves file paths and issue references (for example, whether the skill reads the file itself or delegates to `Read` tool calls inline).
- [x] 3.3 Implement the empty-`$ARGUMENTS` prompt: the skill must not proceed without an input and must not guess.

## 4. Failure Mode Handling

- [x] 4.1 Implement the "no specialists matched" path: Phase 1 output is returned as-is with a clear notice prepended.
- [x] 4.2 Implement the "Phase 1 unparseable" path: raw output surfaced with a parse-failure notice.
- [x] 4.3 Implement the "specialist slug not resolvable" path: skip the specialist and record the miss in the Phase 2 input.
- [x] 4.4 Implement the "specialist empty/error response" path: record the miss in the Phase 2 input.
- [x] 4.5 Implement the "all specialists missing" path: Phase 2 still runs; the Tech Lead synthesizes a best-effort plan and explicitly flags the gap.

## 5. Testing & Validation

- [x] 5.1 Write a manual test script covering each failure mode listed in `design.md`. Include at least one fixture story per branch.
- [ ] 5.2 Validate on a real multi-specialist story that the final output contains every specialist's response verbatim.
- [ ] 5.3 Validate on a no-match story (empty routing table) that the skill degrades to a Tech-Lead-only plan with the documented notice.
- [ ] 5.4 Validate reproducibility: run the skill twice on the same story with the same memory; confirm the structure is comparable (same specialist set, same section ordering).

## 6. Documentation

- [x] 6.1 Add a reference to the new skill from `agents/tech-lead.md` under the Implementation Planning response mode (a note that callers can use the skill instead of executing the two phases manually).
- [x] 6.2 Add a README-level entry (or update the existing skills index if one exists) describing when to use `/plan-implementation`.
- [x] 6.3 Note the interaction with the tiered-orchestration concern: this skill always runs the full fan-out; tiering belongs at the caller level and is tracked separately.

## 7. Release

- [x] 7.1 Run the PR Review Toolkit (`pr-review-toolkit:review-pr`) against the staged changes per CLAUDE.md.
- [x] 7.2 Address any review findings.
- [x] 7.3 Bump the plugin version in `marketplace.json` per the versioning convention.
- [ ] 7.4 Commit, push, open PR.
