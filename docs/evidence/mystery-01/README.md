# Evidence for Mystery 01 — Ping Works, SSH Fails

> Evidence status: not executed. This directory contains collection instructions only.

Related guide: [`01-ping-works-ssh-fails.md`](../../mysteries/01-ping-works-ssh-fails.md)

Collect evidence from `admin-01` to the private address of `target-01`. The evidence must show the same source and destination for both ICMP and TCP/22 tests.

## Required captures

- Provider, region, timestamp, and sanitized instance identifiers.
- Known-good ping and SSH results before the fault is introduced.
- The Terraform plan used to remove only the target SSH ingress rule.
- Ping, TCP/22, and verbose SSH results while the fault is active.
- Target listener and service state from an existing recovery session.
- Cloud security-rule state before and after rollback.
- Repeated ping and SSH results after rollback.

## Command checklist

Run the client-side commands on `admin-01`:

```bash
date --iso-8601=seconds
hostname
ip route get <target-private-ip>
ping -c 4 <target-private-ip>
nc -vz -w 5 <target-private-ip> 22
ssh -vvv -o ConnectTimeout=10 <target-user>@<target-private-ip>
```

Run these through the already-open recovery session on `target-01`:

```bash
sudo ss -lntp '( sport = :22 )'
sudo systemctl status sshd --no-pager
```

Record the relevant Terraform resource:

- AWS: `aws_vpc_security_group_ingress_rule.target_allow_ssh_from_admin`
- OCI: `oci_core_network_security_group_security_rule.target_allow_ssh_from_admin`

Suggested filenames use `YYYY-MM-DD-<provider>-<phase>.txt`, where `<phase>` is `baseline`, `fault`, or `rollback`. Do not add an empty phase file or a successful result that was not observed.
