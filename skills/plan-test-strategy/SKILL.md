---
name: plan-test-strategy
description: "Produce a test strategy for a feature, component, or story. Identifies the highest-impact tests by type and layer, flags brittleness risks, and recommends what NOT to test. Use for test planning, coverage gap analysis, or when deciding how to test a new feature."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob
argument-hint: "[feature, component, story, or area to analyze]"
---

# Test Strategy

Produce a focused test strategy that maximizes reliability gain per unit of maintenance cost. The output recommends specific test types at specific layers with explicit rationale for each — and equally important, what to skip.

## Input

`$ARGUMENTS` = description of the feature, component, story, or area to develop a test strategy for.

## Process

### 1. Handle Missing Input

If `$ARGUMENTS` is empty or contains no actionable description, prompt the user for the minimum information needed:

- **What feature, component, or area needs a test strategy?** — Name the feature or describe the scope.

Do not proceed until the user has provided a description of what to plan testing for.

### 2. Gather Context

- Read the project's CLAUDE.md for architecture, conventions, and domain language
- Scan the codebase for existing test patterns:
  - Glob for test files (`**/*test*`, `**/*spec*`, `**/__tests__/**`)
  - Identify test frameworks in use (package.json, go.mod, requirements.txt, etc.)
  - Note existing test organization (co-located vs. separate test directories)
- Read the code under test to understand:
  - Component boundaries and interfaces
  - External dependencies (APIs, databases, file systems, third-party services)
  - Pure logic vs. integration points vs. UI surfaces
  - Error paths and edge cases
- If a story or AC set is provided, extract the testable behaviors from acceptance criteria

### 3. Risk Assessment

Classify the feature/component along these dimensions:

| Dimension | Low Risk | High Risk |
| --- | --- | --- |
| **Blast radius** | Affects one user flow | Affects many flows or all users |
| **Change frequency** | Stable, rarely modified | Hotspot, frequently changed |
| **Failure cost** | Cosmetic or easily noticed | Data loss, security, or silent corruption |
| **Complexity** | Linear logic, few branches | Many branches, state machines, concurrency |
| **External coupling** | Pure logic, no I/O | Multiple external dependencies |

Use the risk profile to calibrate test investment — high-risk areas justify more tests at more layers; low-risk areas may need only a single layer.

### 4. Test Type Selection

For each testable behavior, recommend the **lowest effective layer**:

| Test Type | Best For | Avoid When |
| --- | --- | --- |
| **Unit tests** | Pure logic, calculations, transformations, validators, parsers | Testing glue code, configuration, or trivial delegation |
| **Integration tests** | Database queries, API client behavior, service boundaries, contract verification | The integration point is stable and well-abstracted |
| **Contract tests** | API boundaries between services, schema evolution | Internal module boundaries (use unit tests instead) |
| **Component tests** | Isolated service behavior with stubbed dependencies | The component has trivial logic |
| **End-to-end tests** | Critical user journeys, smoke tests, deployment verification | Exhaustive coverage of edge cases (use lower layers) |
| **Property-based tests** | Functions with wide input domains, serialization round-trips, invariants | Simple CRUD operations with well-defined inputs |
| **Snapshot tests** | Detecting unintended output changes in serialized formats | Rapidly evolving outputs (causes constant snapshot churn) |

**Selection heuristic:** Ask "what is the simplest test that would catch a regression here?" Start there. Move up a layer only when the lower layer cannot exercise the behavior.

### 5. Brittleness Analysis

For each recommended test, evaluate brittleness risk:

**High brittleness signals (flag and mitigate):**

- Testing implementation details rather than behavior (e.g., asserting method call counts, internal state, private method behavior)
- Excessive mocking — more than 2-3 mocks in a single test suggests the unit boundary is wrong
- Time-dependent assertions without clock control
- Order-dependent tests (test B only passes if test A runs first)
- Tight coupling to UI structure (CSS selectors, DOM hierarchy, exact text matching)
- Snapshot tests on volatile outputs (dates, IDs, non-deterministic ordering)
- Tests that assert exact error messages rather than error categories
- Asserting against auto-generated code or third-party library internals

**Mitigation strategies:**

- Test behavior through public interfaces, not internal implementation
- Replace mocks with fakes or test doubles that implement real interfaces
- Use clock injection for time-dependent logic
- Test error categories (type, code) rather than exact messages
- Use data-testid attributes or semantic selectors instead of CSS paths
- Pin only the stable subset of snapshots

### 6. Coverage Gap Identification

Cross-reference the risk assessment with existing tests:

- **High risk + no tests** = critical gap (must address)
- **High risk + low-layer tests only** = consider adding integration or e2e coverage
- **Low risk + extensive tests** = potential over-testing (flag for review)
- **Error paths untested** = common gap (especially for external dependency failures)

If `/analyze-code-churn` data is available for the area, use churn hotspots to identify files that change frequently but lack proportional test coverage — these are reliability risks.

### 7. Anti-Test List

Explicitly list what should NOT be tested and why:

- Trivial getters/setters — zero logic, zero risk
- Framework behavior — the framework is already tested
- Configuration wiring — test the behavior the config enables, not the config itself
- Third-party library internals — test your integration, not their code
- One-off scripts or migrations — test the outcome, not the script
- Exact log messages — log content is documentation, not a contract

## Output

### Test Strategy: [Feature/Component Name]

**Risk Profile:**

| Dimension | Rating | Rationale |
| --- | --- | --- |
| Blast radius | [Low/Medium/High] | [one sentence] |
| Change frequency | [Low/Medium/High] | [one sentence] |
| Failure cost | [Low/Medium/High] | [one sentence] |
| Complexity | [Low/Medium/High] | [one sentence] |
| External coupling | [Low/Medium/High] | [one sentence] |

**Overall test investment:** [Light / Moderate / Thorough] based on risk profile.

**Recommended Tests:**

For each recommended test:

```
Test: [descriptive name of what is being verified]
Type: [unit | integration | contract | component | e2e | property-based | snapshot]
Layer: [what code/boundary this exercises]
Rationale: [why this test type at this layer — what regression does it catch?]
Brittleness risk: [low | medium | high] — [mitigation if medium/high]
Priority: [critical | important | nice-to-have]
```

Group tests by priority. Lead with critical tests.

**Do Not Test:**

Bulleted list of behaviors or areas explicitly excluded from testing, each with a one-sentence rationale.

**Coverage Gaps:**

Any high-risk areas that currently lack adequate testing, with recommended remediation.

**Existing Test Observations:**

If the area already has tests, note:

- Tests that are well-placed and should be preserved
- Tests that may be over-specified or brittle (candidates for refactoring)
- Test patterns in the codebase that should be followed for consistency
