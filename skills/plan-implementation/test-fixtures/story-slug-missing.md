# Story: Migrate Billing to Stripe Checkout

**Type:** Feature
**Priority:** High

## Description

As a billing administrator, I want the checkout flow to use Stripe Checkout
instead of our custom card form so that we reduce PCI compliance scope and
leverage Stripe's built-in fraud detection.

## Acceptance Criteria

- [ ] All new subscriptions use Stripe Checkout hosted pages
- [ ] Existing subscriptions continue to renew without interruption
- [ ] Stripe webhook handler is updated for the new session lifecycle events
- [ ] Integration tests cover the checkout flow end-to-end

## Notes

This story touches the payments domain and the webhook handler. It is expected
to match at least one routing table specialist.

**Slug-missing simulation:** To exercise the "specialist slug not resolvable"
branch, register a specialist slug in the routing table that does not correspond
to an actual agent file (e.g., `payments-wizard` with no matching
`.claude/agents/payments-wizard.md`). Then run this story. The skill should
skip the unresolvable specialist, record the miss, and continue with any
remaining specialists. Phase 2 should run with the miss noted in the input.

**Expected skill behavior:**

- Unresolvable slug is skipped with a "could not be resolved" notice
- Any resolvable specialists are spawned normally
- Phase 2 runs with the miss recorded
- Tech Lead flags the routing gap in the synthesis
