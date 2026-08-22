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
| `story-no-specialists.md` | No routing model matches | No-specialists notice emitted; Tech Lead synthesizes a plan with zero specialist input |
| `story-slug-missing.md` | Agent file not readable | Routing warning names the agent and path; remaining specialists dispatched; synthesis flags the gap |
| `story-specialist-empty.md` | Specialist returns empty response | Miss warning emitted; synthesis runs with the gap flagged |
| `story-all-specialists-missing.md` | All specialists missing | All-missing warning emitted; Tech Lead synthesizes a best-effort plan and flags the coverage gap |
| `story-happy-path.md` | Multi-specialist happy path | All matched specialists dispatched in parallel; synthesis includes all responses verbatim |

## How to Trigger the Empty-Arguments Branch

Run the skill with no argument:

```
/plan-implementation
```

The skill must prompt for the story body and must not proceed without one.
Confirm it does not fabricate or guess a story.

## Reproducibility Check

Run `/plan-implementation test-fixtures/story-happy-path.md` twice consecutively
with the same project memory. Confirm:

- The same set of specialists is dispatched in both runs
- The section ordering in the synthesis is comparable
- No specialist is present in one run but absent in the other
