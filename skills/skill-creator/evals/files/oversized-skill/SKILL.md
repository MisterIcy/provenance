---
name: oversized-skill
description: Diagnoses and fixes common deploy pipeline failures by error code. Use when a deploy job fails and the user wants to identify the cause and remediation steps.
---

# Deploy Pipeline Troubleshooting

## What this skill does

Looks up a deploy pipeline error code and walks through the cause and fix.

## Workflow

1. Get the error code from the failed deploy log.
2. Find the matching section below.
3. Walk through the remediation steps in order.

## Error codes

### Error code 501

**Symptom:** Deploy job fails at stage 2 with error 501, logs show a stack trace referencing subsystem-1.

**Cause:** The subsystem-1 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-1's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-1 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 2 --verbose --error-code 501
```

### Error code 502

**Symptom:** Deploy job fails at stage 3 with error 502, logs show a stack trace referencing subsystem-2.

**Cause:** The subsystem-2 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-2's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-2 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 3 --verbose --error-code 502
```

### Error code 503

**Symptom:** Deploy job fails at stage 4 with error 503, logs show a stack trace referencing subsystem-3.

**Cause:** The subsystem-3 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-3's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-3 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 4 --verbose --error-code 503
```

### Error code 504

**Symptom:** Deploy job fails at stage 5 with error 504, logs show a stack trace referencing subsystem-4.

**Cause:** The subsystem-4 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-4's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-4 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 5 --verbose --error-code 504
```

### Error code 505

**Symptom:** Deploy job fails at stage 6 with error 505, logs show a stack trace referencing subsystem-5.

**Cause:** The subsystem-5 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-5's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-5 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 6 --verbose --error-code 505
```

### Error code 506

**Symptom:** Deploy job fails at stage 1 with error 506, logs show a stack trace referencing subsystem-6.

**Cause:** The subsystem-6 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-6's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-6 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 1 --verbose --error-code 506
```

### Error code 507

**Symptom:** Deploy job fails at stage 2 with error 507, logs show a stack trace referencing subsystem-7.

**Cause:** The subsystem-7 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-7's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-7 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 2 --verbose --error-code 507
```

### Error code 508

**Symptom:** Deploy job fails at stage 3 with error 508, logs show a stack trace referencing subsystem-8.

**Cause:** The subsystem-8 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-8's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-8 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 3 --verbose --error-code 508
```

### Error code 509

**Symptom:** Deploy job fails at stage 4 with error 509, logs show a stack trace referencing subsystem-9.

**Cause:** The subsystem-9 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-9's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-9 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 4 --verbose --error-code 509
```

### Error code 510

**Symptom:** Deploy job fails at stage 5 with error 510, logs show a stack trace referencing subsystem-10.

**Cause:** The subsystem-10 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-10's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-10 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 5 --verbose --error-code 510
```

### Error code 511

**Symptom:** Deploy job fails at stage 6 with error 511, logs show a stack trace referencing subsystem-11.

**Cause:** The subsystem-11 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-11's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-11 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 6 --verbose --error-code 511
```

### Error code 512

**Symptom:** Deploy job fails at stage 1 with error 512, logs show a stack trace referencing subsystem-12.

**Cause:** The subsystem-12 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-12's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-12 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 1 --verbose --error-code 512
```

### Error code 513

**Symptom:** Deploy job fails at stage 2 with error 513, logs show a stack trace referencing subsystem-13.

**Cause:** The subsystem-13 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-13's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-13 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 2 --verbose --error-code 513
```

### Error code 514

**Symptom:** Deploy job fails at stage 3 with error 514, logs show a stack trace referencing subsystem-14.

**Cause:** The subsystem-14 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-14's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-14 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 3 --verbose --error-code 514
```

### Error code 515

**Symptom:** Deploy job fails at stage 4 with error 515, logs show a stack trace referencing subsystem-15.

**Cause:** The subsystem-15 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-15's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-15 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 4 --verbose --error-code 515
```

### Error code 516

**Symptom:** Deploy job fails at stage 5 with error 516, logs show a stack trace referencing subsystem-16.

**Cause:** The subsystem-16 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-16's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-16 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 5 --verbose --error-code 516
```

### Error code 517

**Symptom:** Deploy job fails at stage 6 with error 517, logs show a stack trace referencing subsystem-17.

**Cause:** The subsystem-17 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-17's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-17 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 6 --verbose --error-code 517
```

### Error code 518

**Symptom:** Deploy job fails at stage 1 with error 518, logs show a stack trace referencing subsystem-18.

**Cause:** The subsystem-18 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-18's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-18 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 1 --verbose --error-code 518
```

### Error code 519

**Symptom:** Deploy job fails at stage 2 with error 519, logs show a stack trace referencing subsystem-19.

**Cause:** The subsystem-19 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-19's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-19 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 2 --verbose --error-code 519
```

### Error code 520

**Symptom:** Deploy job fails at stage 3 with error 520, logs show a stack trace referencing subsystem-20.

**Cause:** The subsystem-20 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-20's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-20 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 3 --verbose --error-code 520
```

### Error code 521

**Symptom:** Deploy job fails at stage 4 with error 521, logs show a stack trace referencing subsystem-21.

**Cause:** The subsystem-21 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-21's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-21 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 4 --verbose --error-code 521
```

### Error code 522

**Symptom:** Deploy job fails at stage 5 with error 522, logs show a stack trace referencing subsystem-22.

**Cause:** The subsystem-22 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-22's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-22 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 5 --verbose --error-code 522
```

### Error code 523

**Symptom:** Deploy job fails at stage 6 with error 523, logs show a stack trace referencing subsystem-23.

**Cause:** The subsystem-23 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-23's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-23 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 6 --verbose --error-code 523
```

### Error code 524

**Symptom:** Deploy job fails at stage 1 with error 524, logs show a stack trace referencing subsystem-24.

**Cause:** The subsystem-24 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-24's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-24 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 1 --verbose --error-code 524
```

### Error code 525

**Symptom:** Deploy job fails at stage 2 with error 525, logs show a stack trace referencing subsystem-25.

**Cause:** The subsystem-25 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-25's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-25 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 2 --verbose --error-code 525
```

### Error code 526

**Symptom:** Deploy job fails at stage 3 with error 526, logs show a stack trace referencing subsystem-26.

**Cause:** The subsystem-26 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-26's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-26 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 3 --verbose --error-code 526
```

### Error code 527

**Symptom:** Deploy job fails at stage 4 with error 527, logs show a stack trace referencing subsystem-27.

**Cause:** The subsystem-27 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-27's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-27 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 4 --verbose --error-code 527
```

### Error code 528

**Symptom:** Deploy job fails at stage 5 with error 528, logs show a stack trace referencing subsystem-28.

**Cause:** The subsystem-28 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-28's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-28 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 5 --verbose --error-code 528
```

### Error code 529

**Symptom:** Deploy job fails at stage 6 with error 529, logs show a stack trace referencing subsystem-29.

**Cause:** The subsystem-29 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-29's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-29 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 6 --verbose --error-code 529
```

### Error code 530

**Symptom:** Deploy job fails at stage 1 with error 530, logs show a stack trace referencing subsystem-30.

**Cause:** The subsystem-30 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-30's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-30 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 1 --verbose --error-code 530
```

### Error code 531

**Symptom:** Deploy job fails at stage 2 with error 531, logs show a stack trace referencing subsystem-31.

**Cause:** The subsystem-31 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-31's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-31 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 2 --verbose --error-code 531
```

### Error code 532

**Symptom:** Deploy job fails at stage 3 with error 532, logs show a stack trace referencing subsystem-32.

**Cause:** The subsystem-32 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-32's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-32 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 3 --verbose --error-code 532
```

### Error code 533

**Symptom:** Deploy job fails at stage 4 with error 533, logs show a stack trace referencing subsystem-33.

**Cause:** The subsystem-33 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-33's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-33 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 4 --verbose --error-code 533
```

### Error code 534

**Symptom:** Deploy job fails at stage 5 with error 534, logs show a stack trace referencing subsystem-34.

**Cause:** The subsystem-34 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-34's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-34 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 5 --verbose --error-code 534
```

### Error code 535

**Symptom:** Deploy job fails at stage 6 with error 535, logs show a stack trace referencing subsystem-35.

**Cause:** The subsystem-35 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-35's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-35 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 6 --verbose --error-code 535
```

### Error code 536

**Symptom:** Deploy job fails at stage 1 with error 536, logs show a stack trace referencing subsystem-36.

**Cause:** The subsystem-36 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-36's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-36 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 1 --verbose --error-code 536
```

### Error code 537

**Symptom:** Deploy job fails at stage 2 with error 537, logs show a stack trace referencing subsystem-37.

**Cause:** The subsystem-37 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-37's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-37 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 2 --verbose --error-code 537
```

### Error code 538

**Symptom:** Deploy job fails at stage 3 with error 538, logs show a stack trace referencing subsystem-38.

**Cause:** The subsystem-38 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-38's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-38 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 3 --verbose --error-code 538
```

### Error code 539

**Symptom:** Deploy job fails at stage 4 with error 539, logs show a stack trace referencing subsystem-39.

**Cause:** The subsystem-39 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-39's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-39 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 4 --verbose --error-code 539
```

### Error code 540

**Symptom:** Deploy job fails at stage 5 with error 540, logs show a stack trace referencing subsystem-40.

**Cause:** The subsystem-40 service was unreachable, misconfigured, or returned an unexpected response during the deploy step, typically due to a stale credential, a network partition, or a version mismatch between the deploy tooling and the target environment.

**Remediation:**
1. Re-run the deploy job with verbose logging enabled (`--verbose`) to confirm the exact failing call.
2. Check subsystem-40's health dashboard for an ongoing incident.
3. Rotate or refresh the credential used for subsystem-40 if the error mentions authentication.
4. If the issue persists, roll back to the last known-good deploy and escalate to the platform team.

**Example command:**
```
deploy-tool retry --stage 5 --verbose --error-code 540
```
