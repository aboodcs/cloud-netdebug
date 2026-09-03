# Mystery 7 — Correct Resources, Wrong Association

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: AWS or OCI.

## Scenario

The expected gateway, route table, route rule, subnet, and instance all exist, yet connectivity still fails. The mystery tests relationships rather than resource existence.

A correct but unused route table has no effect on a packet. The question is not “does the route exist?” but “does the failing source subnet select the route table containing it?”

## Reproducible setup

Intentionally associate the private subnet with the existing public route table while leaving all gateways and route tables in place.

1. Record successful target outbound HTTP/HTTPS and internal `admin-01` → `target-01` SSH tests.
2. Change only the private-subnet relationship in the selected provider configuration:
   - AWS: set `aws_route_table_association.private.route_table_id` to `aws_route_table.public.id`.
   - OCI: set `oci_core_subnet.private.route_table_id` to `oci_core_route_table.public.id`.
3. Review the plan carefully. It must change the association/reference, not the subnet CIDR or instance address assignment.
4. Apply in the disposable lab.
5. Give the learner the inventory: Internet Gateway, NAT Gateway, public/private route tables, their routes, subnet, and target instance all exist—but target Internet access fails.

The private target still has no public IP. Its newly selected public table points `0.0.0.0/0` to the Internet Gateway, which is not a valid outbound design for that private interface.

### Rollback

Restore the private association/reference:

- AWS: `aws_route_table_association.private.route_table_id = aws_route_table.private.id`
- OCI: `oci_core_subnet.private.route_table_id = oci_core_route_table.private.id`

Review and apply the plan, re-query the effective association, and repeat the original tests.

## Expected behavior

| Provider | Public-subnet relationship | Private-subnet relationship |
| --- | --- | --- |
| AWS | `aws_route_table_association.public` connects `aws_subnet.public` to `aws_route_table.public` | `aws_route_table_association.private` connects `aws_subnet.private` to `aws_route_table.private` |
| OCI | `oci_core_subnet.public.route_table_id` references `oci_core_route_table.public` | `oci_core_subnet.private.route_table_id` references `oci_core_route_table.private` |

The public route table sends `0.0.0.0/0` to the Internet Gateway. The private route table sends `0.0.0.0/0` to the NAT Gateway. OCI's private table also sends the selected service CIDR to the Service Gateway.

## Actual behavior

Populate after reproduction:

| Resource/relationship | Exists? | Associated with | Evidence |
| --- | --- | --- | --- |
| Source subnet | _Populate_ | _Populate_ | _Populate_ |
| Expected route table | _Populate_ | _Populate_ | _Populate_ |
| Effective route table | _Populate_ | _Populate_ | _Populate_ |
| Gateway | _Populate_ | _Populate_ | _Populate_ |

## Initial hypotheses

1. The source subnet uses the wrong explicit route table.
2. AWS falls back to the VPC main route table because the intended association is missing.
3. An OCI subnet's `route-table-id` references a different table from the one inspected.
4. The correct association exists in Terraform configuration but was not applied or drifted remotely.
5. The route targets a similarly named but different gateway.
6. The route is correct and the failure instead occurs at security, DNS, or service layers.

## Investigation

Start with the source instance and identify its actual subnet. Do not choose a subnet by display name alone.

AWS:

```bash
aws ec2 describe-instances \
  --region <aws-region> \
  --instance-ids <instance-id> \
  --query 'Reservations[].Instances[].{Vpc:VpcId,Subnet:SubnetId,PrivateIp:PrivateIpAddress}'

aws ec2 describe-route-tables \
  --region <aws-region> \
  --filters "Name=association.subnet-id,Values=<actual-subnet-id>"

aws ec2 describe-route-tables \
  --region <aws-region> \
  --filters "Name=vpc-id,Values=<vpc-id>"
```

If the first route-table query returns no explicit association, inspect which table is the VPC main route table.

OCI:

```bash
oci compute instance get --instance-id <instance-ocid>
oci compute vnic-attachment list \
  --compartment-id <compartment-ocid> \
  --instance-id <instance-ocid>
oci network vnic get --vnic-id <vnic-ocid>
oci network subnet get --subnet-id <actual-subnet-ocid>
oci network route-table get --rt-id <route-table-ocid-from-subnet>
```

Compare desired and remote relationships:

```bash
terraform -chdir=terraform/aws plan -refresh-only
terraform -chdir=terraform/aws state show aws_route_table_association.private

terraform -chdir=terraform/oci plan -refresh-only
terraform -chdir=terraform/oci state show oci_core_subnet.private
```

Run only the pair for the provider being investigated. Confirm the gateway identifier in the effective route, not only the gateway display name.

## Evidence to collect

- Instance/VNIC ID and actual subnet ID.
- Effective route-table ID selected by that subnet.
- Full route entries and route target identifiers.
- Expected Terraform association.
- Refresh-only plan showing any drift.
- Gateway lifecycle/attachment state.
- Original failed connection result.

## Root cause

_Populate only when the effective association or another layer is proven wrong._

## Fix

_Populate after diagnosis. Correct the existing relationship through Terraform; do not create duplicate route tables or gateways as a first response._

## Validation after fix

Repeat the original flow from the same source, re-query the subnet association, and run a Terraform plan to ensure no unintended drift remains.

## What makes this mystery misleading

Inventory checks show all expected nouns while hiding the incorrect edge between them. Packet paths follow identifiers and associations, not resource names or operator intent.

## Provider-specific notes

- AWS represents the relationship with `aws_route_table_association` and can fall back to the VPC main table.
- OCI stores `route_table_id` on the subnet resource in this project.
- OCI's Service Gateway route is relevant only for matching OCI service destinations; it cannot repair the Internet default route.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-07/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is the private subnet selecting the public route table. All named resources still exist, but packets from `target-01` follow the Internet Gateway default route instead of the NAT Gateway route. Because the target has no public IP, that is not a valid Internet path.

Provider-local routing can still carry admin-to-target SSH, so the working internal control is consistent with the fault. The minimal fix is to restore the original private route-table relationship; creating more route tables or gateways would not correct selection.

</details>
