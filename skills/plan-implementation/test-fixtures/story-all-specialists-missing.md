# Story: Implement Multi-Region Failover for Database

**Type:** Feature
**Priority:** Critical

## Description

As a site reliability engineer, I want the database layer to support automatic
failover to a secondary region so that a regional outage does not cause more
than 60 seconds of downtime for end users.

## Acceptance Criteria

- [ ] Automatic failover to secondary region completes within 60 seconds of
      primary failure detection
- [ ] Application reconnects without manual intervention
- [ ] Failover events are logged and trigger PagerDuty alerts
- [ ] Read replicas in the secondary region are kept current (replication lag
      < 5 seconds under normal load)

## Notes

This story touches infrastructure, database configuration, and observability.
It is expected to match multiple routing table specialists.

**All-missing simulation:** To exercise the "all specialists missing" branch,
configure all routing table specialists so that they either use unresolvable
slugs or return empty responses. Run this story. Phase 2 must still run with
all-missing notices. The Tech Lead should synthesize a best-effort plan from
conventions alone and explicitly flag the complete specialist coverage gap.

**Expected skill behavior:**

- All specialist slots recorded as "No response received" or "could not be
  resolved"
- Phase 2 runs regardless (it is NOT skipped)
- Tech Lead synthesis explicitly flags that all consultations failed
- A best-effort plan is produced from conventions and Tech Lead's own knowledge
