# Story: Parse Failure Simulation Guide

This file documents how to simulate a Phase 1 parse failure for manual testing.
It is not a direct skill input. Use the instructions below instead.

## How to Simulate a Parse Failure

A parse failure occurs when the Tech Lead's Phase 1 output does not contain a
`## Consultation Requests` heading. This can happen if:

1. The routing table is misconfigured and the Tech Lead bypasses the structured
   format entirely
2. A future change to the Tech Lead agent modifies the Phase 1 output structure

### Simulation Method

To manually exercise the parse-failure branch:

1. Temporarily edit the Tech Lead agent's Phase 1 instructions to omit the
   `## Consultation Requests` heading from its output format
2. Run the skill with any story input (e.g., `story-happy-path.md`)
3. Confirm the skill surfaces the raw Phase 1 output with the parse-failure
   notice and does not attempt Phase 2

### Expected Output

```
[PARSE FAILURE] The Tech Lead's Phase 1 output did not contain a
## Consultation Requests section. The raw Phase 1 output follows. You may
re-run /plan-implementation or manually drive Phase 2 using the output below.

---

[raw Phase 1 output here]
```

### Cleanup

Revert the temporary Tech Lead agent edit after confirming the branch behavior.
Do not commit a modified Tech Lead agent as part of this test.
