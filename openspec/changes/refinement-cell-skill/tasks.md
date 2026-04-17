# Tasks

## 1. Scaffold the skill

- [ ] 1.1 Create `skills/refinement-review/` directory with a `SKILL.md` file
- [ ] 1.2 Populate `SKILL.md` frontmatter: `name: refinement-review`,
      `user-invokable: true`, `context: fork`, `allowed-tools: Read, Grep,
      Glob, Agent`, and an `argument-hint` documenting the three input forms
- [ ] 1.3 Write the skill description summarizing the parallel PO / Architect
      / UX consultation and the readiness verdict output

## 2. Implement input resolution

- [ ] 2.1 Adapt the input-resolution procedure from
      `skills/plan-implementation/SKILL.md` (Step 1) to handle inline,
      file-path, and issue-reference inputs
- [ ] 2.2 Handle the empty-argument case by prompting for input and halting
      until input is provided
- [ ] 2.3 Handle unresolvable issue references by surfacing an
      `[INPUT ERROR]` notice and prompting for pasted content

## 3. Implement peer fan-out

- [ ] 3.1 Define role-specific prompt templates inside the skill file for
      `product-owner`, `chief-architect`, and `ux-strategist`
- [ ] 3.2 Ensure each prompt asks the peer to end its response with
      `Verdict: ready` / `needs-revision` / `blocked`
- [ ] 3.3 Document that the three Agent invocations must be issued in a
      single assistant turn (parallel fan-out)

## 4. Implement response collection and verdict aggregation

- [ ] 4.1 Parse each peer response for its `Verdict:` line
- [ ] 4.2 Implement verdict aggregation per the spec: unanimous `ready`
      promotes to `ready`; any `blocked` promotes to `blocked`; mixed
      non-blocked with at least one `needs-revision` promotes to
      `needs-revision`
- [ ] 4.3 Handle empty / errored / unparseable peer responses by downgrading
      the overall verdict to at least `needs-revision` and naming the peer

## 5. Implement consolidated report rendering

- [ ] 5.1 Emit the overall verdict line and named peer accountability at the
      top of the report
- [ ] 5.2 Render per-peer sections in the fixed order `product-owner`,
      `chief-architect`, `ux-strategist` with verbatim peer output
- [ ] 5.3 Include "no concerns raised" markers where appropriate and
      "invocation failed" markers for missing peers
- [ ] 5.4 Include an `## Objections` section listing any peer objections
      verbatim; omit when all peers returned clean `ready`
- [ ] 5.5 Include a trailing `## Next Steps` section with a one- to
      three-line recommendation matching the verdict

## 6. Update agent definitions

- [ ] 6.1 Add a short "Collaboration" or equivalent body note to
      `agents/product-owner.md` documenting refinement-cell membership and
      pointing at `/refinement-review`
- [ ] 6.2 Same update to `agents/chief-architect.md`
- [ ] 6.3 Same update to `agents/ux-strategist.md`
- [ ] 6.4 Verify no frontmatter fields changed in the three agent files

## 7. Update README

- [ ] 7.1 Add a section to the top-level `README.md` naming
      `/refinement-review`, `refine-story`, `/write-story`, and
      `/plan-implementation` with a when-to-use-each summary
- [ ] 7.2 Note that trivial stories may legitimately skip the ceremony to
      save tokens

## 8. Manual verification

- [ ] 8.1 Run `/refinement-review` with an inline story draft and confirm
      three parallel Agent calls occur and a well-formed report is produced
- [ ] 8.2 Run `/refinement-review` with a file-path input and confirm the
      file is read and used
- [ ] 8.3 Run `/refinement-review` with an issue reference (if an issue
      tracker CLI is available) and confirm the reference is resolved
- [ ] 8.4 Run `/refinement-review` with no argument and confirm the skill
      prompts for input without invoking any peer
- [ ] 8.5 Simulate a peer invocation failure and confirm the overall verdict
      downgrades correctly and the failed peer is named
