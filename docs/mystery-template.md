# Mystery `<number>` — `<short title>`

Copy this template into the appropriate file under `docs/mysteries/`. Replace every placeholder with observed information. A facilitator may define the intended injected fault in the setup and collapsed answer key, but do not write a runtime root cause or successful verification until evidence supports it.

> Status: _planned / reproduced / diagnosed / fixed / verified_
>
> Provider scope: _AWS / OCI / provider-neutral / Kubernetes / Helm_

## Scenario

Describe the controlled situation without diagnosing it.

- Environment:
- Provider/cluster:
- Date and time:
- Last known-good baseline:
- Change used to stage the mystery, if known:

## Reproducible setup

Define the smallest controlled change that creates the symptom. Do not claim it has been applied unless it has.

1. Record a known-good baseline for the exact traffic path.
2. Record the provider, resource, and configuration element to change.
3. Describe or apply one deliberate fault only.
4. Preserve a separate administration or provider-console recovery path.
5. Give the learner the symptom without revealing the injected fault.

### Rollback

Document the exact reversal before staging the fault. If the exercise can interrupt administration access, use an automatic time-limited rollback where the platform supports it.

## Expected behavior

State the exact expected source, destination, protocol, port, and result.

```text
<source> -> <destination> -> <protocol>/<port> -> <expected result>
```

Explain why this behavior is expected from the route and security design.

## Actual behavior

Record the exact symptom and command output reference.

```text
Command:
Observed result:
Timestamp:
Evidence file:
```

Do not summarize a timeout, refusal, DNS error, authentication error, and HTTP error as the same symptom. They prove different amounts of the path.

## Initial assumptions

List assumptions that must be verified rather than treated as facts.

- [ ] The source is the intended host or Pod.
- [ ] The destination name resolves to the expected address.
- [ ] The destination port is correct.
- [ ] The relevant baseline was previously recorded.
- [ ] No unrelated changes occurred.

Additional assumptions:

- _Populate during investigation._

## Scope

### In scope

- _List the layers and resources involved._

### Out of scope

- _List layers ruled out by existing evidence, with the evidence reference._

Do not mark a layer out of scope merely because its resource exists.

## Traffic path

Draw the expected path and identify every policy boundary.

```text
<source>
   |
   v
<source security / route>
   |
   v
<gateway or Kubernetes Service>
   |
   v
<destination security / host firewall / NetworkPolicy>
   |
   v
<listening process>
```

| Hop/layer | Expected state | Observed state | Evidence |
| --- | --- | --- | --- |
| Source resource/interface |  |  |  |
| Source route |  |  |  |
| Cloud route/gateway |  |  |  |
| Security control |  |  |  |
| Destination interface |  |  |  |
| Host firewall |  |  |  |
| Listening service |  |  |  |
| Kubernetes/Helm, if applicable |  |  |  |

## Initial hypotheses

Rank hypotheses before making changes.

| Priority | Hypothesis | Evidence for | Evidence against | Discriminating test |
| --- | --- | --- | --- | --- |
| 1 |  |  |  |  |
| 2 |  |  |  |  |
| 3 |  |  |  |  |

Use falsifiable statements. “Networking is broken” is not a hypothesis; “the private subnet is associated with a route table that lacks a NAT default route” is.

## Evidence collected

| Timestamp | Source | Command/observation | Result summary | Evidence file |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

Preserve raw output separately when it is useful. Sanitize credentials, tokens, private keys, public account identifiers, and unrelated user data.

## Commands used

```bash
# Add the exact commands used. Remove secrets before committing.
```

Record the execution host for commands whose result depends on the source path.

## Layer-by-layer investigation

### 1. Desired and current resource state

- Terraform configuration:
- Terraform state/plan:
- Provider API or Kubernetes API state:
- Conclusion:

### 2. Interface and addressing

- Source interface/IP:
- Destination interface/IP:
- Addressing-plan match:
- Conclusion:

### 3. Routing and gateways

- Source route decision:
- Subnet route-table association:
- Gateway state:
- Return route:
- Conclusion:

### 4. DNS

- Resolver configuration:
- Query result:
- IP-based control test:
- Conclusion:

### 5. Security controls

- AWS Security Group / OCI NSG:
- OCI security list or AWS network ACL, if relevant:
- Host firewall:
- Stateful return behavior:
- Conclusion:

### 6. Port and process

- Port test result:
- Listening address/port:
- Service status/logs:
- Conclusion:

### 7. Kubernetes and Helm, if applicable

- Namespace:
- Pod labels:
- Service selector:
- Service port/targetPort:
- EndpointSlice:
- NetworkPolicy and CNI enforcement:
- Helm values/rendered manifest/live-object comparison:
- Conclusion:

## Root cause

_Populate only after the evidence identifies the failed layer and exact misconfiguration or state._

State:

1. What was wrong.
2. Where it was wrong.
3. Why it produced the observed symptom.
4. Why nearby working tests could still succeed.

## Fix

_Populate after diagnosis._

- Smallest corrective change:
- Why this fix matches the proven cause:
- Change reference or command:
- Rollback approach:

Avoid listing speculative changes that were not applied.

## Validation after fix

Repeat the original test from the original source.

| Test | Before | Expected after fix | Actual after fix | Evidence |
| --- | --- | --- | --- | --- |
| Original failing flow |  |  |  |  |
| Known-good control flow |  |  |  |  |
| Terraform drift check, if relevant |  | No unexpected changes |  |  |

_Do not mark the mystery verified until the actual post-fix result is recorded._

## What made the mystery misleading

Explain which true but incomplete observation pointed toward the wrong layer. Examples include a gateway existing but not being selected, ICMP working while TCP is blocked, or Pods being healthy while a Service has no endpoints.

## Lesson learned

Write the reusable engineering lesson, not only the one-off fix.

## Provider-specific notes

- Shared concept:
- AWS behavior, if applicable:
- OCI behavior, if applicable:
- Kubernetes/CNI behavior, if applicable:
- Non-equivalences that matter:

Do not invent symmetry. OCI Service Gateway and AWS service-specific VPC endpoints are different designs.

## Evidence file locations

- Pre-fix state: `docs/evidence/mystery-<number>/`
- Test output: `docs/evidence/mystery-<number>/`
- Post-fix state: `docs/evidence/mystery-<number>/`
- Screenshot, if one was genuinely captured: `docs/evidence/mystery-<number>/`

List only files that exist.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

State the deliberately injected fault, the evidence expected to distinguish it from nearby hypotheses, and the smallest intended fix. This describes the exercise design; it is not evidence that the mystery was executed or solved.

</details>
