# Tasks

## 1. Author README orchestration-tiers section

- [x] 1.1 Add a top-level section to `README.md` titled "Tech Lead Orchestration
      Tiers" positioned near the existing "Plan Implementation for a Refined
      Story with the Tech Lead" example
- [x] 1.2 Document all three tiers by name (`1 — Direct specialist`,
      `2 — Standard`, `3 — Full (with Architect escalation)`) with one
      paragraph of framing per tier and a one-sentence "when to use it"
- [x] 1.3 Include at least two concrete examples per tier drawn from realistic
      engineering work
- [x] 1.4 Cross-reference the existing Tech Lead example and the
      `/plan-implementation` and `/refinement-review` sections so readers
      understand how tiers interact with the existing workflow

## 2. Author the signals catalog

- [x] 2.1 Add a "Signals Catalog" subsection inside the new orchestration-
      tiers section documenting touched-file count bands, domain count,
      one-way-door vocabulary, new-pattern vocabulary, and the unfamiliar-
      area heuristic
- [x] 2.2 Include an "If in doubt, escalate" callout with a one-paragraph
      explanation of why defaulting downward is the failure mode the catalog
      prevents
- [x] 2.3 Cross-reference the Chief Architect's description triggers (one-way
      door, cross-cutting, schema/API commitment) by name so tier 3 promotion
      signals align with the Architect's own invocation vocabulary
- [x] 2.4 State explicitly that the catalog is guidance, not gates, and that
      an explicit user-stated tier always wins

## 3. Update Tech Lead agent definition

- [x] 3.1 Add a tier-identification step at the top of the Implementation
      Planning response mode procedure that precedes Phase 1
- [x] 3.2 Document the tier-1 exit path: if tier 1 is identified, the Tech
      Lead names the single most relevant specialist and exits without
      running the full routing pass
- [x] 3.3 Add a preamble to Rule 4 scoping the "no exceptions" clause to
      tiers 2 and 3 (tier 1 work should not reach the Tech Lead; if it did,
      the agent nudges toward direct specialist invocation)
- [x] 3.4 Update the Phase 1 output template to include an `## Engagement
      Tier` line positioned directly after `## Engagement Depth`, with the
      fixed vocabulary `1 — Direct specialist` / `2 — Standard` /
      `3 — Full (with Architect escalation)`
- [x] 3.5 Update the Parseable Phase 1 Output Contract subsection to document
      the new `## Engagement Tier` anchor and note that parsers MAY ignore
      it (backward compatibility)
- [x] 3.6 Update the Phase 2 synthesis procedure so the Escalation Flags
      section, when tier is 3, explicitly names the Chief Architect, quotes
      the specialist-surfaced signal, and recommends pausing for Architect
      consultation before implementation
- [x] 3.7 Cross-reference the README signals catalog from the agent so the
      two documents stay aligned
- [x] 3.8 Add an explicit user-override note: when the caller states a tier
      in the invocation, the Tech Lead uses the stated tier and records the
      override in its Engagement Depth rationale

## 4. Validate contract compatibility

- [x] 4.1 Read `skills/plan-implementation/SKILL.md` and confirm its Phase 1
      parser uses only the anchors documented in the contract (it should
      match `## Consultation Requests`, `### [Specialist Agent Name]`,
      `**Agent:**`, `**Prompt:**`, `## Next Step`)
- [x] 4.2 Confirm the new `## Engagement Tier` line does not fall between
      any of those anchors in a way that would confuse parsing
- [x] 4.3 Document in the agent's Parseable Phase 1 Output Contract that
      `## Engagement Tier` is a non-breaking addition

## 5. Internal consistency review

- [x] 5.1 Re-read the updated `agents/tech-lead.md` and confirm Rule 4's
      wording still reads as a strong invariant within its scoped tiers
- [x] 5.2 Re-read the updated `README.md` and confirm the signals catalog
      is concrete (named vocabulary, numeric bands) rather than platitudinous
- [x] 5.3 Confirm no text changes were made to `agents/chief-architect.md`
- [x] 5.4 Confirm no text changes were made to
      `skills/plan-implementation/SKILL.md`
- [x] 5.5 Confirm no text changes were made to
      `skills/refinement-review/SKILL.md`

## 6. Manual verification

- [x] 6.1 Dry-run the Tech Lead on a single-file rename story and confirm
      tier 1 is identified, one specialist is named, and no full routing
      pass occurs
- [x] 6.2 Dry-run the Tech Lead on a three-file change within one domain
      and confirm tier 2 is identified and the standard two-phase protocol
      runs
- [x] 6.3 Dry-run the Tech Lead on a cross-cutting story containing
      one-way-door vocabulary and confirm tier 3 is identified and the
      Phase 2 synthesis names the Chief Architect in Escalation Flags
- [x] 6.4 Dry-run the Tech Lead with an explicit user-stated tier and
      confirm the override wins and is recorded in the Engagement Depth
      rationale
- [x] 6.5 Dry-run `/plan-implementation` on a representative story and
      confirm the skill continues to parse Phase 1 output successfully with
      the new `## Engagement Tier` line present
