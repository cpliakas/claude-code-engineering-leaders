# Change Proposal: Plan-Implementation Skill

## Summary

Introduce a new skill (`/plan-implementation`) that deterministically executes the Tech Lead's existing two-phase consultation protocol. The skill accepts a story or issue reference, drives Phase 1 (routing), spawns each matched specialist as a sub-agent in parallel, then drives Phase 2 (synthesis) with the collected specialist responses. The output is a single synthesized implementation plan with verbatim specialist quotes and any escalation flags surfaced.

## Motivation

The Tech Lead's implementation-planning response already uses a two-phase consultation protocol because sub-agents cannot spawn further sub-agents (see tech-lead.md:94-97 and issue #3). Phase 1 emits structured consultation requests; the caller is expected to spawn each specialist and feed their responses back for Phase 2 synthesis.

In practice, the protocol depends entirely on the caller — the main Claude Code loop and the human driving it — to faithfully execute both phases. Users routinely:

- Stop after Phase 1 and treat the routing output as the plan
- Skip or forget to spawn some specialists
- Forget to re-invoke the Tech Lead for Phase 2
- Feed partial responses into Phase 2

As a result, the "better plans through specialist consultation" benefit the plugin advertises is delivered unevenly, and mostly only when a disciplined user drives the workflow. A deterministic skill closes that gap.

## Goals

- Provide a single user-invokable entry point that performs both phases end-to-end without manual orchestration
- Guarantee that Phase 2 synthesis runs on every invocation where Phase 1 matched at least one specialist
- Preserve specialist responses verbatim in the final synthesis (per the Tech Lead's verbatim rule)
- Degrade gracefully when no specialists match the routing table, producing a Tech-Lead-only plan with an explicit notice
- Keep the two-phase structure visible to advanced users who want to run Phase 1 alone

## Non-Goals

- Replace the two-phase protocol — this skill operationalizes it, not replaces it
- Change the Tech Lead agent's behavior beyond any clarifications needed for reliable Phase 1 parsing
- Make the Tech Lead spawn sub-agents directly (platform constraint)
- Support multi-turn refinement of specialist responses (single fan-out round only)
- Cover incident analysis or retrospective consultation modes (separate skills can reuse the same pattern)

## Proposed Change

Add a skill at `skills/plan-implementation/SKILL.md` that:

1. Accepts a story body, issue reference, or file pointer as `$ARGUMENTS`
2. Invokes the Tech Lead for Phase 1 with the story context
3. Parses the Tech Lead's Phase 1 output — specifically the `## Consultation Requests` section — extracting each specialist agent name and prompt
4. Spawns each matched specialist as a sub-agent in parallel, using the Tech Lead's emitted prompts verbatim
5. Collects specialist responses and re-invokes the Tech Lead for Phase 2 synthesis with all responses concatenated under a structured heading
6. Returns the synthesized plan to the user
7. Handles the no-specialists-matched path by surfacing the Tech-Lead-only plan with an explicit notice
8. Handles the unparseable-Phase-1-output path by surfacing the raw Phase 1 output with a clear error rather than failing silently

A small Phase-1 contract clarification in `agents/tech-lead.md` is in scope if the current markdown structure is not reliably parseable (for example, adding explicit `Agent:` and `Prompt:` field anchors that are already present but may need to be documented as the parsing contract).

## Success Metrics

- A user can invoke `/plan-implementation` on a story and receive a fully synthesized plan without any manual orchestration steps
- Phase 2 synthesis runs on 100% of invocations where Phase 1 identified at least one specialist
- Specialist responses appear verbatim in the final output
- Plan outputs are reproducible — running the skill twice on the same story with the same memory produces comparable structure
- When the routing table has no matches, the skill surfaces a single Tech-Lead-only plan with an explicit "no specialists matched" notice

## Impact

- **Users:** Gain a deterministic one-shot skill for implementation planning; the Tech Lead's specialist-consultation benefit becomes reliable rather than user-dependent
- **Tech Lead agent:** Minor clarification to the Phase 1 output contract if needed for reliable parsing; otherwise unchanged
- **Other agents:** No changes — specialists are invoked with the same prompts the Tech Lead already emits
- **Token cost:** Parallel specialist fan-out increases token burn per invocation. This is mitigated by the Tech Lead's existing engagement-depth assessment and by the fact that trivial issues should bypass this skill entirely (a separate tiered-orchestration concern tracked elsewhere)

## Risks

- **Phase 1 output format drift.** If the Tech Lead's Phase 1 markdown changes shape, the skill breaks. Mitigation: document the parseable contract in the skill's SKILL.md and reference it from the Tech Lead agent file.
- **Partial specialist failures.** If one specialist sub-agent fails or returns empty, Phase 2 could be invoked with incomplete input. Mitigation: the skill must detect empty or error responses, note them explicitly in the Phase 2 prompt, and let the Tech Lead synthesize what it has.
- **Token cost on small stories.** The skill always runs the full fan-out; trivial issues pay for a multi-specialist consultation when a one-line change would do. Mitigation: the Tech Lead's engagement-depth classification already exists and can route "Minimal" issues toward a short fan-out; tiered orchestration at the caller level is a separate concern.

## Dependencies

- Depends on the Tech Lead's existing two-phase consultation protocol being in place (it is)
- Related to issue #3 (established the two-phase protocol) and issue #4 (Explore subagent delegation pattern)
- Related to the separate tiered-orchestration concern — this skill intentionally does not tier engagement at the caller level

## Alternatives Considered

- **Modify the Tech Lead to spawn sub-agents directly.** Blocked by the platform constraint that sub-agents cannot spawn further sub-agents.
- **Hide the two-phase structure behind a single synthetic agent invocation.** Loses the visibility advanced users need for diagnosing where a plan went wrong; also requires deeper agent-runtime changes.
- **Document the manual workflow more loudly in the Tech Lead agent.** Does not fix the underlying discipline problem — users still skip Phase 2. A skill removes the discipline requirement.
