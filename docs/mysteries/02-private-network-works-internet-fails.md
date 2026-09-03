# Mystery 2 — Private Network Works, Internet Fails

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: AWS or OCI.

## Scenario

The internal path from `admin-01` to `target-01` works, while outbound Internet access from `target-01` fails.

The working SSH path is evidence that both instances exist and that some VPC/VCN-local routing and security behavior works. It does not test the private subnet's default route, NAT Gateway, Internet-facing path, target egress for the requested port, DNS, or the remote service.

## Reproducible setup

Create the failure as a managed Terraform change so Mystery 2 remains distinct from the manual drift exercise.

1. Record successful `admin-01` → `target-01` SSH and target HTTP/HTTPS baseline tests.
2. In only the provider being tested, temporarily remove the private route table's `0.0.0.0/0` NAT route:
   - AWS: remove the `route` block from `aws_route_table.private` that references `aws_nat_gateway.main`.
   - OCI: remove only the CIDR default `route_rules` block from `oci_core_route_table.private`; retain the `SERVICE_CIDR_BLOCK` rule.
3. Review the Terraform plan. It should alter the existing private route table, not create another gateway or subnet.
4. Apply in the disposable lab environment.
5. Give the learner only the symptom that internal SSH still works but Internet HTTP/HTTPS from `target-01` fails.

### Rollback

Restore the exact NAT default-route block from the repository baseline, review and apply the Terraform plan, then repeat both the Internet test and the internal SSH control.

## Expected behavior

```text
admin-01 (10.0.1.0/24)
    -> provider-local route
    -> target-01 (10.0.2.0/24)

target-01
    -> private subnet default route 0.0.0.0/0
    -> NAT Gateway
    -> Internet
```

The Terraform security controls permit target-initiated TCP/80 and TCP/443. ICMP Internet access is not the declared baseline and should not replace an HTTP/HTTPS test.

## Actual behavior

Populate after reproduction:

| Test | Actual result | Evidence |
| --- | --- | --- |
| `admin-01` → `target-01` TCP/22 | _Populate_ | _Populate_ |
| `target-01` → Internet TCP/80 | _Populate_ | _Populate_ |
| `target-01` → Internet TCP/443 | _Populate_ | _Populate_ |
| DNS lookup from `target-01` | _Populate_ | _Populate_ |

## Initial hypotheses

1. The private subnet is associated with the wrong route table.
2. Its route table lacks the NAT default route or points to the wrong gateway.
3. The NAT Gateway is not available or lacks its required public path.
4. Target egress or a subnet/host firewall blocks the requested port.
5. DNS fails while IP connectivity remains healthy.
6. The remote endpoint is unavailable, creating a false local-network symptom.
7. The return path is invalid or asymmetric.

## Investigation

On `target-01`, separate route, DNS, and port tests:

```bash
ip -brief address
ip route
ip route get <known-internet-ip>
getent ahostsv4 example.com
curl -4 -v --connect-timeout 5 http://example.com/
curl -4 -v --connect-timeout 5 https://example.com/
tracepath example.com
```

Inspect the exact private-subnet association.

AWS:

```bash
aws ec2 describe-route-tables \
  --region <aws-region> \
  --filters "Name=association.subnet-id,Values=<private-subnet-id>"

aws ec2 describe-nat-gateways \
  --region <aws-region> \
  --nat-gateway-ids <nat-gateway-id>
```

Confirm that the NAT Gateway is in the public subnet, has an Elastic IP, and can reach the Internet Gateway through the public subnet's route table.

OCI:

```bash
oci network subnet get --subnet-id <private-subnet-ocid>
oci network route-table get --rt-id <private-route-table-ocid>
oci network nat-gateway get --nat-gateway-id <nat-gateway-ocid>
```

Confirm that the subnet references the intended route table, its `0.0.0.0/0` rule targets the NAT Gateway, and `block_traffic` has not disabled that gateway.

For both providers, compare the effective target egress policy with the exact protocol/port being tested. On OCI, include the default security list; on AWS, include applicable Security Groups and network ACL behavior.

## Evidence to collect

- Known-good internal SSH command and result.
- Target interface and host route table.
- Private subnet ID and actual route-table association.
- Default-route target and NAT Gateway state.
- Target egress rules and host firewall.
- Separate DNS, TCP/80, and TCP/443 results.
- Packet capture if needed to distinguish no egress from no reply.

## Root cause

_Populate only after one hypothesis explains the evidence._

## Fix

_Populate after diagnosis. Do not create a second NAT Gateway or route table merely because the existing path fails._

## Validation after fix

Repeat the same failed HTTP/HTTPS command from `target-01`, then verify the internal SSH control still works. Record the observed public source only if obtained from a real endpoint, and do not hard-code it into this guide.

## What makes this mystery misleading

Internal routing and Internet routing share the source instance but diverge at the cloud route table. The successful internal path is useful evidence, not proof that all networking is healthy.

## Provider-specific notes

- AWS NAT Gateway is located in the public subnet and requires an Elastic IP and Internet Gateway path.
- OCI NAT Gateway is attached to the VCN and referenced directly by the private route rule.
- OCI Service Gateway success, if separately observed, would not prove the NAT path; that is Mystery 4.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-02/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is a missing `0.0.0.0/0` route in the private route table. Provider-local routing still carries `admin-01` → `target-01`, but target Internet destinations have no usable cloud default path to the NAT Gateway.

The intended fix is to restore the original NAT route in the existing private route table. Recreating the instances or NAT Gateway is not justified because the association and gateway can be shown to exist.

</details>
