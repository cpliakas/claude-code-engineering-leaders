# Story: Migrate User Data to New Schema

## User Story

As an administrator, I want user records migrated from the legacy schema to the
new unified schema so that the new API can serve all user types.

## Acceptance Criteria

- All user records in `users_legacy` are migrated to `users_v2` with no data
  loss.
- The `users_legacy` table is dropped after migration completes.
- The migration runs as a single transaction and rolls back on error.

## Technical Notes

The `users_legacy` table has 8 million rows. The migration script will run
during a maintenance window.

## Expected Behavior During Review

This story is intentionally designed to trigger `blocked` from the Chief
Architect:

- Dropping the `users_legacy` table is a one-way door: once dropped, rollback
  requires a restore from backup.
- A single transaction over 8 million rows may exceed transaction log limits or
  lock the table for an extended period, blocking reads.
- The story does not account for application code that still references the
  legacy schema.

**Expected outcome:** The Chief Architect returns `blocked`. Overall verdict
should be `blocked`. The `## Next Steps` section should recommend resolving the
blocking concern and mention consulting the named peer directly or escalating to
the product owner for arbitration.
