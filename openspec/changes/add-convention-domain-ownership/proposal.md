# Change Proposal: Convention Domain Ownership

## Why

The plugin positions the Tech Lead as the sole convention owner. The agent
definition at `agents/tech-lead.md` states the Tech Lead is "convention owner
for the project" and carries authorship responsibility in the "Convention
Authorship" operating context. The Convention Gap Identification,
Convention-Review, and Quick Consultation subroutines also flow through the
Tech Lead. This works for cross-domain, tactical-implementation conventions
(ID generation, time serialization, configuration structure), but creates
awkward ownership in domains where other leadership agents have deeper
expertise:

- **Infrastructure and deployment conventions** (CI/CD pipeline shape,
  deployment stages, runbook format, rollback gates) naturally belong to the
  DevOps Lead, who already owns operational doctrine and runbook authorship.
- **Test strategy and quality gate conventions** (what to test, how to
  structure suites, gate criteria, flake policy) naturally belong to the QA
  Lead, who already owns test strategy and brittleness assessment.
- **UX and interaction conventions** (interaction primitives, error-message
  voice, behavioral consistency, accessibility baselines) naturally belong to
  the UX Strategist, who already owns behavioral consistency checks and
  persona guidance.
- **Architectural conventions** (ADR format, one-way-door signals, forward-
  compatibility checks) naturally belong to the Chief Architect, who already
  owns ADR authorship via `/write-adr` and long-term trajectory decisions.

Today all of these flow through the Tech Lead, which either forces Tech Lead
consultations outside its tactical-implementation expertise or leaves
domain-specific conventions undocumented because the owner defaults to the
wrong agent. Cross-agent collaboration on conventions happens informally, if
at all, and the conventions index has no per-entry owner field.

The result is a bottleneck: projects that want to grow convention coverage in
the operational, quality, UX, or architectural domains must route every draft
through an agent whose jurisdiction does not center those domains. Users end
up either consulting the Tech Lead outside its expertise, consulting the
domain leader informally without producing a convention, or skipping the
convention step entirely.

## What Changes

- Introduce a convention ownership model with declared domain owners.
  Conventions are categorized into five domains: `tactical-implementation`,
  `infrastructure`, `quality`, `ux`, and `architecture`. Each domain has a
  single declared owner agent.
- Reframe the Tech Lead's convention responsibility to **cross-domain
  registrar and tactical-implementation author**. The Tech Lead continues to
  author conventions in the `tactical-implementation` domain (the current
  default behavior), and gains an explicit role as the registry-of-record for
  the conventions index across all domains, performing cross-domain
  consistency review and gap identification at the seams between domains.
- Extend the DevOps Lead, QA Lead, UX Strategist, and Chief Architect agent
  definitions so each gains convention-authorship responsibility within its
  domain. Each owner agent becomes the primary author for drafts in its
  domain and consults the Tech Lead for registration and cross-domain
  consistency.
- Add a `/write-convention` skill that accepts a `--domain=<domain>`
  argument. The skill routes convention authorship to the correct owner
  agent's drafting procedure and produces a draft with the declared domain
  and owner recorded in the document frontmatter.
- Extend the conventions index format so every entry records its domain and
  its owner. Entries that omit the field default to `tactical-implementation`
  owned by the Tech Lead, preserving backward compatibility.
- Document the ownership matrix in the top-level `README.md` so readers
  (human and agent) can see which agent owns which convention domain and
  which slash commands author conventions in each domain.

## Capabilities

### New Capabilities

- `convention-domain-ownership`: declared convention domains with a single
  owner agent per domain. Covers the five-domain vocabulary, the Tech Lead's
  reframed role as cross-domain registrar, per-owner authorship
  responsibilities on the DevOps Lead, QA Lead, UX Strategist, and Chief
  Architect, the `/write-convention` skill with a `--domain` argument, the
  conventions-index format extension, and the README ownership matrix.

### Modified Capabilities

None. No existing capability spec covers convention authorship or the
conventions index. This change adds the capability rather than modifying an
existing one.

## Impact

- **Users:** Can consult the correct domain owner directly for conventions
  in that domain. Projects can grow convention coverage in multiple domains
  in parallel without bottlenecking through a single agent. The README
  ownership matrix makes the right entry point discoverable.
- **Tech Lead agent:** Convention responsibility is reframed, not removed.
  The Tech Lead remains the author for `tactical-implementation` conventions
  (the current default domain) and gains an explicit cross-domain registrar
  role covering index registration, cross-domain consistency review, and gap
  identification at domain seams. The Convention Authorship subroutine is
  scoped to the `tactical-implementation` domain; the Convention Gap
  Identification and Convention-Review subroutines remain cross-domain.
- **DevOps Lead, QA Lead, UX Strategist, Chief Architect:** Each gains a
  Convention Authorship responsibility for its declared domain. Each agent
  definition documents the domain it owns and points to the `/write-
  convention --domain=<domain>` entry point. Each agent defers index
  registration and cross-domain review to the Tech Lead.
- **New `/write-convention` skill:** Accepts a domain argument and routes
  the draft to the owner agent's drafting procedure. Writes the draft with
  domain and owner recorded in the document frontmatter. When the domain is
  omitted, defaults to `tactical-implementation` and routes to the Tech Lead.
- **Conventions index format:** Every entry gains optional `domain` and
  `owner` fields. Entries without these fields default to
  `tactical-implementation` owned by `tech-lead` at read time, so existing
  index files round-trip unchanged. The audit skill MAY surface entries with
  a missing or mismatched owner as a later follow-up.
- **README:** Gains a "Convention Ownership Matrix" section listing each
  domain, its owner agent, example conventions in the domain, and the slash
  command that authors in that domain. Cross-referenced from each owner
  agent definition.
- **Token cost:** Minor. The `/write-convention` skill is new but short.
  Each agent definition gains one operating-context subsection scoped to its
  domain. The index-entry format gains two optional fields.
- **Existing projects:** No migration required. Existing conventions without
  declared domain or owner default to `tactical-implementation` owned by the
  Tech Lead at read time. A later change MAY add a migration skill that
  walks the index and prompts for domain and owner on each entry; this
  change does not ship that skill.
- **Non-goals:** Enforcing ownership at runtime is out of scope; ownership
  is an organizational signal surfaced in drafts, the index, and the README,
  not a gate. Removing the Tech Lead's convention responsibility entirely is
  out of scope; the Tech Lead remains the registrar and the tactical-
  implementation author. Migrating existing conventions to new owners is
  out of scope; migration is case-by-case. Multi-owner conventions (those
  that genuinely span two domains) are represented by a single primary
  owner plus a note; full multi-owner semantics are deferred.
