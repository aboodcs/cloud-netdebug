# Mystery 8 — Terraform Drift

> Status: reproducible mystery defined but not executed; no manual change or runtime evidence is recorded.
>
> Provider scope: AWS or OCI.

## Scenario

A controlled provider-side change is made outside Terraform. The task is to detect the difference between configuration, Terraform state, and the remote object; explain its network effect; and restore intended state deliberately.

This document defines the manual change but does not claim it has been applied. Record the exact staged change when the exercise is performed, and use a disposable lab environment.

## Reproducible setup

Use a manual deletion of the target's public HTTPS egress rule. This produces visible Terraform drift without destroying an instance, subnet, route table, or gateway.

1. Record successful target HTTP and HTTPS requests to the same verified Internet endpoint.
2. Record a clean or fully understood Terraform plan before staging the change.
3. In the selected provider console, manually delete only this managed rule:
   - AWS: the rule represented by `aws_vpc_security_group_egress_rule.target_allow_https`
   - OCI: the rule represented by `oci_core_network_security_group_security_rule.target_allow_https_to_internet`
4. Do not edit Terraform configuration or state.
5. Repeat HTTP and HTTPS tests, then run `terraform plan -refresh-only` and a normal `terraform plan`.
6. Give the learner the symptom and plans without identifying the console change.

On OCI, leave `target_allow_https_to_oci_services` intact. It is a separate service-CIDR rule and may provide a useful comparison.

### Rollback

After the learner proves the missing remote rule, use a reviewed Terraform apply to recreate it from the unchanged configuration. Then confirm the provider rule, repeat both traffic tests, and run another normal plan.

## Expected behavior

Before staging drift:

```text
Terraform configuration == Terraform state == remote provider object
```

After a controlled manual change:

```text
Terraform configuration != refreshed remote provider state
                         -> plan explains proposed reconciliation
```

The final goal is not simply an empty plan. The operator must identify what changed, why it affected or did not affect traffic, and why the chosen restoration is correct.

## Actual behavior

Populate during the exercise:

| Field | Recorded value |
| --- | --- |
| Provider | _Populate_ |
| Resource address | _Populate_ |
| Manual change | _Populate_ |
| Time of change | _Populate_ |
| Expected traffic effect | _Populate_ |
| Observed traffic effect | _Populate_ |

## Initial hypotheses

1. A remote attribute differs from Terraform configuration.
2. A different variable value or workspace, rather than remote drift, explains the plan.
3. The resource was replaced or deleted outside Terraform.
4. State points at a different remote object than the operator inspected.
5. The network symptom is unrelated to the staged change.

## Investigation

Preserve repository and state context:

```bash
git status --short
terraform -chdir=terraform/<provider> workspace show
terraform -chdir=terraform/<provider> state list
terraform -chdir=terraform/<provider> show
terraform -chdir=terraform/<provider> plan -refresh-only
terraform -chdir=terraform/<provider> plan
```

Replace `<provider>` with `aws` or `oci`. Read the plan before applying anything. `-refresh-only` focuses on updating Terraform's view of remote changes; a normal plan shows how configuration would reconcile them.

Inspect the exact object through the relevant provider CLI. Examples:

```bash
# AWS route-table example
aws ec2 describe-route-tables \
  --region <aws-region> \
  --route-table-ids <route-table-id>

# OCI route-table example
oci network route-table get --rt-id <route-table-ocid>
```

If the staged change concerns security or an association, use the matching provider query and record identifiers. Do not edit the Terraform state file manually to make the plan disappear.

## Evidence to collect

- Git revision and Terraform workspace.
- Pre-change baseline and resource identifier.
- Exact manual change and timestamp.
- Provider API output after the change.
- Refresh-only and normal plan output.
- Relevant traffic test before and after drift.
- Post-restoration plan and traffic result.

Sanitize account IDs, OCIDs, public addresses, credentials, and tokens before committing output.

## Root cause

_Populate after proving whether the difference is remote drift, changed input, wrong workspace/state, or an unrelated symptom._

## Fix

_Populate after diagnosis._ Possible strategies must be chosen deliberately:

- Restore the remote object to the existing configuration through Terraform.
- Update configuration to adopt an intentional remote change, then review and apply it.
- Import or remove state only when object ownership is proven and the operation is understood.

Do not run `apply`, import, or state-removal commands merely because they eliminate a diff.

## Validation after fix

Expected validation sequence:

```bash
terraform -chdir=terraform/<provider> plan
```

Then repeat the exact network test affected by the drift. Record both outputs; do not state “no changes” until the command actually reports it.

## What makes this mystery misleading

The Terraform file can look correct while the remote association or rule differs. Conversely, a plan difference can come from input/workspace selection rather than a manual cloud change. All three views must be compared.

## Provider-specific notes

The drift method is provider-neutral, but AWS and OCI expose different identifiers and relationship models. AWS subnet route-table associations are separate resources; OCI stores the route-table reference on the subnet. That difference changes which object should be inspected.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-08/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is provider-side deletion of a Terraform-managed TCP/443 egress rule. Configuration still declares it, local state initially remembers it, and refreshed remote state shows it missing. A normal plan should propose recreation of that rule.

The learner must distinguish remote drift from a configuration edit or wrong workspace. The intended restoration is a reviewed Terraform apply using the unchanged configuration, followed by an HTTPS test and a plan showing no remaining unexpected difference.

</details>
