# Evidence for Mystery 07 — Wrong Route-Table Association

> Evidence status: not executed. This directory contains collection instructions only.

Related guide: [`07-wrong-route-table-association.md`](../../mysteries/07-wrong-route-table-association.md)

This mystery associates the private subnet with the public route table while `target-01` still has no public address. Evidence must distinguish route-table existence from selection by the subnet.

## Required captures

- Provider, region, timestamp, subnet identifier, and sanitized route-table identifiers.
- `target-01` private/public address state.
- Known-good private-subnet association and outbound test.
- Terraform plan that changes only the private-subnet association/reference.
- Provider-side association and both route tables while the fault is active.
- Target route choice and outbound symptom.
- Restored association, outbound retest, and post-rollback plan.

## Command checklist

```bash
date --iso-8601=seconds
terraform -chdir=terraform/<provider> state show <private-subnet-address>
terraform -chdir=terraform/<provider> state show <public-route-table-address>
terraform -chdir=terraform/<provider> state show <private-route-table-address>
terraform -chdir=terraform/<provider> plan
```

On AWS also capture `aws_route_table_association.private`. On OCI, the association is the `route_table_id` field of `oci_core_subnet.private` rather than a separate association resource.

From `target-01` capture:

```bash
ip address
ip route
ip route get <verified-public-destination-ip>
curl -4 -v --connect-timeout 10 https://<verified-public-test-host>/
```

Do not infer the association from route-table names; record the actual linked identifiers.
