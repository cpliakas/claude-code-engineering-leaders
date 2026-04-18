---
name: facilitate-retrospective
description: "Facilitate a structured retrospective from a sprint or body-of-work description. Follows the Derby-Larsen five-phase framework with blameless framing and SMART action items."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob
argument-hint: "[description of the sprint, milestone, or body of work to retrospect]"
---

# Facilitate Retrospective

Facilitate a structured retrospective that helps a team introspect a body of work and identify concrete improvements. The output follows the Derby-Larsen five-phase retrospective framework (Set the Stage, Gather Data, Generate Insights, Decide What to Do, Close the Retrospective) adapted for AI-assisted analysis.

## Input

`$ARGUMENTS` = description of the body of work to retrospect — sprint number and team name, milestone description, date range, or a narrative summary of what was delivered and what happened.

## Process

### 1. Handle Missing Input

If `$ARGUMENTS` is empty or contains no actionable description, prompt the team lead for the minimum information needed to begin. Present these questions in a single consolidated prompt:

- **What work are we retrospecting?** — Sprint number, milestone name, or date range.
- **Who is the team?** — Team name or composition (helps frame observations).
- **What was delivered?** — Key deliverables, features shipped, or goals targeted.
- **What notable events occurred?** — Incidents, blockers, surprises, scope changes, staffing changes, or process experiments.

Do not proceed until at least a work scope and one or more notable events or deliverables are provided.

### 2. Gather Context

- Read the project's CLAUDE.md for architecture, domain language, and team conventions
- Scan for a roadmap or backlog file if one exists (Glob for roadmap*, backlog*, TODO*)
- Check project memory for recent work completions, decisions, and open questions logged by the `product-owner` agent
- Check the Agile Coach's project memory
  (`.claude/agent-memory/engineering-leaders-agile-coach/MEMORY.md`) for a
  configured `retrospective_directory` path
- If a directory is configured, read prior retrospective artifacts in that
  directory to identify patterns and recurring themes

### 3. Set the Stage

Establish the retrospective's scope and framing:

- **Scope statement**: What period or body of work is being reviewed (sprint dates, milestone name, or work description)
- **Prime Directive**: Frame the retrospective under the Retrospective Prime Directive — "Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand." This is not decorative; it is a structural constraint on the language used throughout the document.
- **Blamelessness constraint**: All observations, insights, and action items throughout the document must be framed in terms of systems and processes. No language may attribute outcomes to individual people.

### 4. Gather Specialist Input

Gather specialist input using the Tech Lead's two-phase consultation protocol.

**Phase 1 — Get consultation requests:** Invoke the `tech-lead` agent with the
work summary from Step 3. Ask it to identify which specialists should contribute
observations about the retrospected body of work.

The Tech Lead will return a structured set of **consultation requests**: one per
matched specialist, each containing an agent name and a focused prompt.

**Execute consultations:** For each consultation request the Tech Lead returned,
spawn the specified specialist agent with the provided prompt. Run independent
consultations in parallel.

**Phase 2 — Synthesize:** Invoke the `tech-lead` agent again, passing the
original work summary plus the verbatim specialist responses. The Tech Lead will
synthesize the specialist input into domain-specific observations, convention
adherence trends, and emerging patterns.

Incorporate the synthesized specialist observations into Step 5 alongside other
data sources. If the Tech Lead has no registered specialists for this project,
the Tech Lead will produce output directly without consultation requests: skip
the execute and Phase 2 steps and use its output as-is.

### 5. Gather Data

Collect and organize observations about what happened during the retrospected period. Draw from:

- The input description provided by the team lead
- Specialist input gathered via the Tech Lead in Step 4
- Project memory (work completions, decisions, surprises logged by `product-owner`)
- Codebase signals (commit patterns, file churn, test coverage changes — if available and relevant)
- Any context the team lead provided about events, blockers, or scope changes

Organize observations into themes. Common theme categories include (use whichever are relevant, not all):

- **Delivery and throughput** — what shipped, what didn't, velocity patterns
- **Quality** — bugs, rework, test gaps, incidents
- **Process and workflow** — ceremonies, handoffs, tooling, communication patterns
- **Scope and planning** — estimation accuracy, scope creep, dependency surprises
- **Team dynamics** — collaboration patterns, knowledge silos, onboarding

For each observation, note whether it is something the team should **continue doing** (a strength), **stop doing** (a drag), or **start doing** (an opportunity).

### 6. Generate Insights

Analyze the observations from Step 5 to identify systemic factors and underlying patterns. Move beyond surface-level symptoms:

- **Why** did things go well? What systemic conditions enabled the wins?
- **Why** did things go poorly? What process, tooling, or structural factors contributed?
- Use the "5 Whys" technique when a surface observation masks a deeper systemic issue
- Look for connections between themes — e.g., scope creep causing quality issues, or communication gaps causing rework

Each insight must name the systemic factor, not an individual. Frame as: "The [process/system/practice] caused [outcome] because [mechanism]."

### 7. Decide What to Do

Propose 1-3 concrete improvement actions based on the insights from Step 6. Each action item must satisfy all five SMART criteria:

| Criterion | Requirement |
|-----------|-------------|
| **Specific** | Names the exact change — what will be different |
| **Measurable** | Defines how success will be observed or measured |
| **Achievable** | Is within the team's control to implement (enforced by quality gates below, not a separate output field) |
| **Relevant** | Directly addresses a systemic factor identified in Step 6 |
| **Time-bound** | States when the action will be completed or reviewed |

**Quality gates:**

- Maximum 3 action items. Teams that commit to more than 3 improvements rarely complete any. If more than 3 candidates emerge, prioritize by impact and achievability.
- No vague formulations. "Improve communication" is not an action item. "Hold a 15-minute daily sync focused on cross-team blockers, starting next sprint, and review effectiveness at the next retrospective" is.
- Each action item must trace back to a specific insight from Step 6.

### 8. Close the Retrospective

Summarize the retrospective and capture appreciation:

- **Wins to celebrate**: 2-4 specific accomplishments, strengths, or positive patterns worth acknowledging. Celebrating what went well reinforces the behaviors the team should continue.
- **Summary**: A 2-3 sentence narrative capturing the retrospective's key finding and the team's improvement commitment.

### 9. Produce Structured Output

Format the output using the Output section below.

## Output

```markdown
## Scope Reviewed

**Period**: [Sprint N / dates / milestone name]
**Team**: [Team name or composition]
**Prime Directive**: Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand.

## Key Observations

### [Theme 1 Name]

- **Continue**: [Observation — what the team did well in this area]
- **Stop**: [Observation — what is dragging the team down]
- **Start**: [Observation — an opportunity the team hasn't tried yet]

### [Theme 2 Name]

- **Continue**: [Observation]
- **Start**: [Observation]

[Additional themes as needed. Not every theme needs all three categories.]

## Insights

1. **[Insight title]** — [Explanation of the systemic factor, its mechanism, and its impact. References specific observations from the Key Observations section.]

2. **[Insight title]** — [Explanation]

[2-5 insights, each tracing back to observations above.]

## SMART Action Items

1. **[Action title]**
   - **What**: [Specific change to implement]
   - **Measure**: [How success will be observed]
   - **Owner**: [Role or function responsible — never an individual name]
   - **Timeline**: [When to complete or review]
   - **Traces to**: [Which insight this addresses]

2. **[Action title]**
   - **What**: [Specific change]
   - **Measure**: [Success indicator]
   - **Owner**: [Role or function]
   - **Timeline**: [Deadline or review point]
   - **Traces to**: [Insight reference]

[1-3 action items. No more than 3.]

## Appreciation and Wins

- [Specific accomplishment or strength to celebrate]
- [Specific accomplishment or strength to celebrate]

[2-4 items.]

## Summary

[2-3 sentence narrative: the key finding, the improvement commitment, and the overall team trajectory.]
```

Omit theme categories (Continue/Stop/Start) within a theme when they do not apply. Keep each observation to 1-2 sentences. Action items should be concrete enough that someone could execute them without asking follow-up questions.

## Filing the Document

If a `retrospective_directory` was found in the Agile Coach's project memory:

1. Derive a filename: `YYYY-MM-DD-<slug>.md` where `<slug>` is a short
   hyphenated description (e.g., `2026-03-10-sprint-12-retro.md`)
2. Write the retrospective document to `<directory>/<filename>`
3. If an index file (`README.md`) exists in that directory, append a row

If no directory is configured, display the document as output and note:

> To enable automatic filing, add a `retrospective_directory` entry to the
> Agile Coach's project memory
> (`.claude/agent-memory/engineering-leaders-agile-coach/MEMORY.md`) with the
> path where retrospective documents should be stored.
