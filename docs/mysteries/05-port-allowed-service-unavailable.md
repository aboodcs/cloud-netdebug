# Mystery 5 — Port Allowed, Service Unavailable

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: AWS or OCI; the same reasoning also applies to a Kubernetes backend.

## Scenario

Cloud routing and the intended Security Group or NSG rule appear to allow a destination port, but the service does not return the expected response.

“Allowed by cloud policy” is only one condition. The destination host must receive the packet, its host firewall must allow it, a process must listen on the correct address and port, and the application must handle the request.

## Reproducible setup

Use SSH on `target-01` because TCP/22 is already represented by the repository's cloud controls.

1. Record a working `admin-01` → `target-01` SSH connection.
2. Verify the target ingress rule and `ss -lntp '( sport = :22 )'` before injecting the fault.
3. Keep the current target session open and schedule service recovery before stopping `sshd`:

```bash
sudo systemd-run --unit netdebug-m5-rollback --on-active=10m \
  /bin/systemctl start sshd
sudo systemctl stop sshd
```

4. Do not close the existing session. From `admin-01`, attempt a new SSH connection to the target.
5. Give the learner the symptom that cloud TCP/22 policy is present but new SSH connections are unavailable.

Stopping `sshd` normally leaves an already established interactive session alive, but this must not be the only recovery mechanism. Confirm provider-console or serial-console recovery is available before staging.

### Rollback

```bash
sudo systemctl start sshd
sudo systemctl is-active sshd
```

The scheduled transient unit provides a fallback if the manual recovery is not performed first.

## Expected behavior

```text
Client
  -> route
  -> cloud security control
  -> destination interface
  -> host firewall
  -> listening socket
  -> application response
```

For SSH in this repository, the expected destination port is TCP/22. For the Kubernetes nginx workload, the Service and container path use TCP/80.

## Actual behavior

Populate after reproduction:

| Test | Actual result | Evidence |
| --- | --- | --- |
| Cloud rule inspection | _Populate_ | _Populate_ |
| TCP connection test | _Populate_ | _Populate_ |
| Local listener inspection | _Populate_ | _Populate_ |
| Local application request | _Populate_ | _Populate_ |
| Remote application request | _Populate_ | _Populate_ |

## Initial hypotheses

1. The rule exists but is attached to a different instance/VNIC or references the wrong source.
2. The service is stopped, failed, or repeatedly restarting.
3. The service listens on another port.
4. The service binds only to `127.0.0.1` or another interface.
5. The host firewall drops or rejects the connection.
6. The application accepts TCP but returns an application-level error.
7. In Kubernetes, Service `targetPort`, selector, EndpointSlice, or NetworkPolicy is wrong.

## Investigation

From the real client:

```bash
ip route get <destination-ip>
nc -vz -w 5 <destination-ip> <port>
curl -v --connect-timeout 5 http://<destination-ip>:<port>/
```

On the destination host:

```bash
ip -brief address
ss -lntup
ss -lntp '( sport = :<port> )'
systemctl status <service-unit> --no-pager
journalctl -u <service-unit> --since '-15 minutes' --no-pager
sudo nft list ruleset
sudo firewall-cmd --list-all
curl -v http://127.0.0.1:<port>/
curl -v http://<destination-private-ip>:<port>/
```

If Kubernetes is involved:

```bash
kubectl get pods -n netdebug -o wide --show-labels
kubectl describe service netdebug-service -n netdebug
kubectl get endpointslice -n netdebug \
  -l kubernetes.io/service-name=netdebug-service -o wide
kubectl describe networkpolicy allow-approved-client -n netdebug
kubectl logs -n netdebug -l app=netdebug-app --tail=100
```

Use `tcpdump` at the destination only when needed:

```bash
sudo tcpdump -ni any tcp port <port>
```

Packets arriving without a listener response move the investigation beyond the cloud route. No packets arriving means the earlier path still needs attention.

## Evidence to collect

- The exact rule and its attachment.
- TCP result: timeout, refusal, handshake, or application response.
- Listener address, port, and owning process.
- Service state and relevant logs.
- Host firewall rules.
- Kubernetes selector/endpoints/targetPort if applicable.
- Packet capture limited to the relevant peer and port if required.

## Root cause

_Populate after the failed layer is proven._

## Fix

_Populate after diagnosis. Do not broaden cloud ingress if the process is stopped or bound incorrectly._

## Validation after fix

Repeat both the local application request and the original remote request. Verify that unauthorized sources and ports remain denied.

## What makes this mystery misleading

The visible cloud rule can be correct while the endpoint remains unavailable. Security authorization does not create a listener or validate application behavior.

## Provider-specific notes

- AWS Security Groups and the OCI NSG rules used here are stateful.
- OCI's default security list is also part of effective policy.
- Kubernetes NetworkPolicy controls Pod traffic separately from cloud instance controls.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-05/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is a stopped `sshd` service on `target-01`. Cloud route and TCP/22 authorization remain unchanged. Depending on the host and firewall behavior, a new connection should be refused or otherwise fail because no SSH listener accepts it.

The learner should show that packets can reach the host or that the cloud rules are unchanged, then use `ss`, `systemctl`, and `journalctl` to identify the missing listener. The minimal fix is to start `sshd`, not broaden the Security Group/NSG.

</details>
