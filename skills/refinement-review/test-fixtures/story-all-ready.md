# Story: Export Audit Log as CSV

## User Story

As a compliance officer, I want to export the audit log as a CSV file so that
I can provide records to auditors without needing database access.

## Acceptance Criteria

- Given I am on the audit log page, when I click "Export CSV", then a download
  starts and I receive a CSV file with the visible log entries.
- Given the audit log has more than 1,000 entries, when I export, then the
  export contains all entries matching the current filter, not just the
  visible page.
- Given an export is in progress, when I navigate away from the page, then the
  download continues in the background.

## Out of Scope

- Scheduled/automated CSV exports
- Export in formats other than CSV (e.g., PDF, Excel)
- Filtering by date range within the export dialog (use existing filters first)

## Technical Notes

The export endpoint should stream the response to avoid loading all rows into
memory. Authentication is required; the export respects the user's existing
row-level access.

## Definition of Done

- Feature flag removed before release
- Acceptance criteria verified in staging by QA
