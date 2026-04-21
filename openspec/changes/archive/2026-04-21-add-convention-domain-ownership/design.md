# Design: Convention Domain Ownership

## Context

The Tech Lead agent definition at `agents/tech-lead.md` declares the Tech
Lead as "convention owner for the project" and carries four convention-facing
operating contexts:

1. **Convention-Review** (line ~331): reviews changes against established
   conventions, flags violations, candidates, and gaps.
2. **Quick Consultation** (line ~351): answers "what's the convention for X"
   questions.
3. **Convention Authorship** (line ~362): drafts new conventions.
4. **Convention Gap Identification** (line ~382): identifies what convention
   would have prevented an inconsistency.

The Tech Lead's memory schema (line ~82) tracks a single "Conventions
Directory" path and a "Conventions Index" catalog. The index format does not
carry ownership metadata: entries are referenced only by name and path.

Other leadership agents already own authoritative procedures in adjacent
domains:

- **DevOps Lead** owns operational doctrine, runbook authorship via
  `/write-runbook`, CI/CD pipeline shape, and deployment strategy. Convention
  candidates in its domain (pipeline structure, runbook format, rollback
  gates) surface naturally from its work but currently have no authorship
  path unless they flow through the Tech Lead.
- **QA Lead** owns test strategy via `/plan-test-strategy`, brittleness
  assessment, and coverage gap analysis. Convention candidates (test layer
  selection, suite structure, flake policy, gate criteria) surface from its
  work and have the same problem.
- **UX Strategist** owns behavioral consistency checks, persona guidance, and
  interaction primitives. Convention candidates (error-message voice,
  accessibility baselines, interaction primitives, empty-state shape)
  surface from its work.
- **Chief Architect** owns ADR authorship via `/write-adr`, one-way-door
  evaluation, and long-term trajectory decisions. Convention candidates (ADR
  format, decision-record structure, forward-compatibility checks) surface
  from its work.

The current model forces these owners to either consult the Tech Lead
outside its tactical-implementation expertise, document conventions
informally without registration in the index, or skip the convention step
entirely. The result is under-coverage in the operational, quality, UX, and
architectural domains.

The `tech-lead-routing` capability spec at `openspec/specs/tech-lead-
routing/spec.md` does not cover convention ownership; convention authorship
is specified only in the agent definition. No existing capability spec
documents the conventions index format or the authorship flow, so this
change introduces a new capability spec rather than modifying an existing
one.

## Goals / Non-Goals

**Goals:**

- Give each convention a single declared domain owner, with the owner agent
  responsible for authoring drafts in its domain.
- Reframe the Tech Lead's convention responsibility so the registrar role
  and the tactical-implementation author role are both preserved, while
  other domains have their own author agents.
- Make the ownership matrix legible to human readers (the README) and to
  each agent (its own definition) so convention authorship routes to the
  right agent without user intervention.
- Preserve full backward compatibility. Existing conventions index entries,
  existing Tech Lead memory files, and existing `/write-adr` and
  `/write-runbook` skill behaviors continue to work unchanged.
- Provide a single authorship entry point (`/write-convention`) that routes
  by declared domain, so users do not need to memorize per-domain slash
  commands.

**Non-Goals:**

- Enforcing ownership at runtime. Ownership is a social and organizational
  signal surfaced in drafts, the index, and the README. Nothing blocks an
  agent from authoring outside its domain if the user explicitly requests
  it; the skill and agent definitions steer toward the owner without gating.
- Multi-owner conventions. A convention that genuinely spans two domains
  is represented by a single primary owner plus a note in the document;
  full multi-owner semantics (split responsibility, concurrent edits,
  cross-domain approval) are deferred.
- Migrating existing conventions to new owners. The default read-time
  behavior maps unannotated entries to `tactical-implementation` owned by
  `tech-lead`. A migration skill that walks the index and prompts for domain
  and owner is a later change.
- Deprecating `/write-adr` or `/write-runbook`. Those skills remain the
  canonical authorship path for ADRs and runbooks respectively; they are
  not rebranded as convention authorship. The `/write-convention` skill
  authors general conventions in each domain; it does not replace
  domain-specific artifact skills.
- Changing how the Tech Lead's Convention-Review or Convention Gap
  Identification operates. Those remain cross-domain and are performed by
  the Tech Lead. The change is to Convention Authorship specifically.

## Decisions

### D1. Five convention domains with a single owner per domain

The five domains and their owners are:

- `tactical-implementation`: Tech Lead. Covers code-level conventions that
  span modules (ID generation, time serialization, configuration structure,
  error-handling shape, retry patterns). This is the default domain when no
  domain is declared.
- `infrastructure`: DevOps Lead. Covers conventions for pipelines,
  deployment, environments, runbook format, rollback gates, and operational
  tooling.
- `quality`: QA Lead. Covers conventions for test strategy, suite
  structure, layer selection, flake policy, and quality gates.
- `ux`: UX Strategist. Covers conventions for interaction primitives,
  error-message voice, accessibility baselines, empty-state shape, and
  behavioral consistency.
- `architecture`: Chief Architect. Covers conventions for ADR format,
  decision-record structure, forward-compatibility checks, and one-way-door
  signals at the schema and public-interface level.

**Rationale:** Five domains map directly onto the five non-process-oriented
leadership agents that already exist and have authoritative procedures in
adjacent areas. Each domain is broad enough to cover a real body of
convention work and narrow enough that one agent can author it coherently.
The Agile Coach, Engineering Manager, and Product Owner are deliberately
excluded: their jurisdictions are process health, SDLC meta-observation, and
prioritization respectively, none of which produce code-adjacent conventions
in the sense this model describes.

**Alternatives considered:** Fewer, broader domains (for example, combine
`quality` and `architecture` under one "engineering" domain). Rejected:
collapses two agents' jurisdictions into one, defeating the purpose of the
change. More, narrower domains (separate `security`, `data`, `api`
domains). Rejected: no leadership agent owns security or data as a primary
jurisdiction in the current model; those concerns surface through the
Chief Architect or a specialist.

### D2. Tech Lead is cross-domain registrar and tactical-implementation author

The Tech Lead's convention responsibility is explicitly scoped so that:

- Convention Authorship in the `tactical-implementation` domain remains the
  Tech Lead's responsibility. The current authorship procedure is retained
  verbatim for that domain.
- Convention Authorship in the other four domains is delegated. The Tech
  Lead does not author drafts in those domains; instead, it points the user
  (or the `/write-convention` skill) at the domain owner.
- The Tech Lead remains the **registrar of record** for the conventions
  index across all domains. After a domain owner drafts a convention, the
  Tech Lead registers it in the index with the domain and owner recorded.
- The Tech Lead remains the **cross-domain reviewer**: when a new or
  modified convention in one domain has implications in another, the Tech
  Lead surfaces the cross-domain dependency.
- The Tech Lead remains the **gap identifier**: when an inconsistency
  surfaces, the Tech Lead identifies which domain it belongs in and which
  owner should consider a convention draft.

**Rationale:** The Tech Lead already has the cross-module perspective
needed for index management and cross-domain review. Domain owners already
have the depth in their area needed for authorship. This split puts each
responsibility on the agent whose jurisdiction centers it.

**Alternatives considered:** Remove the Tech Lead from convention work
entirely. Rejected: the index and the cross-domain review role have no
other natural home; the Tech Lead's cross-module view is the right fit.
Also considered: distribute registrar responsibility to each domain owner
(each owner maintains a per-domain index). Rejected: fragments the index
and makes cross-domain consistency harder. Also considered: make every
agent its own registrar with no central index. Rejected: defeats the point
of a conventions registry.

### D3. `/write-convention` skill with `--domain` routes to the owner agent

A new skill at `skills/write-convention/SKILL.md` accepts a
`--domain=<domain>` argument (and a positional alternative) and produces a
draft convention in the domain's format. The skill:

- Validates the domain against the five-string vocabulary. An unknown
  domain is a warning with a list of valid values, then the skill prompts
  for a valid domain.
- Routes the drafting procedure to the owner agent. The owner agent is
  identified by domain via a fixed mapping in the skill.
- Reads the project's convention template from memory (via the Tech Lead's
  `Conventions Directory` path) so the draft follows the established
  structure.
- Writes a draft file in the conventions directory with frontmatter that
  records the domain and owner, and leaves the draft marked for review
  rather than self-promoting it to active.
- Does not register the draft in the index. The Tech Lead performs
  registration after review, consistent with D2.

When the `--domain` argument is omitted, the skill defaults to
`tactical-implementation` (owned by the Tech Lead), preserving the current
"Tech Lead drafts everything" behavior for users who do not opt into
domain routing.

**Rationale:** A single entry point avoids per-domain slash-command
proliferation (`/write-tactical-convention`, `/write-infra-convention`, and
so on) while still routing authorship to the right agent. A `--domain`
argument is consistent with the positional-plus-flag ergonomics used by
`/add-specialist`. Defaulting to `tactical-implementation` preserves
back-compat for users who have not yet learned the domain vocabulary.

**Alternatives considered:** Per-domain slash commands (`/write-infra-
convention`, `/write-ux-convention`, and so on). Rejected: five new slash
commands for what is structurally one authorship flow. Also considered:
extend each owner agent's existing artifact skill (`/write-runbook`,
`/write-adr`) to cover conventions in its domain. Rejected: conflates
conventions (generalizable patterns) with specific artifact types
(ADRs, runbooks) and overloads those skills.

### D4. Index entries gain optional `domain` and `owner` fields

The conventions index (catalog of documented conventions, tracked by the
Tech Lead in memory per the current `Conventions Index` memory field) is
extended so every entry MAY declare a domain and an owner. Entries that
omit the fields are read as `domain: tactical-implementation` and
`owner: tech-lead` at read time, so existing index files round-trip
unchanged.

Proposed entry syntax (the exact writing format is internal to the skill
and the Tech Lead's memory; the semantic model is fixed):

```markdown
- `<convention-name>` — `<path-to-doc>` — `domain: <domain>` — `owner: <agent>`
```

For `tactical-implementation` entries owned by `tech-lead`, the trailing
`domain` and `owner` suffixes MAY be omitted so the existing index format
round-trips cleanly.

**Rationale:** Optional fields with sensible defaults preserve back-compat.
Two fields (domain and owner) are separated rather than combined because
future multi-owner scenarios (deferred per Non-Goals) may want to record
multiple owners without losing the domain label.

**Alternatives considered:** Reformat the index as a table with a
`Domain` and `Owner` column. Rejected: forces a migration for every
existing project and loses the lightness of the current list format.
Also considered: infer domain and owner from the convention file's own
frontmatter and skip index-level metadata. Rejected: makes the index
less useful as a catalog-at-a-glance and forces the Tech Lead to read
every convention file to produce a Quick Consultation answer.

### D5. Convention document frontmatter records domain and owner

Every convention document authored via `/write-convention` carries a
YAML frontmatter block with at minimum:

```yaml
---
name: <convention-name>
domain: <domain>
owner: <agent>
status: draft
---
```

The `status` field remains at its current `draft` value until a human
merges the convention. The `domain` and `owner` fields are fixed at
authorship time and match the index entry written at registration.

Existing conventions without frontmatter are treated as
`domain: tactical-implementation` and `owner: tech-lead` at read time. A
later migration skill MAY walk existing conventions and prompt for
frontmatter; this change does not ship that skill.

**Rationale:** Recording domain and owner in the document makes the
convention self-describing when read outside the index. Keeping the
existing `status: draft` convention preserves the "drafts until merged"
rule from the Tech Lead's current authorship procedure.

**Alternatives considered:** Record domain and owner only in the index.
Rejected: the document loses provenance when read on its own. Also
considered: record owner as a GitHub handle or name rather than an
agent ID. Rejected: the agent ID is the routing key; human ownership
belongs in a separate per-project metadata file if a project wants it.

### D6. Each owner agent definition gains a Convention Authorship subsection

The DevOps Lead, QA Lead, UX Strategist, and Chief Architect agent
definitions each gain a Convention Authorship subsection under their
respective operating contexts. The subsection documents:

- The agent's declared domain (one of the five from D1).
- The triggers that surface a convention candidate from its work (for
  example, the DevOps Lead surfaces pipeline-shape candidates during
  CI/CD reviews; the QA Lead surfaces test-structure candidates during
  suite audits).
- The drafting procedure, which mirrors the Tech Lead's existing
  Convention Authorship procedure (read template, research pattern, draft,
  note deviations, output for review).
- An explicit handoff to the Tech Lead for index registration after the
  draft is reviewed.
- A cross-reference to `/write-convention --domain=<domain>` as the
  authorship entry point.

The Tech Lead's existing Convention Authorship subsection is scoped to the
`tactical-implementation` domain only. The other three subsections
(Convention-Review, Quick Consultation, Convention Gap Identification)
remain cross-domain and unchanged.

**Rationale:** Each owner agent already contains its domain's deep
knowledge. Adding a Convention Authorship subsection re-uses the pattern
the Tech Lead already documents, keeping the authorship flow consistent
across agents. Explicit handoff to the Tech Lead for registration makes
the registrar role legible from each owner's definition.

**Alternatives considered:** Have each owner agent also register the
convention directly. Rejected: duplicates registrar logic across agents
and makes the index vulnerable to divergent formats. Also considered:
pull Convention Authorship into a shared skill that each agent can
invoke. Rejected: the drafting procedure is short and the agent-level
customization (domain-specific triggers, domain-specific template
expectations) is valuable enough to keep in the agent definition.

### D7. README gains a Convention Ownership Matrix

The top-level `README.md` gains a "Convention Ownership Matrix" section
that lists each domain, its owner agent, example conventions in that
domain, and the slash command that authors in that domain. The section
is cross-referenced from each owner agent definition and from the
`/write-convention` skill.

**Rationale:** Ownership is an organizational signal. Users need one
place to discover who owns what without reading every agent definition.
The README is where users look first.

**Alternatives considered:** Put the matrix in the plugin's
`CLAUDE.md` (project-specific instructions). Rejected: `CLAUDE.md` is
for authoring conventions, not runtime guidance. Also considered: put
the matrix in a new `docs/conventions.md` file. Rejected: adds a new
file for a small piece of discoverability that fits naturally in the
README.

## Risks / Trade-offs

- **Ownership diffusion.** Distributing authorship across five agents
  risks the opposite problem the current model has: conventions that
  everyone owns are ones nobody maintains. Mitigation: each domain has
  exactly one owner, not a committee. The Tech Lead's cross-domain
  registrar role is preserved precisely so a single agent still tracks
  the aggregate state.
- **User confusion about which agent to consult.** With authorship
  distributed, users may not know which agent to ask. Mitigation: the
  README matrix documents the mapping. The `/write-convention` skill
  routes by domain argument so the user does not have to route manually.
  The Tech Lead's Quick Consultation remains the fallback for "what's
  the convention for X" questions; it points at the owner if drafting
  is needed.
- **Back-compat drift if the default domain changes.** The default of
  `tactical-implementation` must be preserved for existing entries and
  existing user workflows. Mitigation: the default is documented as an
  explicit decision; changing it would be a follow-up change with its
  own spec and an explicit migration path.
- **Unregistered drafts.** An owner agent might produce a draft that
  never gets registered in the index. Mitigation: each owner's
  Convention Authorship subsection includes an explicit handoff to the
  Tech Lead for registration. The audit skill MAY surface unregistered
  convention files as orphans in a later change.
- **Cross-domain conventions.** Some genuine conventions span two
  domains (for example, an error-envelope format has both
  `tactical-implementation` and `ux` facets). Mitigation: D1's rule is
  "single primary owner" and the document frontmatter can note a
  secondary consulting agent. Full multi-owner semantics are deferred.
- **Agent definition size growth.** Each owner agent gains a new
  operating-context subsection, growing the definition by a short
  section. Mitigation: the subsection is short (triggers, drafting
  procedure, handoff) and follows an established template across
  agents.

## Migration Plan

No migration required. The change is additive.

- Existing conventions index files continue to parse. Entries without
  declared `domain` and `owner` fields default to
  `domain: tactical-implementation` and `owner: tech-lead` at read time.
- Existing convention documents without frontmatter default to the same
  domain and owner at read time. The Tech Lead's existing convention
  authorship (for the default domain) continues to work unchanged.
- The Tech Lead's Convention Authorship subsection is narrowed in scope
  but the procedure is unchanged for `tactical-implementation`
  conventions. Existing users who only author in that domain see no
  behavior change.
- The DevOps Lead, QA Lead, UX Strategist, and Chief Architect gain a
  new subsection; no removal of existing behavior.
- Rollback: remove `/write-convention`, remove the Convention Authorship
  subsections from the four owner agents, restore the Tech Lead's
  "convention owner for the project" framing, remove the README matrix,
  and remove the capability spec. Existing conventions and existing
  index entries continue to resolve correctly under the reverted model
  because the current model is a superset of "everything is
  tactical-implementation owned by tech-lead."

## Open Questions

- Should the `/write-convention` skill spawn the owner agent directly
  via the Agent tool, or emit a consultation request for the Tech Lead's
  routing model to dispatch? Deferred: the initial implementation can
  emit a consultation request, which is consistent with the existing
  routing infrastructure and avoids coupling the skill to Agent-tool
  invocation details. A direct-spawn path is a follow-up if usage
  warrants it.
- Should the convention document frontmatter record the reviewer as well
  as the owner (for example, an architecture convention drafted by the
  Chief Architect but reviewed by the Tech Lead)? Deferred: the current
  authorship model treats reviewer as the human merger of the draft; an
  explicit reviewer field is easy to add if projects request it.
- Should a convention be allowed to declare a secondary consulting
  domain (for example, an error-envelope convention with primary
  `tactical-implementation` and consulting `ux`)? Deferred: the initial
  model is single-owner plus informal notes in the document; formal
  multi-domain support is a follow-up.
- Should the audit skill (`/audit-routing-table` or a sibling) check for
  conventions whose declared owner does not match the domain mapping
  (for example, a `quality` convention owned by `tech-lead` instead of
  `qa-lead`)? Deferred: useful, but the initial ownership model does not
  need enforcement to be valuable; add the check in a later change once
  the mapping has stabilized.
- Should the five-domain vocabulary be extensible by projects (for
  example, a project adds a `data` domain owned by a specialist)?
  Deferred: the fixed vocabulary is simpler initially; extensibility
  is a follow-up once the first round of feedback arrives.
