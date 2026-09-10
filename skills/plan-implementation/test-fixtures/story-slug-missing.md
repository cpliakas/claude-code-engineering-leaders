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
to match at least one routing model specialist.

**Missing-agent-file simulation:** To exercise the "agent file not readable"
branch, register a specialist in `## Registered Specialists` whose entry does
not correspond to an actual agent file (e.g., `payments-wizard` with no
matching `.claude/agents/payments-wizard.md` or `agents/payments-wizard.md`).
Then run this story. The skill should emit a routing warning naming the agent
and the unreadable path(s), treat the specialist as a match candidate on its
explicit registration alone, and still dispatch it alongside the other matched
specialists. Synthesis runs with the routing warning in its input.

**Expected skill behavior:**

- Unreadable agent file produces a routing warning naming the agent and the
  tried path(s)
- The specialist is still dispatched by slug — description-based matching is
  unavailable, not dispatch
- All other matched specialists are dispatched normally
- Synthesis runs with the routing warning carried forward and flagged
