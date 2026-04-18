# Story: Add Dark Mode Toggle

## User Story

As a power user, I want to toggle dark mode in my account settings so that I
can use the application comfortably in low-light environments.

## Acceptance Criteria

- Given I am on the Account Settings page, when I toggle "Dark Mode", then the
  application immediately switches to the dark color scheme.
- Given I have enabled dark mode, when I log out and log back in, then dark
  mode is still active.
- Given I am using the application on mobile, when dark mode is enabled, then
  the mobile view also uses the dark color scheme.

## Out of Scope

- Automatic dark mode based on OS preference (follow-up story)
- Per-component dark mode overrides

## Expected Behavior During Failure Simulation

Use this fixture to test graceful degradation when a peer invocation fails
(see `README.md` for instructions on simulating a failure). The report should:

1. Name the failed peer explicitly.
2. Show "Invocation failed; input absent from this refinement." in that peer's
   section.
3. Downgrade the overall verdict to at least `needs-revision`.
4. Still include verbatim responses from the two peers that succeeded.
