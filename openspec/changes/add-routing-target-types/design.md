# Design: Routing Target Types

## Context

The Tech Lead's routing model (defined at `agents/tech-lead.md` and specified
by the `tech-lead-routing` capability) treats every registered specialist as
a Claude Code sub-agent. The memory file
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md` stores each
entry as `- \`<agent-name>\` — \`<path-to-agent-file>\``, and the Tech Lead's
Phase 1 output emits each matched entry with a `**Agent:**` anchor that names
a kebab-case slug. The caller (or the `/plan-implementation` skill) dispatches
that slug through the Agent tool.

This model is correct when the right domain expert is a sub-agent. It breaks
down when:

- The right answer is a **skill** that produces an artifact (for example,
  `/write-runbook` for an operational question). A sub-agent invocation is
  the wrong dispatch shape: the user wants the skill's deterministic output,
  not a free-form specialist response.
- The right answer is a **document** (an ADR, convention, or runbook). The
  routing target is a file path, not an agent, and the user's action is to
  read that file before the plan proceeds.
- The right answer is a **human** (security reviewer, compliance officer,
  infrastructure owner). No agent exists or should exist; the plan must
  pause for out-of-band judgment.
- The right answer is an **agent in a different plugin**. The local
  `agents/` directory cannot resolve the slug, but the Agent tool can invoke
  it via a namespaced reference.

Without target-type support, users either hand-edit routing entries into
sub-agent slugs that do not resolve (which produces silent routing failures),
or they document these gates as ad-hoc reminders in the issue body (which
removes them from the structured routing model entirely). The Tech Lead
therefore cannot emit them in Phase 1, and `/plan-implementation` never sees
them.

The `/plan-implementation` skill parses Phase 1 output using the anchors
documented in the `agents/tech-lead.md` "Parseable Phase 1 Output Contract"
subsection: `## Consultation Requests`, `### [Specialist Agent Name]`,
`**Agent:**`, `**Prompt:**`, `## Next Step`. Any new machine-readable signal
must extend that contract without breaking existing parsers.

## Goals / Non-Goals

**Goals:**

- Let users register routing entries for skills, docs, humans, and
  external-plugin agents as first-class routing targets alongside sub-agents.
- Make every consultation request in Phase 1 output self-describing: a reader
  (or a future parser) can tell from one line how to handle the request.
- Preserve full backward compatibility. Existing memory files, existing agent
  definitions, and the existing `/plan-implementation` parser continue to
  work unchanged.
- Document caller-side handling patterns in one place (the README) so the
  Phase 1 output is actionable for both humans and future automation.

**Non-Goals:**

- Target-type dispatch inside `/plan-implementation`. The skill continues to
  spawn only `subagent` and `external-agent` targets in this change;
  non-dispatchable targets are surfaced to the user. Full dispatch logic is a
  follow-up.
- Automatic ticket-system integration for `human` escalation. The notice is
  in-plan only; the user owns the handoff.
- Automatic content extraction for `doc` targets. The user reads the file;
  the plan does not inline content.
- Cross-plugin routing discovery. `external-agent` entries are declared
  explicitly; the Tech Lead does not probe other plugins' routing tables.
- A mandatory target-type declaration on every entry. Omitting the field
  defaults to `subagent` for back-compat.
- Changes to how skills themselves work. This change uses existing skills as
  routing targets; it does not alter the skill execution model.

## Decisions

### D1. Five target types with a `subagent` default

The supported target types are:

- `subagent`: a Claude Code sub-agent in the local `agents/` directory,
  dispatched via the Agent tool with a kebab-case slug. This is the current
  behavior and the default when no target type is declared.
- `skill`: a skill whose invocation produces the answer. Dispatched by the
  caller invoking the named skill with the emitted prompt.
- `doc`: a file path the user should read before the plan proceeds. The
  output cites the path; the plan notes the dependency; no agent or skill is
  invoked.
- `human`: a named person or role whose judgment is required. The plan is
  paused with an explicit escalation notice naming the contact.
- `external-agent`: a sub-agent in another plugin, referenced by a namespaced
  slug (for example, `plugin-x:agent-y`). Dispatched via the Agent tool like
  a local subagent.

**Rationale:** Five types cover the real dispatch patterns that appear in
practice without multiplying categories. `subagent` and `external-agent` are
both Agent-tool targets but differ in resolution (local registry vs. plugin
namespace), so they are kept distinct: a caller that only dispatches local
subagents can ignore `external-agent` entries cleanly. `skill` is separate
from `subagent` because the execution model is different (deterministic
procedure vs. free-form agent). `doc` and `human` are separate because they
are non-dispatchable: the right caller behavior is to cite or escalate, not
to invoke.

**Alternatives considered:** Collapse `subagent` and `external-agent` into
one `agent` type with a namespaced slug. Rejected: the resolution semantics
differ (local file vs. plugin-scoped), and the audit skill needs to tell the
two apart to flag broken local pointers. Also considered: add a `tool` type
for invoking arbitrary Bash or MCP tools. Rejected: routing to a tool call
as a "specialist" overloads the metaphor and invites a far larger surface
area than this change should introduce.

### D2. Target type is an optional per-entry field; default is `subagent`

The routing memory file format is extended so that a registered entry MAY
declare a target type after the existing agent-name and path tokens. The
absence of the field is equivalent to declaring `subagent`.

Proposed entry syntax (the exact writing format is a `/add-specialist` concern
and MAY evolve, but the semantic model is fixed):

```markdown
- `<name>` — `<path-or-slug>` — `target-type: <type>`
```

For entries whose target type is `subagent`, the suffix MAY be omitted so
existing entries continue to round-trip cleanly. The audit skill treats an
omitted suffix as `subagent` and does not flag it.

For entries whose target type is `doc`, the `<path-or-slug>` token holds the
file path. For `skill`, it holds the skill slug. For `human`, it holds the
contact identifier (name, role, or email). For `external-agent`, it holds
the namespaced agent slug.

**Rationale:** Making the field optional with a `subagent` default is the
only option that preserves backward compatibility without a migration pass.
Putting the type in a trailing `key: value` suffix rather than reformatting
the entry into a table keeps the memory file human-editable.

**Alternatives considered:** Rewrite the memory file into a table with a
`Target Type` column. Rejected: forces a migration for every existing
project and loses the lightness of the current list format. Also considered:
store target type in a separate section. Rejected: puts the type far from
the entry it describes and invites drift.

### D3. Phase 1 output gains a `**Target Type:**` anchor per request

Each `### <Name>` subsection under `## Consultation Requests` gains a
`**Target Type:**` line on the line immediately after the heading. The value
is one of the five strings from D1. Downstream anchors are shaped per type:

- `subagent` and `external-agent`: retain `**Agent:**` with the agent slug
  (local kebab-case for `subagent`; namespaced for `external-agent`). The
  existing `**Prompt:**` anchor is retained.
- `skill`: `**Skill:**` with the skill slug. `**Prompt:**` is retained as
  the input the skill should receive.
- `doc`: `**Doc:**` with the file path. `**Prompt:**` is retained as the
  "what to look for when reading" note.
- `human`: `**Contact:**` with the person or role. `**Prompt:**` is retained
  as the question to ask.

The `## Next Step` heading continues to mark the end of the consultation-
requests block, so the existing parser's stop anchor is unchanged.

**Rationale:** Adding a single `**Target Type:**` anchor on every request
gives parsers a single key to branch on. Preserving `**Prompt:**` across all
five types keeps the most semantically rich field in the same shape, which
minimizes parser churn. Retaining `**Agent:**` for both Agent-tool targets
and introducing distinct anchors (`**Skill:**`, `**Doc:**`, `**Contact:**`)
for the other three types makes each request self-describing when read
without the `**Target Type:**` line.

**Alternatives considered:** Keep `**Agent:**` as the universal anchor and
shove any non-agent target into it. Rejected: the anchor name misrepresents
the payload and makes the parser's job harder. Also considered: emit a YAML
frontmatter block at the top of Phase 1 listing all target types. Rejected:
the Tech Lead's output is already structured markdown; frontmatter just for
target types is inconsistent with the existing shape.

### D4. `/add-specialist` gains an explicit target-type input

The skill is extended to accept a target-type argument. Two forms are
supported:

- A `--target-type=<type>` flag, which is unambiguous regardless of argument
  order.
- A second positional token shaped like `subagent`, `skill`, `doc`, `human`,
  or `external-agent` immediately after the name, before any override
  arguments. The skill distinguishes this from an override by matching the
  token against the fixed type vocabulary.

When no target type is provided, the skill writes a `subagent` entry in the
legacy row format (no trailing type suffix), preserving back-compat.

When a non-subagent target type is provided, the skill validates the
second-position value (the path, slug, or contact) per type:

- `skill`: check the token is a recognizable skill slug. Warn if no matching
  `skills/<slug>/SKILL.md` exists locally (external plugin skills may not be
  present).
- `doc`: check the path exists with Glob. Warn if not.
- `human`: no format check; accept any string.
- `external-agent`: check the slug contains a namespace separator (`:`) and
  warn otherwise.

Validation failures are warnings, not errors. The user can proceed after an
explicit confirmation (mirroring the existing duplicate and redundancy
warnings in the skill).

**Rationale:** Both the flag and the positional form are ergonomic, and the
positional form is consistent with the skill's existing argument style
(agent name first, then overrides). Validation-as-warning matches the
skill's current treatment of duplicates and redundant overrides. Hard errors
would force the user to hand-edit memory when a file is temporarily missing
or a contact is not yet finalized.

**Alternatives considered:** Require a flag only. Rejected: positional args
are the current style. Also considered: hard-fail on validation. Rejected:
see above.

### D5. Caller-side handling patterns live in the README

The top-level `README.md` gains a section documenting how each target type
should be dispatched:

- `subagent`: spawn via the Agent tool with the slug from `**Agent:**`.
- `skill`: invoke the skill named in `**Skill:**` with the emitted prompt.
  The caller captures the skill's output and feeds it back to Phase 2 like
  any specialist response.
- `doc`: cite the path in the plan's dependencies. The plan notes "Read
  `<path>` before starting." No Phase 2 feedback loop.
- `human`: pause the plan with an explicit escalation notice that names the
  contact and quotes the prompt as the question being asked. No Phase 2
  feedback loop in the automated flow; the user owns the handoff.
- `external-agent`: spawn via the Agent tool with the namespaced slug. Same
  Phase 2 feedback loop as `subagent`.

The README section cross-references the Tech Lead example and the
`/add-specialist` example so readers find the handling guidance from both
entry points.

**Rationale:** A single source of truth for dispatch semantics avoids drift
between the agent definition, the skill, and the spec. The README is where
users look first; the other documents reference it.

**Alternatives considered:** Inline the handling patterns in the agent
definition. Rejected: duplicates content and creates drift risk. Also
considered: put them in the capability spec. Rejected: the spec documents
the contract, not the caller's dispatch choice; the spec references the
README for the per-type handling patterns.

### D6. `/plan-implementation` is not modified in this change

The skill continues to parse the existing anchors and continues to spawn
only `subagent` (and, by extension, `external-agent`, since the Agent tool
accepts namespaced slugs when the plugin is installed) targets in Phase 1.
When a consultation request declares a non-dispatchable target type
(`skill`, `doc`, or `human`), the current skill surfaces the request to the
user rather than silently dropping it.

The new `**Target Type:**` line is an additive anchor that MAY be ignored
by current parsers. Because the skill's existing parser matches on
`**Agent:**` specifically, requests for `skill`, `doc`, and `human` targets
(which do not carry `**Agent:**`) are naturally excluded from the spawn
pass. The skill's "surface unspawnable requests" behavior is a
documentation update, not a code change.

Full target-type-aware dispatch in the skill is deferred to a follow-up
change so this change can ship the model and observe usage before
automating the dispatch logic.

**Rationale:** Scope discipline. Bundling skill changes here doubles the
surface area and risks a coupled revert if the target-type vocabulary needs
adjustment after early usage.

**Alternatives considered:** Add target-type dispatch to
`/plan-implementation` in this change. Rejected: see above. Also considered:
forbid non-dispatchable target types until the skill supports them.
Rejected: that defers the feature entirely, and the readability benefit of
documented non-dispatchable gates (doc and human) is itself valuable even
without automation.

## Risks / Trade-offs

- **Phase 1 output readability.** Adding a `**Target Type:**` line per
  request lengthens the output. Mitigation: the added line is one short
  string on its own line, positioned where human readers expect metadata
  (immediately after the subsection heading). Readers can still scan by
  heading alone.
- **Back-compat drift if the default changes.** Future work might want a
  different default than `subagent`. Mitigation: the default is documented
  as an explicit decision. Changing it would be a follow-up change with its
  own spec.
- **Misregistration of target type.** A user might register a `doc` entry
  whose path is stale, or a `skill` entry whose skill does not exist.
  Mitigation: `/add-specialist` validates per type and warns at registration
  time. `/audit-routing-table` already surfaces broken pointers and can be
  extended in a later change to check target-type-specific validity.
- **Non-dispatchable requests feel inert.** A `doc` or `human` request with
  no automated follow-up may be ignored by callers under time pressure.
  Mitigation: the README documents the caller-side pause semantics
  explicitly; the Tech Lead's own output surfaces the target type in a way
  that is hard to miss (one line per request).
- **Parser surprise.** A parser that naively looks for `**Agent:**` on every
  consultation request will treat non-subagent requests as malformed.
  Mitigation: the existing `/plan-implementation` parser matches on the
  full anchor set (`### <Name>`, `**Agent:**`, `**Prompt:**`) and treats
  entries lacking `**Agent:**` as non-spawnable today; this change extends
  that tolerance into a documented handling pattern rather than inventing
  new parser behavior.
- **External-agent slug resolution fails silently.** A namespaced slug for a
  plugin that is not installed produces a runtime error at dispatch time,
  not at registration time. Mitigation: `/add-specialist` warns if the slug
  lacks a namespace separator; full install-state checks are out of scope.

## Migration Plan

No migration required. The change is additive.

- Existing `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`
  files continue to parse. Entries without a target-type suffix default to
  `subagent` at routing time.
- Existing `agents/tech-lead.md` memory sections (Registered Specialists,
  Project Code Area Overrides, conventions index) are unaffected.
- Existing `/plan-implementation` parsers ignore the new `**Target Type:**`
  line and continue to match `**Agent:**` / `**Prompt:**` / `## Next Step`.
- Rollback: revert the agent-definition edits, revert the
  `/add-specialist` skill changes, remove the new README section, and
  remove the capability spec. Existing `subagent` entries continue to route
  correctly after the revert because they never relied on the new anchors.

## Open Questions

- Should `human` entries carry a severity indicator (for example,
  `blocker` vs `advisory`) so the plan can differentiate a security review
  that must happen from a courtesy ping? Deferred: one use case at a time;
  revisit if projects actually request the distinction.
- Should `doc` entries support a "stale-after" date so the audit skill can
  flag expired references? Deferred to a follow-up audit-focused change.
- Should `skill` entries support arguments inline (for example,
  `/write-runbook incident-response`) rather than relying on the Tech Lead's
  prompt to carry the arguments? Deferred: inline arguments invite a
  parsing surface that duplicates the skill's own argument handling.
  Current approach is to put arguments in the prompt.
- Should `external-agent` entries be discoverable via an installed-plugin
  probe so users can see the available namespaced slugs? Deferred: explicit
  declaration is simpler and consistent with the current registration flow.
