# Tasks

## 1. Author the `convention-domain-ownership` capability spec

- [ ] 1.1 Create `openspec/specs/convention-domain-ownership/spec.md` with
      the Purpose, Invariants, Acceptance Criteria, and Requirements
      sections following the existing capability-spec template
- [ ] 1.2 Document the five-domain vocabulary (`tactical-implementation`,
      `infrastructure`, `quality`, `ux`, `architecture`) and the single-
      owner mapping in Requirements
- [ ] 1.3 Document the `tactical-implementation` and `tech-lead` defaults
      for entries and documents that omit domain or owner fields, and the
      back-compat round-trip guarantee for legacy index entries
- [ ] 1.4 Document the Tech Lead's reframed role: cross-domain registrar,
      tactical-implementation author, cross-domain reviewer, gap
      identifier; explicitly scope Convention Authorship to the
      `tactical-implementation` domain
- [ ] 1.5 Document each owner agent's Convention Authorship responsibility
      (DevOps Lead → `infrastructure`, QA Lead → `quality`, UX Strategist →
      `ux`, Chief Architect → `architecture`) and the handoff to the Tech
      Lead for index registration
- [ ] 1.6 Document the conventions-index entry format extension (optional
      `domain` and `owner` fields) and the convention-document frontmatter
      schema (`name`, `domain`, `owner`, `status`)
- [ ] 1.7 Document the `/write-convention` skill contract (accepts
      `--domain=<domain>` flag or positional token; validates against the
      five-string vocabulary; defaults to `tactical-implementation`; writes
      a draft to the conventions directory; does not register in the
      index)
- [ ] 1.8 Document the README Convention Ownership Matrix requirement
      (lists each domain, owner agent, example conventions, and authoring
      slash command; cross-referenced from each owner agent)

## 2. Update the Tech Lead agent definition

- [ ] 2.1 Update the agent description at `agents/tech-lead.md` so the
      phrase "convention owner across modules" is reframed as "cross-
      domain convention registrar and tactical-implementation convention
      author"
- [ ] 2.2 Update the Operating Contexts section so "You are the convention
      owner" is reframed: the Tech Lead is the registrar for all domains
      and the author for the `tactical-implementation` domain
- [ ] 2.3 Update the Convention Authorship subsection to scope its
      authorship procedure to the `tactical-implementation` domain,
      including a pointer to `/write-convention --domain=<domain>` for
      conventions in other domains
- [ ] 2.4 Retain the Convention-Review, Quick Consultation, and Convention
      Gap Identification subsections as cross-domain responsibilities; add
      a note that each references the per-domain owner when the domain is
      not `tactical-implementation`
- [ ] 2.5 Update the Memory Schema description (Conventions Directory and
      Conventions Index) to note that index entries MAY carry domain and
      owner fields and that the read-time default for unannotated entries
      is `tactical-implementation` owned by `tech-lead`
- [ ] 2.6 Add a cross-reference from the Tech Lead definition to the
      README's Convention Ownership Matrix

## 3. Update the DevOps Lead agent definition

- [ ] 3.1 Add a Convention Authorship operating-context subsection to
      `agents/devops-lead.md` declaring `infrastructure` as the DevOps
      Lead's convention domain
- [ ] 3.2 Document the triggers that surface convention candidates in the
      infrastructure domain (pipeline-shape reviews, runbook authorship
      reviews, postmortem doctrine gaps)
- [ ] 3.3 Document the drafting procedure: read the project's convention
      template, research the current pipeline/deployment/runbook pattern,
      draft, note deviations, output for review
- [ ] 3.4 Document the handoff to the Tech Lead for index registration
      after review
- [ ] 3.5 Cross-reference `/write-convention --domain=infrastructure` as
      the authorship entry point and the README Ownership Matrix

## 4. Update the QA Lead agent definition

- [ ] 4.1 Add a Convention Authorship operating-context subsection to
      `agents/qa-lead.md` declaring `quality` as the QA Lead's convention
      domain
- [ ] 4.2 Document the triggers that surface convention candidates in the
      quality domain (test strategy reviews, brittleness assessments,
      coverage gap analyses)
- [ ] 4.3 Document the drafting procedure using the shared template shape
      (read template, research pattern, draft, note deviations, output for
      review)
- [ ] 4.4 Document the handoff to the Tech Lead for index registration
- [ ] 4.5 Cross-reference `/write-convention --domain=quality` and the
      README Ownership Matrix

## 5. Update the UX Strategist agent definition

- [ ] 5.1 Add a Convention Authorship operating-context subsection to
      `agents/ux-strategist.md` declaring `ux` as the UX Strategist's
      convention domain
- [ ] 5.2 Document the triggers that surface convention candidates in the
      UX domain (behavioral consistency checks, error-message voice
      reviews, interaction-primitive audits, accessibility baselines)
- [ ] 5.3 Document the drafting procedure using the shared template shape
- [ ] 5.4 Document the handoff to the Tech Lead for index registration
- [ ] 5.5 Cross-reference `/write-convention --domain=ux` and the README
      Ownership Matrix

## 6. Update the Chief Architect agent definition

- [ ] 6.1 Add a Convention Authorship operating-context subsection to
      `agents/chief-architect.md` declaring `architecture` as the Chief
      Architect's convention domain
- [ ] 6.2 Document the triggers that surface convention candidates in the
      architecture domain (ADR format evolution, decision-record
      structure, one-way-door signal patterns)
- [ ] 6.3 Document the relationship between `/write-adr` (an ADR is an
      artifact) and a convention draft (a pattern that spans multiple
      ADRs or decisions); note that this change does not rebrand
      `/write-adr` as a convention-authoring skill
- [ ] 6.4 Document the drafting procedure using the shared template shape
- [ ] 6.5 Document the handoff to the Tech Lead for index registration
- [ ] 6.6 Cross-reference `/write-convention --domain=architecture` and
      the README Ownership Matrix

## 7. Author the `/write-convention` skill

- [ ] 7.1 Create `skills/write-convention/SKILL.md` with the standard
      frontmatter (name, description, context handling)
- [ ] 7.2 Document the argument parsing: a `--domain=<value>` flag OR a
      positional token matching the five-string vocabulary; an unknown
      domain is surfaced with a list of valid values and the skill prompts
      for a valid domain
- [ ] 7.3 Document the owner-agent routing (fixed mapping from domain to
      agent) and the routing behavior when the `--domain` argument is
      omitted (default to `tactical-implementation`, owner `tech-lead`)
- [ ] 7.4 Document the drafting flow: read the conventions directory path
      from the Tech Lead's memory; read the project's convention template
      if one exists; produce a draft with frontmatter (`name`, `domain`,
      `owner`, `status: draft`)
- [ ] 7.5 Document the output: the draft is written to the conventions
      directory with a predictable filename; the index is NOT updated by
      the skill (registration is the Tech Lead's responsibility after
      review)
- [ ] 7.6 Document the validation step: if the conventions directory does
      not exist in the Tech Lead's memory, the skill surfaces a clear
      error with a pointer to `/onboard` or to the Tech Lead's
      onboarding path
- [ ] 7.7 Document the confirmation summary emitted at the end of the
      skill (shows the draft path, the domain, the owner, and the
      registration handoff note)

## 8. Author the README Convention Ownership Matrix

- [ ] 8.1 Add a "Convention Ownership Matrix" section to the top-level
      `README.md` with a table row per domain listing the domain, owner
      agent, representative example conventions in that domain, and the
      authoring slash command (`/write-convention --domain=<domain>`)
- [ ] 8.2 State explicitly that entries without a declared domain or
      owner default to `tactical-implementation` and `tech-lead`
      respectively, and that existing projects require no migration
- [ ] 8.3 Cross-reference the Tech Lead example (for registration and
      cross-domain review) and each owner-agent example (for authorship
      in its domain)
- [ ] 8.4 Link to the relevant operating-context subsection in each agent
      definition so readers can jump to the drafting procedure

## 9. Validate back-compat and internal consistency

- [ ] 9.1 Confirm that `skills/write-adr/SKILL.md` is not modified by
      this change (ADR authorship remains the Chief Architect's
      responsibility under `/write-adr`)
- [ ] 9.2 Confirm that `skills/write-runbook/SKILL.md` is not modified by
      this change (runbook authorship remains the DevOps Lead's
      responsibility under `/write-runbook`)
- [ ] 9.3 Confirm that `skills/plan-implementation/SKILL.md` and
      `skills/refinement-review/SKILL.md` are not modified by this
      change
- [ ] 9.4 Re-read the Tech Lead's memory schema and confirm the
      Conventions Directory and Conventions Index descriptions are
      consistent with the new optional fields and the read-time default
- [ ] 9.5 Re-read each owner agent's new Convention Authorship subsection
      and confirm the drafting procedure, handoff language, and cross-
      references match the shared shape
- [ ] 9.6 Re-read the README Ownership Matrix and confirm each row's
      owner agent matches the corresponding agent's declared domain

## 10. Manual verification

- [ ] 10.1 Invoke `/write-convention --domain=infrastructure <name>` and
      confirm the skill routes to the DevOps Lead's drafting procedure,
      produces a draft with `domain: infrastructure` and
      `owner: devops-lead` in frontmatter, and writes to the conventions
      directory without updating the index
- [ ] 10.2 Invoke `/write-convention --domain=quality <name>` and confirm
      the same behavior with `owner: qa-lead`
- [ ] 10.3 Invoke `/write-convention --domain=ux <name>` and confirm the
      same behavior with `owner: ux-strategist`
- [ ] 10.4 Invoke `/write-convention --domain=architecture <name>` and
      confirm the same behavior with `owner: chief-architect`
- [ ] 10.5 Invoke `/write-convention <name>` without a `--domain`
      argument and confirm the skill defaults to
      `domain: tactical-implementation` and `owner: tech-lead`
- [ ] 10.6 Invoke `/write-convention --domain=garbage <name>` and confirm
      the skill warns with a list of valid values and prompts for a
      valid domain rather than producing a draft with an invalid domain
- [ ] 10.7 Consult the Tech Lead for a Quick Consultation ("what's the
      convention for runbook format") and confirm the Tech Lead
      references the DevOps Lead as the owner rather than drafting
      itself
- [ ] 10.8 Register a legacy index entry (no domain or owner suffix) and
      confirm the Tech Lead reads it as
      `domain: tactical-implementation` owned by `tech-lead`
