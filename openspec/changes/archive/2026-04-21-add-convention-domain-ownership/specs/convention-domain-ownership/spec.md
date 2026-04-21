# Convention Domain Ownership

## ADDED Requirements

### Requirement: Five convention domains with a single owner per domain

The plugin SHALL recognize five convention domains, each mapped to a single
owner agent:

- `tactical-implementation` → `tech-lead`
- `infrastructure` → `devops-lead`
- `quality` → `qa-lead`
- `ux` → `ux-strategist`
- `architecture` → `chief-architect`

A convention's declared domain determines which agent owns authorship for
that convention. The owner agent's definition MUST declare the domain it
owns and MUST document a Convention Authorship operating-context
subsection for that domain. The domain vocabulary is fixed; unknown
domains MUST be rejected by the `/write-convention` skill with a list of
valid values.

#### Scenario: Known domain routes to the declared owner

- **WHEN** the `/write-convention` skill is invoked with
  `--domain=infrastructure`
- **THEN** the drafting flow routes to the DevOps Lead's Convention
  Authorship procedure and the draft is written with
  `owner: devops-lead` in frontmatter

#### Scenario: Unknown domain is rejected with a list of valid values

- **WHEN** the `/write-convention` skill is invoked with
  `--domain=garbage`
- **THEN** the skill emits a message listing the five valid domains and
  prompts the user for a valid value, and does not produce a draft until
  a valid domain is provided

#### Scenario: Each owner agent declares its domain

- **WHEN** a reader inspects `agents/devops-lead.md`,
  `agents/qa-lead.md`, `agents/ux-strategist.md`, or
  `agents/chief-architect.md`
- **THEN** the file contains a Convention Authorship subsection that
  names the agent's declared domain and describes the drafting procedure
  for conventions in that domain

### Requirement: Default domain and owner for unannotated entries

The plugin SHALL apply default values when a conventions index entry or
a convention document omits the `domain` or `owner` fields. A missing
`domain` field MUST resolve to `tactical-implementation` at read time,
and a missing `owner` field MUST resolve to `tech-lead` at read time.
These defaults preserve back-compat with existing projects that created
conventions before this change.

The memory-file writer and the `/write-convention` skill MUST NOT
back-fill defaults into legacy entries that already round-trip cleanly.
Writes for new `tactical-implementation` entries owned by `tech-lead`
MAY omit the suffixes to preserve the legacy row format, and writes for
any other domain or owner MUST include both fields explicitly.

#### Scenario: Legacy entry resolves to the default domain and owner

- **WHEN** the Tech Lead reads a conventions index entry with no
  `domain` or `owner` suffix
- **THEN** the entry is treated as
  `domain: tactical-implementation, owner: tech-lead` at read time and
  no warning is emitted

#### Scenario: Non-default entries carry explicit fields

- **WHEN** the `/write-convention` skill writes an entry for a non-
  `tactical-implementation` domain or a non-`tech-lead` owner
- **THEN** the entry includes both the `domain` and `owner` fields
  explicitly so a subsequent reader does not rely on defaults

### Requirement: Tech Lead is cross-domain registrar and tactical-implementation author

The Tech Lead SHALL retain convention responsibility in four reframed
ways:

- **Author** for conventions whose domain is `tactical-implementation`.
  The existing Convention Authorship procedure in
  `agents/tech-lead.md` is scoped to that domain and remains unchanged
  in substance.
- **Registrar** for the conventions index across all domains. After a
  domain owner drafts and a human reviews a convention, the Tech Lead
  records the entry in the index with domain and owner fields populated.
- **Cross-domain reviewer.** When a draft or an existing convention has
  implications in a second domain, the Tech Lead surfaces the cross-
  domain dependency and routes the consultation to the relevant owner.
- **Gap identifier.** When an inconsistency surfaces (during code
  review, postmortem, or retrospective), the Tech Lead identifies the
  domain the gap belongs in and points at the owner whose Convention
  Authorship subsection should consider a draft.

The Tech Lead MUST NOT author convention drafts in domains other than
`tactical-implementation`. When a user asks the Tech Lead to draft in
another domain, the Tech Lead MUST point at the owner agent and at
`/write-convention --domain=<domain>`.

#### Scenario: Tech Lead authors a tactical-implementation convention

- **WHEN** a user asks the Tech Lead to draft a convention for ID
  generation across modules
- **THEN** the Tech Lead follows its Convention Authorship procedure,
  produces a draft in the conventions directory with
  `domain: tactical-implementation` and `owner: tech-lead`, and marks
  the draft `status: draft` for human review

#### Scenario: Tech Lead redirects a non-tactical authorship request

- **WHEN** a user asks the Tech Lead to draft a convention for CI/CD
  pipeline structure
- **THEN** the Tech Lead names the DevOps Lead as the owner of the
  `infrastructure` domain, suggests
  `/write-convention --domain=infrastructure`, and does NOT produce a
  draft itself

#### Scenario: Tech Lead registers a reviewed draft

- **WHEN** a domain owner has produced a convention draft and a human
  has reviewed and approved it
- **THEN** the Tech Lead updates the conventions index with an entry
  that records the convention name, path, domain, and owner

### Requirement: Each owner agent authors in its declared domain

Every non-Tech-Lead owner agent SHALL contain a Convention Authorship
operating-context subsection. The DevOps Lead, QA Lead, UX Strategist,
and Chief Architect agent definitions MUST each include such a
subsection that:

- Declares the agent's single convention domain (one of
  `infrastructure`, `quality`, `ux`, `architecture`).
- Lists the triggers that surface convention candidates from the
  agent's existing work.
- Documents the drafting procedure: read the project's convention
  template (path in the Tech Lead's memory), research the current
  pattern in the relevant area, draft the convention, note any code or
  process that deviates from the proposed pattern, output the draft
  marked `status: draft`.
- Documents the handoff to the Tech Lead for index registration after
  human review.
- Cross-references `/write-convention --domain=<domain>` as the
  authorship entry point and the README Convention Ownership Matrix.

The owner agent MUST NOT register drafts in the conventions index
itself; registration is the Tech Lead's responsibility.

#### Scenario: DevOps Lead authors an infrastructure convention

- **WHEN** the `/write-convention --domain=infrastructure` skill routes
  to the DevOps Lead's Convention Authorship procedure
- **THEN** the DevOps Lead reads the project's convention template,
  researches the current pipeline or deployment pattern, produces a
  draft with frontmatter `domain: infrastructure` and
  `owner: devops-lead`, and hands off to the Tech Lead for
  registration

#### Scenario: QA Lead authors a quality convention

- **WHEN** the `/write-convention --domain=quality` skill routes to the
  QA Lead's Convention Authorship procedure
- **THEN** the draft is produced with frontmatter `domain: quality` and
  `owner: qa-lead` and handed off to the Tech Lead for registration

#### Scenario: UX Strategist authors a ux convention

- **WHEN** the `/write-convention --domain=ux` skill routes to the UX
  Strategist's Convention Authorship procedure
- **THEN** the draft is produced with frontmatter `domain: ux` and
  `owner: ux-strategist` and handed off to the Tech Lead for
  registration

#### Scenario: Chief Architect authors an architecture convention

- **WHEN** the `/write-convention --domain=architecture` skill routes
  to the Chief Architect's Convention Authorship procedure
- **THEN** the draft is produced with frontmatter
  `domain: architecture` and `owner: chief-architect` and handed off
  to the Tech Lead for registration

### Requirement: `/write-convention` skill with domain routing

A new skill at `skills/write-convention/SKILL.md` SHALL accept an
optional `--domain=<value>` flag or a positional token matching the
five-string vocabulary. When the argument is omitted, the skill MUST
default to `tactical-implementation` owned by `tech-lead`. The skill
MUST validate the domain against the fixed vocabulary and MUST prompt
for a valid value when an unknown domain is supplied.

The skill MUST route the drafting procedure to the owner agent declared
for the domain. The drafting flow MUST:

1. Read the conventions directory path from the Tech Lead's memory.
2. Read the project's convention template if one is recorded in memory.
3. Produce a draft file in the conventions directory with frontmatter
   at minimum: `name`, `domain`, `owner`, `status: draft`.
4. Emit a confirmation summary showing the draft path, domain, owner,
   and a note that the Tech Lead will handle index registration after
   review.

The skill MUST NOT write to or update the conventions index. Index
registration is the Tech Lead's responsibility per the "Tech Lead is
cross-domain registrar" requirement.

When the conventions directory path is not recorded in the Tech Lead's
memory, the skill MUST surface a clear error naming the missing
configuration and pointing the user at the Tech Lead's onboarding path.

#### Scenario: Flag form routes to the declared owner

- **WHEN** the user invokes
  `/write-convention --domain=infrastructure <name>`
- **THEN** the skill routes to the DevOps Lead, produces a draft with
  `domain: infrastructure, owner: devops-lead, status: draft` in
  frontmatter, and writes it to the conventions directory

#### Scenario: Positional form routes to the declared owner

- **WHEN** the user invokes `/write-convention ux <name>`
- **THEN** the skill recognizes `ux` as the domain token, routes to
  the UX Strategist, and produces a draft with
  `domain: ux, owner: ux-strategist, status: draft`

#### Scenario: Omitted domain defaults to tactical-implementation

- **WHEN** the user invokes `/write-convention <name>` with no domain
- **THEN** the skill routes to the Tech Lead and produces a draft with
  `domain: tactical-implementation, owner: tech-lead, status: draft`

#### Scenario: Skill does not update the index

- **WHEN** the skill completes a draft
- **THEN** the conventions index is unchanged; the confirmation
  summary notes that the Tech Lead will register the entry after human
  review

#### Scenario: Missing conventions directory surfaces a clear error

- **WHEN** the skill is invoked in a project whose Tech Lead memory
  has no conventions directory configured
- **THEN** the skill emits a message naming the missing configuration
  and pointing at `/onboard` or the Tech Lead onboarding path, and
  does not write a draft

### Requirement: Conventions index entries carry optional domain and owner fields

The conventions index SHALL support per-entry `domain` and `owner`
metadata. Entries MAY declare these fields using a trailing suffix
shape:

```markdown
- `<convention-name>` — `<path-to-doc>` — `domain: <domain>` — `owner: <agent>`
```

Entries that omit the suffixes MUST be read as `tactical-
implementation` owned by `tech-lead`. The writer (the Tech Lead, via
its registration step) MUST include both fields explicitly for non-
default entries and MAY omit them for default entries to preserve the
legacy row format.

The index format is human-editable; readers MUST tolerate additional
whitespace and MUST accept both `—` and `-` as the separator between
name, path, and suffixes.

#### Scenario: Annotated entry round-trips

- **WHEN** the Tech Lead registers a convention draft with
  `domain: quality` and `owner: qa-lead`
- **THEN** the index entry written includes both `domain: quality` and
  `owner: qa-lead` as suffixes, and re-reading the entry produces the
  same domain and owner values

#### Scenario: Legacy entry reads as default

- **WHEN** the Tech Lead reads an existing index entry with no
  `domain` or `owner` suffix
- **THEN** the entry is resolved as `tactical-implementation` owned by
  `tech-lead` without warning

### Requirement: Convention documents carry frontmatter with domain and owner

Every convention document authored via `/write-convention` SHALL carry
a YAML frontmatter block with at minimum:

- `name`: the convention's canonical name
- `domain`: one of the five declared domains
- `owner`: the declared owner agent for that domain
- `status`: initially `draft`; promoted to `active` only after human
  review, consistent with the existing "drafts until merged" rule

Convention documents without frontmatter MUST be read as
`domain: tactical-implementation` and `owner: tech-lead` at read time,
preserving back-compat with existing conventions. This change does
NOT require a migration pass over existing convention files.

#### Scenario: New draft carries frontmatter

- **WHEN** `/write-convention --domain=architecture <name>` produces a
  draft
- **THEN** the draft file begins with a YAML frontmatter block
  containing `name`, `domain: architecture`, `owner: chief-architect`,
  and `status: draft`

#### Scenario: Legacy document reads as default

- **WHEN** a reader loads a convention document authored before this
  change that has no frontmatter
- **THEN** the document is treated as `domain: tactical-implementation`
  owned by `tech-lead` for routing and index purposes

### Requirement: README documents the Convention Ownership Matrix

The top-level `README.md` SHALL include a "Convention Ownership
Matrix" section that:

- Lists each of the five domains as a row or table entry.
- Names the owner agent for each domain.
- Gives at least one representative example convention per domain.
- Names the authoring slash command for each domain
  (`/write-convention --domain=<domain>`).
- States explicitly that entries without a declared domain or owner
  default to `tactical-implementation` owned by `tech-lead` and that
  existing projects require no migration.
- Cross-references the Tech Lead (for registration and cross-domain
  review) and each owner agent (for authorship in its domain).

Each owner agent's Convention Authorship subsection MUST link to the
README matrix so readers can navigate from the agent definition to the
matrix and back.

#### Scenario: Matrix lists all five domains

- **WHEN** a reader navigates to the "Convention Ownership Matrix"
  section of the top-level `README.md`
- **THEN** the section contains one row or entry per domain
  (`tactical-implementation`, `infrastructure`, `quality`, `ux`,
  `architecture`) naming the owner agent and the authoring slash
  command for each

#### Scenario: README states the back-compat default

- **WHEN** a reader inspects the "Convention Ownership Matrix"
  section
- **THEN** the text states explicitly that entries without declared
  domain or owner default to `tactical-implementation` owned by
  `tech-lead` and that existing projects require no migration

#### Scenario: Agent definitions link back to the matrix

- **WHEN** a reader inspects the Convention Authorship subsection in
  any of the four non-Tech-Lead owner agent definitions
- **THEN** the subsection links to or references the README's
  Convention Ownership Matrix

### Requirement: No changes to unrelated skills

This change MUST NOT modify `skills/write-adr/SKILL.md`,
`skills/write-runbook/SKILL.md`, `skills/plan-implementation/SKILL.md`,
or `skills/refinement-review/SKILL.md`. ADR authorship remains the
Chief Architect's responsibility via `/write-adr`; runbook authorship
remains the DevOps Lead's responsibility via `/write-runbook`. The
Convention Authorship flow is orthogonal to those artifact-specific
skills and does not replace them.

#### Scenario: Adjacent authoring skills are unchanged

- **WHEN** `skills/write-adr/SKILL.md` and
  `skills/write-runbook/SKILL.md` are diffed before and after this
  change
- **THEN** no lines are added, removed, or modified

#### Scenario: Plan-implementation and refinement-review skills are unchanged

- **WHEN** `skills/plan-implementation/SKILL.md` and
  `skills/refinement-review/SKILL.md` are diffed before and after this
  change
- **THEN** no lines are added, removed, or modified
