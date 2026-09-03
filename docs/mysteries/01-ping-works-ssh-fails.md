# Mystery 1 — Ping Works, SSH Fails

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: AWS or OCI.

## Scenario

From the intended source, basic ICMP reachability to a compute instance works, but an SSH connection to the same destination fails.

The scenario is deliberately misleading: `ping` and SSH do not test the same protocol, port, security rule, or process. A reply to ICMP proves only part of Layer 3 reachability and ICMP handling.

## Reproducible setup

Use the private `admin-01` → `target-01` path so the public administration entry point remains available for recovery.

1. Establish and record a working SSH baseline from `admin-01` to `target-01`.
2. Confirm ICMP echo is permitted from only the admin Security Group/NSG to the target. The repository does not declare this rule, so add it as a clearly named temporary test-harness rule and record it. Do not allow ICMP from `0.0.0.0/0`.
3. Confirm that `ping <target-private-ip>` works from `admin-01`.
4. Temporarily remove the target's SSH ingress resource from the selected provider configuration:
   - AWS: `aws_vpc_security_group_ingress_rule.target_allow_ssh_from_admin`
   - OCI: `oci_core_network_security_group_security_rule.target_allow_ssh_from_admin`
5. Review the Terraform plan and apply only in the disposable lab environment.
6. Give the learner only the symptom: ping works, but a new SSH connection fails.

Keep an existing session open or retain provider-console access. The mystery must not remove the laptop → `admin-01` recovery path.

### Rollback

Restore the removed SSH ingress resource, review and apply the plan, verify a new SSH connection, then remove the temporary ICMP test-harness rule if it is not part of the desired baseline.

## Expected behavior

For the repository's intended administration path:

```text
Laptop -> admin-01 public IP -> TCP/22 -> sshd
admin-01 -> target-01 private IP -> TCP/22 -> sshd
```

SSH should succeed only when the relevant known-good baseline has been established, the source matches the declared security rule, the route and return path are valid, `sshd` listens on a reachable address, the host firewall permits the port, and authentication is valid.

## Actual behavior

Populate when the mystery is staged:

| Test | Actual result | Evidence |
| --- | --- | --- |
| ICMP test | _Populate_ | _Populate_ |
| TCP/22 connection | _Populate_ | _Populate_ |
| SSH negotiation/authentication | _Populate_ | _Populate_ |

Classify the SSH failure as timeout, refusal, host-key problem, negotiation failure, or authentication failure. Those are different symptoms.

## Initial hypotheses

These are candidates, not conclusions:

1. TCP/22 is missing from or excluded by the effective AWS Security Group, OCI NSG, OCI security list, or host firewall.
2. `sshd` is stopped or failed.
3. `sshd` listens only on loopback or another address/port.
4. The source differs from the source allowed by `allowed_ssh_cidr` or the admin-to-target group reference.
5. TCP routing or the return path differs from the ICMP path.
6. TCP succeeds but the username, key, file permissions, or SSH policy rejects authentication.

## Investigation

Run from the failing source:

```bash
ping -c 3 <destination-ip>
ip route get <destination-ip>
nc -vz -w 5 <destination-ip> 22
ssh -vvv -o ConnectTimeout=5 <user>@<destination-ip>
```

On the destination, using another valid management path if SSH itself is unavailable:

```bash
ip -brief address
ip route
ss -lntp '( sport = :22 )'
systemctl status sshd --no-pager
journalctl -u sshd --since '-15 minutes' --no-pager
sudo nft list ruleset
sudo firewall-cmd --list-all
```

Inspect the applicable provider controls:

```bash
# AWS
aws ec2 describe-security-groups \
  --region <aws-region> \
  --group-ids <security-group-id>

# OCI
oci network nsg rules list --nsg-id <nsg-ocid>
oci network security-list get --security-list-id <security-list-ocid>
```

Compare the source actually observed by the destination with the rule source. Do not add `0.0.0.0/0` merely to see whether SSH starts working.

## Evidence to collect

- Exact source and destination IPs.
- `ping`, TCP/22, and `ssh -vvv` results with timestamps.
- Source route decision and destination return route.
- Effective cloud rules and their resource attachment.
- Listener address/port and `sshd` service state.
- Relevant firewall and SSH logs.

## Root cause

_Populate only after the failing layer is proven._

## Fix

_Populate with the smallest corrective change after diagnosis._

## Validation after fix

Repeat the original SSH command from the same source. Also repeat the ICMP control and verify that no broader security exposure was introduced.

| Check | Expected | Actual | Evidence |
| --- | --- | --- | --- |
| Original SSH flow | TCP/22 and SSH complete as intended | _Populate_ | _Populate_ |
| Unauthorized source | Remains denied | _Populate_ | _Populate_ |

## What makes this mystery misleading

A working network-layer signal is easy to overgeneralize. ICMP reachability does not demonstrate a TCP listener, a TCP/22 security rule, or valid SSH credentials.

## Provider-specific notes

- AWS Security Groups are stateful.
- OCI NSG rules used by this project are stateful, but the subnet's default security list also contributes to effective policy.
- Neither provider's declared instance-level rules should be inferred from a `ping` result alone.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-01/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is the missing target ingress rule for TCP/22. The narrow ICMP rule remains, so the provider-local route and ICMP path work while new SSH connections are dropped by the target Security Group/NSG.

The intended diagnosis is protocol-specific cloud security, not a broken route or failed `sshd`. The learner should prove that TCP/22 does not reach the target and that the expected target ingress rule is absent. The minimal fix is to restore only the original admin-group-to-target-group TCP/22 rule and verify that no broader ingress was introduced.

</details>
