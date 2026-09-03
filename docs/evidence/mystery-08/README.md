# Evidence for Mystery 08 — Terraform Drift

> Evidence status: not executed. No provider-side deletion has been performed by this documentation change.

Related guide: [`08-terraform-drift.md`](../../mysteries/08-terraform-drift.md)

The controlled drift is manual deletion of the Terraform-managed public HTTPS egress rule for `target-01`. Terraform configuration and state must remain unedited until the comparison is captured.

## Required captures

- Git revision, Terraform workspace, provider, region, and timestamp.
- Clean or fully explained pre-change plan.
- Exact remote rule identifier and a provider view before deletion.
- Timestamped record of the single console/API deletion.
- Provider view after deletion.
- `terraform plan -refresh-only` and normal `terraform plan` output.
- HTTP/HTTPS tests before and after the remote change.
- Reviewed Terraform restoration, provider view, retest, and final plan.

## Command checklist

```bash
git rev-parse HEAD
git status --short
terraform -chdir=terraform/<provider> workspace show
terraform -chdir=terraform/<provider> state list
terraform -chdir=terraform/<provider> plan -refresh-only
terraform -chdir=terraform/<provider> plan
```

Relevant resources:

- AWS: `aws_vpc_security_group_egress_rule.target_allow_https`
- OCI: `oci_core_network_security_group_security_rule.target_allow_https_to_internet`

Save configuration, state, and remote-provider observations as separate evidence. Never edit the state file or fabricate a clean final plan.
