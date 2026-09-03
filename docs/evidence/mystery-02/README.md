# Evidence for Mystery 02 — Private Network Works, Internet Fails

> Evidence status: not executed. This directory contains collection instructions only.

Related guide: [`02-private-network-works-internet-fails.md`](../../mysteries/02-private-network-works-internet-fails.md)

Collect the internal and Internet tests from `target-01`. The staged fault removes the private route table's default route to the provider NAT Gateway while leaving local cloud-network routing intact.

## Required captures

- Provider, region, timestamp, and sanitized resource identifiers.
- Known-good internal and Internet tests before the change.
- `target-01` interface, local route, and selected route information.
- Private-subnet route-table association and route entries.
- NAT Gateway state.
- Internal and Internet tests while the fault is active.
- Terraform plan/apply evidence for the deliberate change and rollback.
- Repeated tests after rollback.

## Command checklist

Run on `target-01`:

```bash
date --iso-8601=seconds
hostname
ip address
ip route
ip route get <admin-private-ip>
ip route get <verified-public-destination-ip>
ping -c 4 <admin-private-ip>
curl -4 -v --connect-timeout 10 https://<verified-public-test-host>/
```

Capture the relevant Terraform objects:

```bash
terraform -chdir=terraform/<provider> state show <private-route-table-address>
terraform -chdir=terraform/<provider> state show <nat-gateway-address>
terraform -chdir=terraform/<provider> plan
```

Use `aws_route_table.private` and `aws_nat_gateway.main` on AWS, or `oci_core_route_table.private` and `oci_core_nat_gateway.main` on OCI. Replace placeholders with values verified from the selected lab; do not invent destinations or results.
