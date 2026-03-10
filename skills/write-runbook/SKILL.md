---
name: write-runbook
description: "Generate a structured operational runbook for incident response, diagnostics, or maintenance procedures. Use when defining a runbook for a new alert, documenting a post-incident gap, establishing an operational procedure, or preparing a maintenance checklist."
user-invokable: true
context: fork
allowed-tools: Read, Grep, Glob
argument-hint: "[alert name, service name, or description of the operational scenario]"
---

# Write Runbook

Generate a fully structured operational runbook from a scenario description.

## Input

`$ARGUMENTS` = description of the operational scenario — alert name, service name, and/or procedure type (e.g., "high CPU on payment-api", "certificate rotation for api.example.com", "diagnose intermittent 502s from ALB").

## Process

### 1. Handle Missing Input

If `$ARGUMENTS` is empty or contains no actionable description, prompt the user for the minimum information needed:

- **What operational scenario does this runbook cover?** — Provide an alert name, service name, or description of the procedure (e.g., "high CPU on payment-api", "certificate rotation for api.example.com").

Do not proceed until the user has provided a scenario description.

### 2. Determine Runbook Type

Select the type based on the scenario:

- **Incident response** — a known failure mode triggered by an alert or symptom with understood remediation paths
- **Diagnostic** — unknown root cause; the goal is symptom-to-cause investigation
- **Maintenance** — planned operational task (deployment, certificate rotation, scaling change, database migration)

If the scenario is ambiguous, default to **incident response**.

### 3. Generate a Runbook ID

Assign a unique ID using the pattern `RUN-[SERVICE-PREFIX]-[NNN]` where:

- `SERVICE-PREFIX` is a 2–4 letter abbreviation of the primary service (e.g., `PAY` for payment-api, `DB` for database, `CERT` for certificate, `GEN` for general)
- `NNN` is a sequential number starting at `001`

### 4. Produce the Runbook

Use the template for the selected type below. Fill every section with specifics derived from `$ARGUMENTS`. Do not leave placeholder text that requires the user to fill in — infer reasonable defaults and mark them with `[VERIFY]` where validation against the real system is required.

**If this procedure is normally executed by automation or a script:** Ask: *What steps does the normal automation perform implicitly that a responder would miss if bypassing it?* Incorporate every answer as an explicit numbered step. Common hidden steps: loading environment variables, validating credentials, acquiring locks, checking prerequisites, taking a pre-operation backup. Never write "run the script" — list what the script does so a responder can execute the procedure without it.

---

## Templates

### Incident Response Runbook

```markdown
# [Alert Name]: [Service] — Incident Response Runbook

## Metadata

| Field               | Value                                         |
|---------------------|-----------------------------------------------|
| Runbook ID          | RUN-XXX-001                                   |
| Owner               | [Team] / @[individual]                        |
| Last Updated        | YYYY-MM-DD                                    |
| Last Validated      | YYYY-MM-DD                                    |
| Severity            | [P1 / P2 / P3]                                |
| Related Alerts      | [alert-name]                                  |
| Dashboards          | [Link to primary dashboard — VERIFY]          |
| Tools Required      | [e.g., kubectl, aws-cli, psql]                |
| Permissions Required| [e.g., k8s-prod-admin, AWS ReadOnly]          |
| Escalation Contact  | [PagerDuty service / Slack channel]           |

## Overview

**What this runbook covers:** [1–2 sentences on the symptom and scope]

**What this runbook does NOT cover:** [Explicit exclusions with links to other runbooks if known]

## Impact

[Who or what is affected when this alert fires. Customer-facing? Internal only? Data integrity risk? Revenue impact?]

## Prerequisites

- [ ] Access to [system/tool] via [method — e.g., VPN, bastion host]
- [ ] CLI tool [name] installed and authenticated
- [ ] Credentials fetched from [vault path — never store inline]
- [ ] [Any other precondition — e.g., maintenance window open, stakeholders notified]

## Diagnosis Steps

### Step 1: Confirm the alert is real (not a false positive)

Run:

```bash
[command to confirm the alert condition — e.g., check metric, health endpoint]
```

**Expected:** [normal output]

**If alert is confirmed:** → Continue to Step 2.

**If no anomaly found:** → Alert may have resolved. Monitor for 5 minutes. If clean, close with note "resolved before investigation began."

### Step 2: Identify the blast radius

Run:

```bash
[command to check affected services, error rates, user impact]
```

**Expected:** [normal output]

**If blast radius is expanding:** → Escalate immediately per the Escalation section below.

**If contained:** → Continue to Step 3.

### Step 3: Check [primary component health]

Run:

```bash
[exact diagnostic command]
```

**Expected:** [normal output description]

**If abnormal → Go to Remediation Option A.**

**If normal → Go to Step 4.**

### Step 4: Check [secondary component or dependency]

Run:

```bash
[exact diagnostic command]
```

**Expected:** [normal output]

**If abnormal → Go to Remediation Option B.**

**If normal → Go to Step 5.**

### Step 5: Check recent changes

Run:

```bash
[command to check recent deployments, config changes, or infrastructure changes]
```

**Expected:** No changes in the past [N] hours / last deployment was > [N] hours ago.

**If a recent change correlates with the issue:** → Rollback per the Rollback section, then re-verify.

**If no correlating change found:** → Escalate with full diagnostic output.

## Remediation

### Option A: [Most common fix — label descriptively]

⚠️ **This modifies production state.**

1. Run:

   ```bash
   [exact command]
   ```

   **Expected output:** [what success looks like]

2. Verify the fix took effect:

   ```bash
   [verification command]
   ```

   **Expected:** [success indicator]

3. → Continue to Verification.

### Option B: [Alternative fix]

⚠️ **This modifies production state.**

1. Run:

   ```bash
   [exact command]
   ```

   **Expected output:** [what success looks like]

2. → Continue to Verification.

## Rollback

If remediation worsens the situation or introduces new errors:

1. ⚠️ Run:

   ```bash
   [exact rollback command]
   ```

2. Verify rollback succeeded:

   ```bash
   [verification command]
   ```

   **Expected:** [pre-incident state indicators]

3. Escalate if rollback does not restore the system to baseline.

## Verification

- [ ] [Primary metric] returned to normal range — expected: [value or threshold]
- [ ] [Dashboard link — VERIFY] shows green / no active alerts
- [ ] No new errors in logs for [N] minutes
- [ ] [Any dependent service health check]
- [ ] Monitor for [N] minutes before closing the incident

## Escalation

**Escalate if any of the following are true:**

- Unresolved after [30] minutes of active investigation
- Customer-facing error rate exceeds [5%]
- Data integrity is at risk
- Blast radius is expanding despite remediation attempts

**How to escalate:**

1. Page [team/individual] via [PagerDuty service name / Slack @handle]
2. Post in [#incident-channel] with:
   - Current symptoms and alert name
   - Steps taken so far and their outcomes
   - Diagnostic output (paste or link)
3. Hand off with a verbal/written summary

## Post-Incident

- [ ] Update this runbook with any new findings within 5 business days
- [ ] File a ticket for automation opportunity if the same steps were followed manually
- [ ] Add to post-incident review agenda: Was this runbook accurate? What would have made it better?
- [ ] Update alert definition to link this runbook URL if not already linked
```

---

### Diagnostic Runbook

For situations with **unknown root cause** — structure as a symptom-to-cause decision tree ordered from most likely to least likely.

```markdown
# [Symptom Description] — Diagnostic Runbook

## Metadata

| Field               | Value                              |
|---------------------|------------------------------------|
| Runbook ID          | RUN-XXX-001                        |
| Owner               | [Team] / @[individual]             |
| Last Updated        | YYYY-MM-DD                         |
| Last Validated      | YYYY-MM-DD                         |
| Tools Required      | [tools]                            |
| Permissions Required| [permissions]                      |
| Related Runbooks    | [links to remediation runbooks]    |

## Symptom

[Observable behavior that triggered this investigation — exact error message, metric value, or user report]

## Investigation Checklist

Work through checks in order. Stop at the first check that identifies a root cause.

### Check 1: [Most likely cause]

**Command:**

```bash
[diagnostic command]
```

**If [condition indicating this is the cause]:** Root cause is [X]. → See [Remediation Runbook RUN-XXX].

**If normal:** → Continue to Check 2.

### Check 2: [Second most likely cause]

**Command:**

```bash
[diagnostic command]
```

**If [condition]:** Root cause is [Y]. → See [Remediation Runbook RUN-XXX].

**If normal:** → Continue to Check 3.

### Check 3: [Third most likely cause]

**Command:**

```bash
[diagnostic command]
```

**If [condition]:** Root cause is [Z]. → Apply [resolution].

**If normal:** → Continue to Check 4.

### Check 4: [Less likely — dependency or external factor]

**Command:**

```bash
[diagnostic command]
```

**If [condition]:** → [action]

**If normal:** → No root cause identified. Escalate.

## No Root Cause Identified

Escalate to [team] via [method] with the following information gathered:

- [ ] Output of Check 1: [paste]
- [ ] Output of Check 2: [paste]
- [ ] Output of Check 3: [paste]
- [ ] Output of Check 4: [paste]
- [ ] Approximate time the symptom first appeared
- [ ] Any recent changes (deploys, config, infrastructure)
- [ ] Affected users / services / percentage of traffic
```

---

### Maintenance Runbook

For planned operational tasks — deployments, certificate rotations, capacity changes, database migrations.

```markdown
# [Procedure Name] — Maintenance Runbook

## Metadata

| Field                | Value                                    |
|----------------------|------------------------------------------|
| Runbook ID           | RUN-XXX-001                              |
| Owner                | [Team] / @[individual]                   |
| Last Updated         | YYYY-MM-DD                               |
| Last Validated       | YYYY-MM-DD                               |
| Estimated Duration   | [N] minutes                              |
| Maintenance Window   | [required window — or "anytime"]         |
| Tools Required       | [tools]                                  |
| Permissions Required | [permissions — fetch from vault, path]   |
| Rollback Time        | [estimated rollback duration]            |

## Overview

**Purpose:** [What this procedure accomplishes and why it is needed]

**Scope:** [What systems are affected]

**Risk level:** [Low / Medium / High] — [brief rationale]

## Pre-Maintenance Checklist

- [ ] Change ticket [ID] approved and linked
- [ ] Maintenance window confirmed: [date/time] – [date/time] [timezone]
- [ ] Stakeholders notified via [channel]
- [ ] Backup completed and verified — run:

  ```bash
  [backup verification command]
  ```

  **Expected:** [confirmation output]

- [ ] Rollback procedure reviewed and tested (or tested in staging)
- [ ] [Any other precondition]

## Procedure

### Step 1: [First action]

Run:

```bash
[exact command]
```

**Checkpoint:** Verify step succeeded:

```bash
[verification command]
```

**Expected:** [success output]

**If step fails:** → Do not continue. Execute rollback.

### Step 2: [Second action]

⚠️ **This modifies production state.**

Run:

```bash
[exact command]
```

**Checkpoint:**

```bash
[verification command]
```

**Expected:** [success output]

### Step 3: [Continue for all steps...]

[...]

## Post-Maintenance Verification

- [ ] [Primary health check — command and expected output]
- [ ] [Smoke test — command and expected output]
- [ ] [Dependent service health check]
- [ ] Monitor for [N] minutes before declaring success
- [ ] Stakeholders notified of successful completion via [channel]
- [ ] Change ticket updated and closed

## Rollback

If the procedure fails at any step:

1. Stop immediately — do not continue to the next step.

2. ⚠️ Execute rollback:

   ```bash
   [rollback command for the most recent irreversible action]
   ```

3. Verify system returned to pre-maintenance state:

   ```bash
   [verification command]
   ```

4. Notify stakeholders of rollback via [channel].

5. Update change ticket with failure details and schedule a post-mortem.
```

---

## Output

Produce a single complete runbook in Markdown. Fill every field with specifics from `$ARGUMENTS`. Where exact values cannot be inferred, use `[VERIFY]` as a placeholder and note what needs to be confirmed against the real system.

After the runbook, include a brief **"Next Steps"** section (outside the runbook body) with:

1. Where to store this runbook (suggest the relevant repository or wiki location)
2. Which alert definition(s) should link to this runbook URL
3. Who should validate it (service owner or on-call engineer)
4. Suggested first validation method (e.g., tabletop walkthrough, game day, next incident)
