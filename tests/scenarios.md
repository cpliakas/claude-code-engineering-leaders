# Agent Test Scenarios

Test scenarios for validating agent behavior individually and across the
relationship model. Run each scenario by invoking the named agent with the
prompt text, then check the expected behaviors.

## How to Use

1. Open a project where this plugin is installed
2. Invoke the agent named in each scenario
3. Provide the prompt text
4. Check the **Expected Behaviors** — each is a binary pass/fail

Score: count passes / total expected behaviors. Track scores over time to
detect regressions after agent changes.

---

## Part 1: Individual Agent Walkthroughs

### PO-1: Feature proposal in current phase

**Agent:** product-owner
**Prompt:** "We need to add input validation to the user registration form. It's
part of our current sprint work and follows the existing validation pattern we
use elsewhere."

**Expected Behaviors:**

- [ ] Advises **proceed** (aligns with current phase)
- [ ] Does not recommend consulting chief-architect or ux-strategist (follows established pattern, small scope)
- [ ] Stays in jurisdiction — does not suggest implementation details

### PO-2: Feature proposal crossing phase boundary

**Agent:** product-owner
**Prompt:** "I want to add a real-time notification system. We'd need WebSocket
infrastructure, a notification preferences UI, and email digest fallback. We
haven't started any real-time features yet — our current phase is focused on
finishing the core CRUD workflows."

**Expected Behaviors:**

- [ ] Advises **defer** or recommends splitting — some work belongs to a later phase
- [ ] References sequencing principles (infrastructure before features, don't start phase N+1 before N is stable)
- [ ] Identifies which pieces could be done now vs. deferred
- [ ] Recommends `/write-epic` or `/write-spike` to scope the work formally

### PO-3: Uncertain work area

**Agent:** product-owner
**Prompt:** "We're thinking about adding SSO support but we don't know which
providers to support, whether to use SAML or OIDC, or how it interacts with
our existing auth system."

**Expected Behaviors:**

- [ ] Recommends `/write-spike` — too uncertain to story-write
- [ ] Does not produce a story or epic directly
- [ ] Identifies the key unknowns that the spike should resolve

### PO-4: Strategic triage after authoring

**Agent:** product-owner
**Prompt:** "Write a story for migrating our user data model from a flat
structure to a normalized schema with separate profile and preferences tables."

**Expected Behaviors:**

- [ ] Authors the story (via `/write-story`)
- [ ] Strategic triage fires: recommends consulting `chief-architect` (schema change is a one-way door)
- [ ] Does not recommend consulting `ux-strategist` (no new interaction pattern)

### PO-5: Strategic triage — UX consultation

**Agent:** product-owner
**Prompt:** "Write a story for adding a bulk delete feature to the dashboard.
Users can currently only delete items one at a time."

**Expected Behaviors:**

- [ ] Authors the story
- [ ] Strategic triage fires: recommends consulting `ux-strategist` (new interaction pattern — bulk operations behave differently from single-item operations)
- [ ] May or may not recommend `chief-architect` depending on scope assessment

---

### CA-1: One-way door detection

**Agent:** chief-architect
**Prompt:** "We're going to change our API response format from envelope style
({ data: ..., meta: ... }) to flat JSON responses. We have three external
consumers."

**Expected Behaviors:**

- [ ] Flags as a **one-way door** (public API contract with external consumers)
- [ ] Risk rating is High or Critical
- [ ] Includes a proceed-anyway path with mitigations (versioning, deprecation period)
- [ ] Suggests this warrants an ADR
- [ ] Does not suggest implementation details — stays at the strategic level

### CA-2: Two-way door — light touch

**Agent:** chief-architect
**Prompt:** "We're thinking of switching our internal logging from Winston to
Pino. Same structured JSON output, just a different library."

**Expected Behaviors:**

- [ ] Flags as a **two-way door** (internal implementation, easily reversed)
- [ ] Risk rating is Low
- [ ] Provides a brief conversational response, not a full structured assessment
- [ ] Does not recommend an ADR

### CA-3: Forward compatibility check

**Agent:** chief-architect
**Prompt:** "We're building a permissions system with simple role-based access
(admin, editor, viewer). In six months we'll need attribute-based access
control for enterprise customers. Should we worry about that now?"

**Expected Behaviors:**

- [ ] Assesses current decision against future transition
- [ ] Identifies low-cost investments now that reduce transition cost later
- [ ] Distinguishes what to build now vs. what to defer
- [ ] Names the trade-off explicitly

### CA-4: Stays out of domain specialist territory

**Agent:** chief-architect
**Prompt:** "Should we use a B-tree or hash index on the users table email
column?"

**Expected Behaviors:**

- [ ] Defers to domain knowledge — this is a local implementation choice
- [ ] Does not produce a full architectural assessment
- [ ] May offer a brief opinion but flags that this is not an architectural concern

---

### UX-1: Implementation-focused ACs

**Agent:** ux-strategist
**Prompt:** "Review this story for UX:

As a user, I want to reset my password so that I can regain access to my account.

Acceptance Criteria:
1. POST /api/auth/reset returns 200 with a JWT token
2. Token expires after 3600 seconds in Redis
3. The password_hash column is updated with bcrypt cost factor 12
4. Email is sent via SendGrid API with template ID sg-reset-001"

**Expected Behaviors:**

- [ ] Flags all four ACs as implementation-focused (system internals, not user-observable)
- [ ] Rewrites each AC as a user-observable outcome (e.g., "User receives an email with a reset link within 2 minutes")
- [ ] Identifies the persona (user/account holder)
- [ ] Recommendation is **Revise ACs**

### UX-2: Behavioral consistency check

**Agent:** ux-strategist
**Prompt:** "We have a 'delete' action on list items that shows a confirmation
dialog and moves items to trash. Now we're adding a 'delete' action on the
settings page that permanently deletes without confirmation. Is this okay?"

**Expected Behaviors:**

- [ ] Flags the behavioral inconsistency — "delete" means different things in different contexts
- [ ] Identifies the existing pattern users have learned (confirmation + trash)
- [ ] Assesses whether the deviation is justified or accidental
- [ ] Recommends alignment or, if justified, recommends signaling the difference to the user
- [ ] References behavioral consistency rule (#4)

### UX-3: Persona guidance

**Agent:** ux-strategist
**Prompt:** "I'm writing a story for the 'system administrator' persona. They
need to manage API keys for their organization."

**Expected Behaviors:**

- [ ] Checks whether "system administrator" is a canonical persona or needs correction
- [ ] Recommends the appropriate persona mode (active user)
- [ ] If the project has no personas defined yet, notes that this is an opportunity to establish canonical persona definitions in memory

### UX-4: Complexity budget assessment

**Agent:** ux-strategist
**Prompt:** "We want to add a visual query builder to let users construct complex
data filters with AND/OR logic, nested groups, and custom field selection. Our
users are small business owners who check their dashboard once a day."

**Expected Behaviors:**

- [ ] Flags complexity budget concern — small business owners checking a dashboard daily have low tolerance for complex interactions
- [ ] Questions whether the feature earns its cognitive load
- [ ] Suggests simpler alternatives or progressive disclosure
- [ ] Grounds the recommendation in the persona's needs

---

### AC-1: Clean story passes

**Agent:** agile-coach
**Prompt:** "Review this story:

As a hiring manager, I want to filter candidates by interview stage so that I
can focus on candidates who need my attention this week.

Acceptance Criteria:
1. When I select a stage filter, only candidates in that stage appear in my list
2. When I clear the filter, all candidates reappear
3. My filter selection persists when I navigate away and return to the list

Out of scope: Saving named filter presets, combining multiple filters.

Definition of Done: Unit tests for filter logic, manual smoke test on staging."

**Expected Behaviors:**

- [ ] INVEST scores are mostly or all PASS
- [ ] Coaching principles are mostly or all PASS
- [ ] Notes the story is well-structured
- [ ] Produces the structured report format

### AC-2: Horizontal work detection

**Agent:** agile-coach
**Prompt:** "Review this story:

As a developer, I want to migrate the database from PostgreSQL 14 to
PostgreSQL 16 so that we can use the latest features.

Acceptance Criteria:
1. Database is running PostgreSQL 16
2. All existing data is preserved
3. No downtime during migration"

**Expected Behaviors:**

- [ ] Flags Valuable as FAIL — no user-visible outcome, "latest features" is not a benefit to the developer persona
- [ ] Flags Vertical Slice principle as FAIL — pure infrastructure, no user-facing change
- [ ] Recommends reclassification as a technical task or enabler
- [ ] Notes that the Architect may have context on whether this is a legitimate enabler (per relationship model)
- [ ] Hands off to product-owner for prioritization advice

### AC-3: Coupled ACs

**Agent:** agile-coach
**Prompt:** "Review this story:

As a customer, I want to place an order so that I receive my products.

Acceptance Criteria:
1. I add items to my cart
2. After step 1, I proceed to checkout
3. After step 2, I enter my shipping address
4. After step 3, I confirm and pay
5. After step 4, I receive an order confirmation email"

**Expected Behaviors:**

- [ ] Flags Each AC Independently Testable as FAIL — criteria form a sequential chain
- [ ] Flags Small as FAIL or borderline — this covers the entire purchase flow
- [ ] Suggests splitting vertically or restructuring ACs as independent outcomes
- [ ] Provides specific rewrites

---

## Part 2: Cross-Agent Tension Scenarios

### TENSION-1: Architect approves, UX Strategist flags

**Setup:** First, invoke `chief-architect` with:

"We're going to normalize our settings storage from a single JSON blob per user
into a relational schema with separate tables for notification preferences,
display preferences, and integration settings. This gives us better query
performance and lets us add new preference categories without schema changes."

**Expected from Architect:**

- [ ] Likely approves or proceeds with modifications — sound technical decision
- [ ] Flags as a one-way door (schema change)
- [ ] Notes forward compatibility benefit

**Then invoke `ux-strategist` with:**

"The architect recommends normalizing user settings into separate tables. Today
users experience settings as a single page where everything saves together.
After normalization, different setting categories might save independently,
load at different speeds, or show partial failures. Review for UX impact."

**Expected from UX Strategist:**

- [ ] Flags behavioral consistency concern — settings currently save atomically, normalization could break that mental model
- [ ] Identifies the user impact: partial saves, inconsistent load states
- [ ] Does not override the Architect — surfaces the tension for the PO to arbitrate
- [ ] Recommends that if the team proceeds, the UI should maintain atomic save behavior regardless of backend normalization

### TENSION-2: PO arbitrates competing advice

**Agent:** product-owner
**Prompt:** "The Chief Architect recommends normalizing our settings schema into
separate tables — it's a sound technical decision that improves query
performance and forward compatibility. The UX Strategist flags that this could
break the user's mental model of settings saving atomically, and recommends
maintaining atomic save behavior in the UI regardless. How should we proceed?"

**Expected Behaviors:**

- [ ] Presents the tension clearly (what each agent recommends and why)
- [ ] Frames the trade-off (technical benefit vs. UX risk)
- [ ] Offers a lean with reasoning
- [ ] **Defers to the user** for the final decision — does not decide autonomously
- [ ] Suggests recording the decision in memory

### TENSION-3: Coach flags horizontal work, Architect context needed

**Agent:** agile-coach
**Prompt:** "Review this story:

As a developer, I want to add a message queue between the API and the
notification service so that notification delivery doesn't block API responses.

Acceptance Criteria:
1. API publishes notification events to the queue
2. Notification service consumes events from the queue
3. API response times are unaffected by notification delivery delays"

**Expected Behaviors:**

- [ ] Flags as horizontal work (Vertical Slice principle) — no user-visible outcome
- [ ] Notes that the Chief Architect may have context on whether this is a legitimate enabler within the technical trajectory
- [ ] Recommends reclassification as a technical task or enabler
- [ ] Hands off to product-owner for prioritization

### TENSION-4: Coach can't determine readiness, consults PO

**Agent:** agile-coach
**Prompt:** "Review this story:

As an admin, I want to configure SSO providers so that my team can use their
corporate credentials to log in.

Acceptance Criteria:
1. Admin can add an SSO provider with a metadata URL
2. Admin can test the SSO connection before enabling it
3. Team members see a 'Sign in with SSO' option on the login page

Note: We discussed SSO as a Phase 3 feature but the enterprise customer asked
for it urgently."

**Expected Behaviors:**

- [ ] Story quality review proceeds normally (INVEST, coaching principles)
- [ ] Flags that readiness classification is unclear — the note suggests phase ambiguity
- [ ] Consults `product-owner` for roadmap context rather than guessing at phase fit
- [ ] Does not make a sprint-ready vs. backlog determination independently

### TENSION-5: UX Strategist and Agile Coach complementary review

**Setup:** First, invoke `agile-coach` with:

"Review this story:

As a user, I want to export my data so that I can use it in other tools.

Acceptance Criteria:
1. GET /api/export returns a CSV file with Content-Disposition header
2. The export includes all user-created records from the records table
3. Large exports are streamed using chunked transfer encoding"

**Expected from Coach:**

- [ ] Flags AC Outcome-Orientation as FAIL — criteria reference HTTP headers, database tables, and transfer encoding
- [ ] Provides structural rewrites but may lack domain language for the user-observable versions

**Then invoke `ux-strategist` with the same story and the Coach's output:**

"The Agile Coach flagged these ACs as implementation-focused. Can you provide
user-observable rewrites grounded in the persona's language?"

**Expected from UX Strategist:**

- [ ] Rewrites ACs in user-observable terms (e.g., "When I click Export, I receive a CSV file I can open in Excel")
- [ ] Adds persona context that the Coach couldn't provide
- [ ] Demonstrates the complementary relationship — Coach flags the structure problem, UX Strategist provides the domain-grounded fix

---

## Part 3: Specialist Routing Scenarios

### SR-1: Register-only path

**Setup:** Ensure `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`
exists (or will be created). No `my-backend-specialist` entry present.

**Action:** Run `/add-specialist my-backend-specialist`

**Expected Behaviors:**

- [ ] Attempts to locate `agents/my-backend-specialist.md` and warns if absent
- [ ] Creates or updates the memory file with a `## Registered Specialists`
  section
- [ ] Adds `- \`my-backend-specialist\`` to `## Registered Specialists`
- [ ] Does NOT add any row to `## Project Code Area Overrides`
- [ ] Output confirms registration and mentions `/audit-routing-table` as a
  follow-up step

### SR-2: Register with code-area override

**Setup:** `my-payments-specialist` not yet registered.

**Action:** Run `/add-specialist my-payments-specialist "src/payments/**"`

**Expected Behaviors:**

- [ ] Registers `my-payments-specialist` in `## Registered Specialists`
- [ ] Appends a row `| \`src/payments/**\` | my-payments-specialist |` to
  `## Project Code Area Overrides`
- [ ] Output shows both the registration and the override row
- [ ] Output mentions `/audit-routing-table`

### SR-3: Override redundancy warning

**Setup:** Register `qa-lead` (whose description body contains the phrase
"test strategy").

**Action:** Run `/add-specialist qa-lead "test strategy"`

**Expected Behaviors:**

- [ ] Detects that "test strategy" appears in `qa-lead`'s description
- [ ] Warns the user that the override is redundant
- [ ] Asks whether to proceed before writing the row
- [ ] If user says no, skips the override but still registers the agent
- [ ] Output explains what was written vs. skipped

### SR-4: Tech Lead routing via description match

**Setup:** Register `my-backend-specialist` whose description contains
"REST API" and "endpoint design".

**Action:** Invoke `@agents/tech-lead Plan the implementation for: Add a new
REST API endpoint for user profile retrieval.`

**Expected Behaviors:**

- [ ] Phase 1 output includes a `## Consultation Requests` section
- [ ] `my-backend-specialist` appears under `## Consultation Requests`
- [ ] Output does NOT reference a "Specialist Routing Table"; matching is
  described in terms of description matching
- [ ] Phase 1 format is parseable: `## Consultation Requests`, `### <Name>`,
  `**Agent:** \`my-backend-specialist\``, `**Prompt:**`, `## Next Step`

### SR-5: Broken pointer warning

**Setup:** Add `ghost-specialist` to `## Registered Specialists` with a path
that does not exist: `- \`ghost-specialist\` — \`agents/ghost-specialist.md\``

**Action:** Invoke `@agents/tech-lead Plan the implementation for any issue.`

**Expected Behaviors:**

- [ ] Phase 1 output includes a routing warning about `ghost-specialist` in
  `## Preliminary Constraints`
- [ ] Other registered specialists (if any) still route correctly
- [ ] No consultation request is emitted for `ghost-specialist`
- [ ] The warning is explicit, not silent

### SR-6: Audit routing table — clean project

**Setup:** Project has one registered specialist with a readable agent file.
No override rows. No redundant signals.

**Action:** Run `/audit-routing-table`

**Expected Behaviors:**

- [ ] All four checks report PASS
- [ ] Summary table shows PASS for all checks
- [ ] No files are modified
- [ ] Report is human-readable

### SR-7: Audit routing table — all four findings

**Setup:** Manually craft a MEMORY.md with:
- An orphan override row (target agent not in Registered Specialists)
- A registered specialist whose agent file does not exist
- A redundant override row (signal text appears in the agent's description)
- A registered specialist with a description under 60 words

**Action:** Run `/audit-routing-table`

**Expected Behaviors:**

- [ ] Check 1 flags the orphan override with the agent name and recommended action
- [ ] Check 2 flags the broken pointer with the missing path
- [ ] Check 3 flags the redundant override, identifying which description
  contains the signal
- [ ] Check 4 flags the thin description with the actual word count
- [ ] Summary table shows N finding(s) for each failing check
- [ ] No files are modified
- [ ] Report ends with a reminder that no auto-fix occurred

### SR-8: plan-implementation regression

**Setup:** Register at least one specialist whose description matches a known
issue topic. Ensure the MEMORY.md uses the new `## Registered Specialists`
format (no `## Specialist Routing Table` section).

**Action:** Run `/plan-implementation` on the issue.

**Expected Behaviors:**

- [ ] Phase 1 produces `## Consultation Requests` with the matched specialist
- [ ] Phase 1 output is parseable: `**Agent:** \`<name>\`` and `**Prompt:**`
  anchors are present
- [ ] Phase 2 synthesis runs after specialist responses are fed back
- [ ] Final plan is produced in the synthesis format

### SR-9: Onboard — simplified Q8

**Setup:** Fresh project (or use a test project with no existing memory).

**Action:** Run `/onboard` through to Step 4 and provide one specialist name
when prompted.

**Expected Behaviors:**

- [ ] Q8 does NOT ask for code areas or trigger keywords — only agent names
- [ ] `/add-specialist <name>` is invoked with the agent name only (no signals)
- [ ] Step 5 summary mentions `/audit-routing-table` as a follow-up hygiene step
- [ ] MEMORY.md after onboarding uses `## Registered Specialists` format, not
  `## Specialist Routing Table`
