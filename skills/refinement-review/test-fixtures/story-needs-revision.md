# Story: User Dashboard Redesign

## User Story

As a user, I want a redesigned dashboard so that I can see all my data in one
place.

## Acceptance Criteria

- The dashboard loads in under 2 seconds.
- All widgets from the old dashboard are present.
- The layout uses the new design system components.
- Users can rearrange widgets by dragging and dropping.
- The backend returns a 200 status code on `/api/dashboard`.

## Technical Notes

Use the new widget registry introduced in v3.1. The drag-and-drop library is
already bundled.

## Expected Behavior During Review

This story is intentionally vague in places to trigger `needs-revision` from
at least one peer:

- The "As a user" persona is non-canonical (likely to trigger UX Strategist
  concern).
- "See all my data in one place" has no clear scope boundary.
- Acceptance criteria mix user-observable outcomes with implementation details
  (HTTP status code, design system components).
- No out-of-scope statement for mobile or accessibility.

**Expected outcome:** At least one peer returns `needs-revision`. Overall
verdict should be `needs-revision`. The `## Objections` section should be
present.
