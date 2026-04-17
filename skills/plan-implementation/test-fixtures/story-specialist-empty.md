# Story: Add Rate Limiting to Public API Endpoints

**Type:** Feature
**Priority:** High

## Description

As an API platform engineer, I want rate limiting applied to all public API
endpoints so that individual clients cannot exhaust server resources and
degrade service for other users.

## Acceptance Criteria

- [ ] Rate limits are enforced at the API gateway layer
- [ ] Clients receive HTTP 429 with a `Retry-After` header when limited
- [ ] Rate limit configuration is per-client (API key) with configurable thresholds
- [ ] Metrics for rate-limit events are emitted to the observability pipeline

## Notes

This story touches the API gateway, observability pipeline, and client-facing
response contracts. It is expected to match multiple routing table specialists.

**Empty-response simulation:** To exercise the "specialist returns empty"
branch, configure the routing table to include a specialist whose agent
definition instructs it to return no output (or simulate by temporarily
replacing a real specialist's agent with a stub that emits an empty response).
Run this story. The skill should record the empty slot, continue with remaining
specialists, and proceed to Phase 2 with the miss noted.

**Expected skill behavior:**

- Specialist with empty response has slot recorded as "No response received"
- Remaining specialists' responses are included verbatim
- Phase 2 runs with the miss recorded
- Tech Lead explicitly flags the gap in the synthesis
