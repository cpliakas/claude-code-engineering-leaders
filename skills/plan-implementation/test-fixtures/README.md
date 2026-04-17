# Plan-Implementation Skill: Test Fixtures

Manual test inputs for the `/plan-implementation` skill. Each file exercises a
specific execution branch. Use these to validate the skill's behavior after any
changes to `SKILL.md` or `agents/tech-lead.md`.

## Validation Checklist

Run each fixture by invoking `/plan-implementation <file-path>` and confirming
the expected behavior described in the table below.

| Fixture | Branch | Expected Outcome |
|---|---|---|
| (no argument) | Empty `$ARGUMENTS` | Skill prompts for story body; does not proceed |
| `story-no-specialists.md` | No routing table matches | Phase 1 output returned with "no specialists matched" notice; Phase 2 skipped |
| `story-parse-failure.md` | Phase 1 parse failure | Raw Phase 1 output returned with parse-failure notice; Phase 2 skipped |
| `story-slug-missing.md` | Specialist slug not resolvable | Specialist skipped; miss recorded in Phase 2 input; Phase 2 runs |
| `story-specialist-empty.md` | Specialist returns empty response | Miss recorded in Phase 2 input; Phase 2 runs with the gap flagged |
| `story-all-specialists-missing.md` | All specialists missing | Phase 2 runs with all-missing notices; Tech Lead flags the gap explicitly |
| `story-happy-path.md` | Multi-specialist happy path | All specialists respond; Phase 2 synthesis includes all responses verbatim |

## How to Trigger the Empty-Arguments Branch

Run the skill with no argument:

```
/plan-implementation
```

The skill must prompt for the story body and must not proceed without one.
Confirm it does not fabricate or guess a story.

## Reproducibility Check (tasks 5.4)

Run `/plan-implementation test-fixtures/story-happy-path.md` twice consecutively
with the same project memory. Confirm:

- The same set of specialists is identified in both runs
- The section ordering in the synthesis is comparable
- No specialist is present in one run but absent in the other
