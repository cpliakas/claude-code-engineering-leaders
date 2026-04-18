# Refinement Review Skill: Test Fixtures

Manual test inputs for the `/refinement-review` skill. Each file exercises a
specific execution branch. Use these to validate the skill's behavior after any
changes to `SKILL.md` or the three peer agent definitions.

## Validation Checklist

Run each fixture by invoking `/refinement-review <file-path>` and confirming
the expected behavior described in the table below.

| Fixture | Branch | Expected Outcome |
|---|---|---|
| (no argument) | Empty `$ARGUMENTS` | Skill prompts for story body; does not invoke any peer |
| `story-all-ready.md` | All three peers return `ready` | Consolidated report opens with `READY`; no `## Objections` section |
| `story-needs-revision.md` | One peer returns `needs-revision` | Report opens with `NEEDS REVISION`; named peer listed; `## Objections` section present |
| `story-blocked.md` | One peer returns `blocked` | Report opens with `BLOCKED`; named peer listed; `## Next Steps` recommends escalation |
| `story-peer-failure.md` | One peer invocation fails | Report names the failed peer; overall verdict downgrades to at least `needs-revision` |

## How to Trigger the Empty-Arguments Branch

Run the skill with no argument:

```
/refinement-review
```

The skill must prompt for the story body or issue reference and must not
invoke any peer until input is provided. Confirm it does not fabricate a story.

## How to Verify Parallel Fan-Out

When running any story fixture, confirm that all three Agent tool calls
(`product-owner`, `chief-architect`, `ux-strategist`) appear in a single
assistant turn, not spread across three separate turns.

## How to Simulate a Peer Failure

To simulate a peer invocation failure, run `/refinement-review
skills/refinement-review/test-fixtures/story-peer-failure.md` and deny the
`product-owner` Agent tool call permission in the UI when prompted. The report
should:

1. Show `NEEDS REVISION` (at minimum) as the overall verdict.
2. Name `product-owner` as failed.
3. Still include verbatim responses from `chief-architect` and `ux-strategist`.
4. Show "Invocation failed; input absent from this refinement." in the
   `product-owner` section.
