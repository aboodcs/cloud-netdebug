# Evidence for Mystery 05 — Port Allowed, Service Unavailable

> Evidence status: not executed. This directory contains collection instructions only.

Related guide: [`05-port-allowed-service-unavailable.md`](../../mysteries/05-port-allowed-service-unavailable.md)

The cloud SSH rule remains present while `sshd` is stopped temporarily on `target-01`. Keep a separate recovery path and record it before staging the fault.

## Required captures

- Provider, timestamp, source and destination, and confirmed recovery method.
- Successful baseline TCP/22 and SSH results from `admin-01`.
- Target cloud ingress rule for TCP/22.
- `sshd` status and listening socket before the change.
- The scheduled automatic recovery unit.
- TCP/22, verbose SSH, `ss`, service status, and relevant logs during the fault.
- Service and client results after rollback.

## Command checklist

From `admin-01`:

```bash
date --iso-8601=seconds
nc -vz -w 5 <target-private-ip> 22
ssh -vvv -o ConnectTimeout=10 <target-user>@<target-private-ip>
```

From the preserved `target-01` session:

```bash
sudo ss -lntp '( sport = :22 )'
sudo systemctl status sshd --no-pager
sudo systemctl status netdebug-m5-rollback.timer --no-pager
sudo journalctl -u sshd --since '<exercise-start-time>' --no-pager
```

Capture the provider rule represented by `aws_vpc_security_group_ingress_rule.target_allow_ssh_from_admin` or `oci_core_network_security_group_security_rule.target_allow_ssh_from_admin`. Do not include private keys or authentication secrets.
