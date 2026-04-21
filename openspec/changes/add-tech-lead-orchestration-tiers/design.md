# Design: Tech Lead Orchestration Tiers

## Context

The Tech Lead agent (`agents/tech-lead.md`) is the tactical orchestration
point for implementation. Its Rule 4 currently reads (paraphrased): if the
issue matches any registered specialist's description or any Code Area
Override, the Tech Lead MUST emit a consultation request for that
specialist — no exceptions. The rationale is sound for cross-cutting or
unfamiliar work: missing a specialist's input is expensive, and letting the
Tech Lead decide "I don't need this specialist" opens a failure mode where
the critical perspective gets skipped.

The same rule applied to a trivial single-domain change forces the full
two-phase consultation protocol to run for work that does not need it. In
practice that looks like:

- A five-line bug fix in one module routed through multiple specialists.
- An obvious rename touching one file, orchestrated as a multi-specialist
  synthesis.
- A repeated pattern (adding a test that mirrors three existing tests)
  producing an implementation plan that quotes specialists verbatim when the
  pattern is already established.

The opposite failure mode exists on the other end: cross-domain work with a
clear one-way-door signal (schema commitment, public API change, new
cross-cutting pattern) sometimes reaches implementation without the Chief
Architect being consulted, because the Tech Lead's Phase 2 synthesis flags
the escalation but leaves it to the user to decide whether to pause — and
under time pressure users often do not.

The `/plan-implementation` skill parses the Tech Lead's Phase 1 output as
documented in the "Parseable Phase 1 Output Contract" subsection of
`agents/tech-lead.md`. Any new machine-readable signal added to Phase 1
(such as an explicit tier line) must extend that contract without breaking
existing parsers.

## Goals / Non-Goals

**Goals:**

- Document three concrete tiers of Tech Lead engagement so users and skills
  can select the right level of orchestration for the work at hand.
- Publish a signals catalog so tier selection is based on observable story
  attributes rather than subjective judgment alone.
- Scope the existing "no exceptions" Rule 4 to tiers 2 and 3 so trivial
  single-domain work has a documented lightweight path.
- Surface Architect escalation before tier 3 implementation starts, rather
  than mid-implementation, by making the escalation a first-class output of
  the Tech Lead's Phase 2 synthesis.
- Extend the Phase 1 output contract in a backward-compatible way so tier
  data is machine readable for future skill automation.

**Non-Goals:**

- Automatic tier detection inside a skill or hook. Tier selection is
  user-facing guidance in this change; automation (e.g., in
  `/plan-implementation`) is a follow-up.
- New agents, response modes, or skills. Tiers live as documentation plus a
  small agent-definition edit.
- Changes to the Chief Architect's own definition. Tier 3 escalation reuses
  the Architect's existing description triggers.
- Rigid enforcement. Tiers are guidance. Users may override tier selection
  explicitly; the Tech Lead must respect an explicit user override.
- Retirement of Rule 4. The rule's "no exceptions" clause continues to
  govern tiers 2 and 3. Only tier 1 is exempt, and only because tier 1 work
  should not reach the Tech Lead in the first place.
- A rename of the existing `## Engagement Depth` line. The new tier marker
  lives alongside it; rename-and-deprecate is out of scope for this change.

## Decisions

### D1. Three named tiers with explicit signals

The documented tiers are:

1. **Direct specialist.** Single-domain, well-established pattern. The caller
   invokes the relevant specialist directly; the Tech Lead is skipped.
   Examples: renaming a function inside one module; adding a test that
   mirrors existing tests; fixing a typo in user-visible copy; tightening a
   literal constant.
2. **Tech Lead Standard.** Multi-file change within one domain, or an
   unfamiliar area where routing to one or two specialists is the right
   level of care. The Tech Lead runs the current two-phase protocol with
   routing limited to the matched specialists.
3. **Tech Lead Full (with Architect escalation).** Cross-domain change, new
   pattern, schema or public API commitment, or one-way-door signal. The
   Tech Lead runs the full protocol and its Phase 2 synthesis flags an
   Architect escalation **before** implementation starts. The user decides
   whether to pause for the Architect; the escalation itself is explicit
   and concrete.

**Rationale:** Three tiers are the minimum number that separate
"don't involve the Tech Lead" from "involve the Tech Lead with reduced
scope" from "involve the Tech Lead and surface the Architect before code
is written." Two tiers would collapse the Architect-escalation case back
into a mid-implementation surprise. Four or more tiers invite false
precision and make the signals catalog harder to apply.

**Alternatives considered:** A single "auto" mode where the Tech Lead picks
the tier silently. Rejected: it hides the decision from the user and
reproduces the current implicit behavior. Also considered: five tiers
mirroring a maturity model. Rejected as over-engineered for guidance that
must be memorable enough to actually be followed.

### D2. Signals catalog lives in the README, referenced from the agent

The mapping from story attributes to tiers is documented in a new README
section (the signals catalog). The Tech Lead agent references the README
rather than duplicating the catalog inline, keeping a single source of
truth.

Signals include, at minimum:

- **Touched-file count.** 1 file → tier 1 candidate; 2–5 files in one
  domain → tier 2 candidate; >5 files or multiple domains → tier 3
  candidate. Counts are guidance, not gates.
- **Domain count.** Single domain vs. multiple domains, measured against
  the registered specialist set and Code Area Overrides.
- **One-way-door vocabulary.** Explicit keywords in the story text that
  mirror the Chief Architect's description: "schema", "migration", "API
  contract", "public interface", "data model", "event envelope", and
  similar. Presence of any one promotes the story to tier 3.
- **New-pattern vocabulary.** "New pattern", "introduce", "first time",
  "convention" — promotes to at least tier 2, tier 3 if combined with
  cross-domain impact.
- **Unfamiliar-area heuristic.** If the story touches code the caller has
  not edited before (measurable from the story text or the user's own
  framing), the catalog recommends escalating one tier above the
  file-count signal alone would indicate.
- **If-in-doubt rule.** When signals conflict or are absent, the catalog
  recommends the higher of the candidate tiers. Defaulting downward to
  avoid overhead is the exact failure mode this change addresses.

**Rationale:** Concrete signals produce a catalog someone can actually
apply. A signals catalog without numbers or vocabulary devolves into
advice that sounds reasonable but cannot be checked. Including the
"if in doubt, escalate" rule counterweights the incentive to default
downward.

**Alternatives considered:** Keep the catalog inside the agent file only.
Rejected: the README is where users look first, and duplicating the
catalog across both files is a drift hazard. Also considered: make the
catalog a standalone markdown file linked from both places. Rejected for
this change as premature; revisit if the catalog grows.

### D3. Rule 4 is scoped, not removed

Rule 4 in `agents/tech-lead.md` continues to read "specialist matches
require consultation requests — no exceptions" but gains a preamble that
scopes its application to tiers 2 and 3. The Tech Lead's Implementation
Planning response mode opens with a step that identifies the operating
tier, and a tier-1 identification instructs the Tech Lead to name the
single most relevant specialist and exit without running the full routing
pass.

**Rationale:** The rule's invariant (no silent skipping of matched
specialists) is still the right behavior within the tier where it applies.
Removing or weakening it globally would reopen the skipping failure mode
it was written to prevent. Tier 1 is exempt because tier 1 work should
not be orchestrated through the Tech Lead in the first place; if the user
invoked the Tech Lead anyway, the right response is a nudge toward
invoking the specialist directly, not a full orchestration pass.

**Alternatives considered:** Replace Rule 4 with a gradient rule ("emit
consultation requests proportional to tier"). Rejected: "proportional to
tier" is vague and invites the same judgment calls the rule exists to
eliminate within its scope. Also considered: drop Rule 4 entirely and
rely on tier selection. Rejected: tier 2 and tier 3 still need the
invariant that a matched specialist is not silently skipped.

### D4. Phase 1 output gains a parseable `## Engagement Tier` line

The Tech Lead's Phase 1 structured output adds an `## Engagement Tier`
line on the line immediately following `## Engagement Depth`. Values are
the fixed vocabulary `1 — Direct specialist`, `2 — Standard`, or
`3 — Full (with Architect escalation)`. The existing `## Engagement
Depth` line is preserved unchanged so existing parsers continue to work.

**Rationale:** Adding a new line rather than repurposing Engagement Depth
preserves backward compatibility with `/plan-implementation` and any
downstream readers. The fixed vocabulary keeps parsing trivial and keeps
the written output scannable. Placing it adjacent to Engagement Depth
makes the relationship between the two concepts visible in a single
glance.

**Alternatives considered:** Repurpose `## Engagement Depth` with the new
vocabulary. Rejected: breaks existing parsing contracts for no meaningful
gain. Also considered: emit tier as a YAML frontmatter block at the top
of the Phase 1 output. Rejected: the Tech Lead's output is already a
structured markdown document; introducing frontmatter just for tier is
inconsistent.

### D5. Tier 3 escalation is named and concrete in Phase 2 output

When the Tech Lead runs Phase 2 on tier 3 work, the existing `## Escalation
Flags` section MUST (a) name the Chief Architect explicitly, (b) quote the
specific specialist-surfaced signal that triggered the escalation, and
(c) recommend pausing implementation for Architect consultation before
proceeding. If no such signal surfaces in Phase 2, the tier is implicitly
downgraded (the Tech Lead notes this in the synthesis); the recorded tier
on the Phase 1 line is not retroactively edited.

**Rationale:** The current Escalation Flags section is a list of one-way
doors without an addressee. Naming the Architect turns it from an
observation into a routing instruction. The "before implementation"
framing moves the escalation out of the mid-implementation window where
it tends to be ignored under time pressure.

**Alternatives considered:** Have the Tech Lead autonomously consult the
Architect on tier 3. Rejected explicitly in `agents/tech-lead.md`'s
existing Relationship to Other Agents: "The Architect is not directly
consulted by the Tech Lead... The user decides whether to engage the
Architect." Preserving that boundary while making the escalation concrete
is the intent here.

### D6. User override beats signal-based tier selection

If the caller explicitly states a tier in the invocation (e.g., "plan this
at tier 2"), the Tech Lead uses the stated tier and records the override
in its Engagement Depth rationale line. The signals catalog is for
defaulting in the absence of an explicit tier.

**Rationale:** The tiers are guidance, not gates. Users with context the
signals cannot capture should be able to override. The override is
recorded so that retrospectives can see when overrides are happening and
whether the signals catalog needs tuning.

**Alternatives considered:** Enforce tier selection algorithmically.
Rejected as over-engineered for a documentation change and
contradictory to the non-goal of rigid enforcement.

### D7. No changes to `/plan-implementation` parsing logic in this change

The `/plan-implementation` skill is not modified here. It continues to
parse the existing Phase 1 contract. The new `## Engagement Tier` line is
ignored by current parsers (since they look for specific anchors and do
not fail on unrecognized headings). A follow-up change can add tier-aware
short-circuiting to the skill once the model has settled.

**Rationale:** Scope discipline. This change ships the documentation and
the agent-definition edit. Skill automation is a separate, larger change
that benefits from observing the three-tier model in practice first.

**Alternatives considered:** Bundle skill tier-awareness into this change.
Rejected: doubles the surface area and risks a coupled revert if the
tier vocabulary needs adjustment based on early usage.

## Risks / Trade-offs

- **Signals catalog drift from the Chief Architect's description.** The
  one-way-door vocabulary in the catalog is chosen to mirror the Architect's
  triggers. If the Architect's description evolves, the catalog can become
  stale. **Mitigation:** The catalog lives in one place (README) and is
  cross-referenced from the agent; review the catalog whenever the
  Architect's description changes materially. Consider adding a catalog
  audit to the quarterly convention review if cadence permits.
- **Users default to tier 1 to avoid overhead.** The explicit tier 1
  option creates an incentive to pick it even for work that is genuinely
  cross-cutting. **Mitigation:** The "if in doubt, escalate" rule in the
  catalog, and the signals that auto-promote to tier 3 on specific
  vocabulary, counterweight the incentive. Revisit if early usage shows
  systematic underselection of tier 3.
- **Subjective tier boundaries.** File counts and vocabulary matches do not
  perfectly predict the right tier. Edge cases will arise.
  **Mitigation:** Document the signals as guidance with "if in doubt,
  escalate" as the tiebreaker. The tier is recorded in Phase 1 output, so
  retrospectives can review whether the choice held up and the catalog can
  be tuned.
- **Adjacent `## Engagement Depth` and `## Engagement Tier` lines feel
  redundant.** Two lines that mean similar things can confuse readers.
  **Mitigation:** The Engagement Depth rationale clause (`— one-sentence
  rationale`) is expected to reference the tier when relevant, making the
  two lines complementary rather than duplicative. If the redundancy
  becomes annoying in practice, a follow-up change can unify them.
- **Architect escalation becomes noise.** If every tier 3 flags an
  escalation, users start ignoring the signal. **Mitigation:** The Phase 2
  contract requires a specific specialist-surfaced signal (quoted) before
  escalation is named. Tier 3 stories whose synthesis surfaces no such
  signal are implicitly downgraded in the Phase 2 narrative, even though
  the Phase 1 tier line is not rewritten. The escalation is concrete or
  absent.

## Migration Plan

No migration required; the change is additive.

- Existing `agents/tech-lead.md` memory (Registered Specialists, Code
  Area Overrides, conventions index) is unaffected.
- Existing `/plan-implementation` parsers ignore the new
  `## Engagement Tier` line and continue to parse `## Engagement Depth`
  and `## Consultation Requests` as before.
- Rollback is removal of the new README section, revert of the agent-
  definition edits, and removal of the `## Engagement Tier` line from the
  Phase 1 contract. No data loss.

## Open Questions

- Should tier 0 ("skip Tech Lead entirely — invoke no one") be a formal
  fourth tier for trivially mechanical work (e.g., formatting-only
  changes)? Deferred: in practice tier 1 already covers "invoke one
  specialist" which is functionally close, and adding a tier for "invoke
  nobody" risks a proliferation of labels. Revisit if users repeatedly
  ask for it.
- Should the signals catalog eventually live in a shared memory file so
  projects can tune the thresholds per repository? Deferred: the catalog
  is guidance, and per-project tuning is better handled by explicit
  overrides in project onboarding memory rather than a plugin-level
  tunable surface.
- Should `/plan-implementation` emit a short-circuit message when the
  Tech Lead returns tier 1, explaining how to invoke the specialist
  directly? Deferred to the follow-up skill automation change that reads
  the new tier line.
