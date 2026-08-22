# Story: Add User Activity Feed to Dashboard

**Type:** Feature
**Priority:** Medium

## User Story

As a product manager, I want to see a real-time activity feed on the main
dashboard so that I can quickly understand what my team has been working on
without navigating to individual project pages.

## Background

The dashboard currently shows aggregate metrics but no temporal activity stream.
Teams use the audit log for compliance, but it is not designed for at-a-glance
consumption. This feature adds a lightweight activity feed component that
streams events from the existing audit log data layer.

## Acceptance Criteria

- [ ] Activity feed displays the 50 most recent events across all projects the
      user has access to
- [ ] Each event shows: event type, actor, target resource, timestamp
- [ ] Feed updates in real time via WebSocket (no manual refresh required)
- [ ] Feed respects access control: users only see events for resources they can
      access
- [ ] Feed loads in under 2 seconds on the 95th percentile for 100 concurrent
      users
- [ ] Accessibility: feed is navigable by keyboard; events announced to screen
      readers on update

## Technical Notes

- Data source: existing `audit_events` table; no new schema required
- Real-time delivery: extend existing WebSocket infrastructure
- Access control: reuse existing permission middleware
- Frontend: new React component in the dashboard shell

## Expected Skill Behavior (Happy Path)

Running `/plan-implementation test-fixtures/story-happy-path.md` on a project
with a well-populated routing model should:

1. Match: the skill reads the routing model and matches the relevant
   specialists (e.g., frontend, backend, QA, UX), classifying the story's tier
2. Dispatch: all matched specialists are dispatched in one parallel batch with
   focused prompts
3. Synthesis: the Tech Lead is invoked once and synthesizes all specialist
   responses into a final implementation plan
4. Output: a complete plan with verbatim specialist input quoted under
   "## Specialist Consultations" and a synthesized approach

The final output should contain every specialist's response verbatim (not
summarized or paraphrased). Run the skill twice on this fixture and confirm the
same specialists appear in both outputs with comparable section structure.
