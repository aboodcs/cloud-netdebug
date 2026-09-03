# Mystery 9 — Works from One Source, Fails from Another

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: AWS or OCI.

## Scenario

`admin-01` can reach `target-01`, while another source cannot reach the same target and port.

The destination alone does not define a flow. Different sources can have different addresses, routes, gateways, security identities, NAT behavior, and return paths. A successful connection from one source must not be generalized to all sources.

## Reproducible setup

This mystery uses the repository's intended access boundaries and requires no fault injection.

1. Record the actual private address of `target-01` and the public/private addresses of `admin-01`.
2. From `admin-01`, record a successful SSH connection to the target's private address.
3. From the operator laptop, attempt SSH directly to that same target private address without ProxyJump.
4. Record the laptop route decision for the target private address and the absence of a target public address.
5. Give the learner only the two source-dependent results and ask whether the failed source is supposed to have a valid route and authorization.

If the laptop has a VPN or local route for `10.0.0.0/16`, document it before the exercise; the lab uses that CIDR in both providers, so local overlap can change the observed failure mode. The designed repository still declares no laptop-to-private-subnet VPN or peering path.

### Cleanup

No infrastructure change is required. End any diagnostic sessions and remove no security controls. The correct operational access remains SSH through `admin-01`, for example with ProxyJump.

## Expected behavior

The declared administrative flow is:

```text
admin-01 security identity
    -> provider-local route
    -> target security identity
    -> TCP/22 on target-01
```

AWS permits target SSH ingress from `admin_sg`; OCI permits it from `admin_nsg`. A different source is expected to work only if it has a valid route and is explicitly included by the effective controls. Direct Internet access to `target-01` is not supported because it has no public IP.

## Actual behavior

Populate after defining the second source:

| Field | Working source | Failing source |
| --- | --- | --- |
| Host/resource | `admin-01` | _Populate_ |
| Source IP seen by destination | _Populate_ | _Populate_ |
| Security Group/NSG identity | _Populate_ | _Populate_ |
| Route/path | _Populate_ | _Populate_ |
| Protocol/port result | _Populate_ | _Populate_ |
| Evidence | _Populate_ | _Populate_ |

## Initial hypotheses

1. The destination rule references the admin Security Group/NSG, not the failing source.
2. The failing source uses another source IP because of NAT, a proxy, or a different interface.
3. The failing source lacks a route to the private target or has an invalid return path.
4. A host firewall or service policy treats the two sources differently.
5. One test uses a public destination and the other a private destination.
6. DNS gives the sources different destination addresses.
7. The working test uses an established stateful connection while the failing test initiates a new connection.

## Investigation

Run the same test from both sources and preserve all variables:

```bash
getent ahosts <target-name>
ip route get <target-ip>
nc -vz -w 5 <target-ip> <port>
ssh -vvv -o ConnectTimeout=5 <user>@<target-ip>
```

On `target-01`, observe connection attempts and listener state:

```bash
ss -lntp
sudo tcpdump -ni any tcp port <port>
journalctl -u sshd --since '-15 minutes' --no-pager
```

Inspect provider identity and rules:

```bash
# AWS
aws ec2 describe-instances \
  --region <aws-region> \
  --instance-ids <source-instance-id> <target-instance-id>
aws ec2 describe-security-groups \
  --region <aws-region> \
  --group-ids <source-sg-id> <target-sg-id>

# OCI
oci network vnic get --vnic-id <source-vnic-ocid>
oci network vnic get --vnic-id <target-vnic-ocid>
oci network nsg rules list --nsg-id <target-nsg-ocid>
```

For OCI, also inspect the default security list. For AWS, inspect any applicable network ACL when provider observations disagree with Security Group expectations.

Do not “fix” the test by making `target-01` public. First decide whether the second source is intended to be authorized at all.

## Evidence to collect

- Exact identity and IP of each source.
- Exact destination address, protocol, and port.
- Route decision from each source.
- Target's observed source address, if packets arrive.
- Security Group/NSG membership and effective rules.
- Return route from target to each source.
- Side-by-side command output with timestamps.

## Root cause

_Populate only after the source-dependent difference is proven._

## Fix

_Populate only if the failing source is supposed to be allowed. Scope the correction to the intended source and port._

## Validation after fix

Repeat the same command from both sources. Confirm the intended source now works and an unrelated unauthorized source remains denied.

## What makes this mystery misleading

The same destination and port encourage destination-only reasoning. Security policy and return routing evaluate the complete flow, including source identity and the path that produced it.

## Provider-specific notes

- AWS rules can reference another Security Group; this authorizes network interfaces associated with that group under AWS rule semantics, not a hostname.
- OCI NSG rules can reference another NSG; the subnet default security list remains additive.
- Stateful reply traffic belongs to an existing connection and does not prove that the reverse source can initiate a new one.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-09/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed condition and intended diagnosis</summary>

`admin-01` works because it has provider-local routing to the private subnet and its Security Group/NSG identity is explicitly authorized by the target rule. The laptop's direct attempt fails because `target-01` has no public IP, the repository declares no routed private connection from the laptop, and target SSH ingress references the admin security identity rather than the laptop.

This is an intended denial, not a defect requiring broader ingress. The learner should use the supported bastion/ProxyJump path and document why changing `target-01` to public would violate the design.

</details>
