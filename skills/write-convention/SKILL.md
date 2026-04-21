---
name: write-convention
description: >
  Route convention authorship to the declared domain owner. Accepts an optional
  --domain=<value> flag or positional domain token. Valid domains:
  tactical-implementation, infrastructure, quality, ux, architecture. Defaults
  to tactical-implementation when omitted. Use when authoring a new convention
  for any domain.
user-invokable: true
allowed-tools: Read, Glob, Grep, Write
argument-hint: "[--domain=<domain>] <convention-name>"
context: fork
---

# Write Convention

Route convention authorship to the declared domain owner for the convention
described in `$ARGUMENTS`.

## Step 1 — Parse Arguments

Extract two pieces of information from `$ARGUMENTS`:

1. **Domain** — accept either:
   - Flag form: `--domain=<value>` anywhere in the argument string.
   - Positional form: a bare word appearing before the convention name that
     exactly matches one of the five valid domain strings
     (`tactical-implementation`, `infrastructure`, `quality`, `ux`,
     `architecture`).
   - If neither form is present, default to `tactical-implementation`.

2. **Convention name** — everything in `$ARGUMENTS` that is not the domain
   flag or the positional domain token.

If `$ARGUMENTS` is empty (no convention name), ask the user to provide a
convention name before proceeding.

## Step 2 — Validate Domain

Check the extracted domain against the fixed vocabulary:

- `tactical-implementation`
- `infrastructure`
- `quality`
- `ux`
- `architecture`

If the value is not one of these five strings, emit the following message:

> `"<value>"` is not a recognized convention domain. Valid domains are:
> `tactical-implementation`, `infrastructure`, `quality`, `ux`, `architecture`.
>
> Which domain should this convention belong to?

Prompt the user for a valid domain. Do not proceed until a valid domain is
supplied.

## Step 3 — Resolve Owner Agent

Map the validated domain to its owner agent:

| Domain | Owner Agent |
|---|---|
| `tactical-implementation` | `tech-lead` |
| `infrastructure` | `devops-lead` |
| `quality` | `qa-lead` |
| `ux` | `ux-strategist` |
| `architecture` | `chief-architect` |

## Step 4 — Read Conventions Directory Path

Read the Tech Lead's memory at
`.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`.

Look for a `Conventions Directory` path (typically listed under a
`## Conventions Directory` section or `## Project File References` section).

If no conventions directory path is configured, emit the following error and
stop:

> The conventions directory path is not configured in the Tech Lead's project
> memory. Run `/onboard` to configure it, or add a `## Conventions Directory`
> entry to
> `.claude/agent-memory/engineering-leaders-tech-lead/MEMORY.md`
> with the path where conventions are stored before running this skill again.

## Step 5 — Read Convention Template

If the Tech Lead's memory records a convention template path, read that file
to establish the project's heading structure.

If no template is recorded, use this minimal default structure:

```markdown
---
name: <convention-name>
domain: <domain>
owner: <agent>
status: draft
---

# <Convention Name>

## Context

[What situation or inconsistency prompted this convention?]

## Convention

[The pattern or rule being established.]

## Examples

[One or more concrete examples showing correct usage.]

## Deviations

[Known existing code or processes that deviate from this convention.
List them so the team can track alignment over time.]
```

## Step 6 — Delegate Drafting to the Owner Agent

Emit a consultation request for the resolved owner agent with the following
prompt:

> You are being asked to draft a convention for the `<domain>` domain.
>
> **Convention name:** `<convention-name>`
> **Domain:** `<domain>`
> **Owner:** `<agent>`
>
> Using the convention template structure below, produce a complete draft
> convention document. Before drafting:
>
> 1. Research the current pattern in the codebase related to this convention
>    name to understand what already exists and what variations are present.
> 2. Draft the convention following the template structure.
> 3. Note any existing code, configuration, or process that deviates from the
>    proposed convention.
>
> The draft frontmatter MUST include exactly these fields:
>
> ```yaml
> ---
> name: <convention-name>
> domain: <domain>
> owner: <agent>
> status: draft
> ---
> ```
>
> Do not mark the convention as "active." It will remain `status: draft` until
> the team reviews and approves it.
>
> Template structure to follow:
>
> [paste the template content from Step 5]

Note: the consultation request pattern (rather than a direct Agent-tool spawn)
is consistent with the existing routing infrastructure. A direct-spawn path is
a deliberate follow-up if usage warrants it (see the "Open Questions" section
of `openspec/changes/add-convention-domain-ownership/design.md`).

## Step 7 — Write the Draft

Write the owner agent's output to the conventions directory as a file named
`<convention-name>.md` (convention name converted to kebab-case).

Do not write to or update the conventions index. Index registration is the
Tech Lead's responsibility after the draft is reviewed and approved.

## Step 8 — Confirmation Summary

Emit a confirmation summary:

> **Convention draft created**
>
> - **File:** `<conventions-directory>/<convention-name>.md`
> - **Domain:** `<domain>`
> - **Owner:** `<agent>`
> - **Status:** `draft`
>
> The draft is ready for review. Once you and the team have reviewed and
> approved it, ask the Tech Lead to register it in the conventions index with
> the `domain` and `owner` fields populated.
>
> See the [Convention Ownership Matrix](../../README.md#convention-ownership-matrix)
> for the full domain-to-owner mapping.
