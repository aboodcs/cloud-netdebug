# Mystery 6 — One Port Works, Another Fails

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: provider-neutral.

## Scenario

Two connections use the same source and destination IP, but one TCP port works and another fails.

The working connection is a control. It strongly suggests that the common address and at least part of the common route are valid. The investigation should focus on what differs by port without declaring the entire network healthy.

## Reproducible setup

Use outbound Internet access from `target-01`, with HTTP TCP/80 as the working control and HTTPS TCP/443 as the failing comparison.

1. Select one external service that is known to respond on both HTTP and HTTPS, and record both successful baseline requests from `target-01`.
2. Temporarily remove only the public HTTPS egress resource from the provider configuration:
   - AWS: `aws_vpc_security_group_egress_rule.target_allow_https`
   - OCI: `oci_core_network_security_group_security_rule.target_allow_https_to_internet`
3. On OCI, retain `target_allow_https_to_oci_services`; it targets the OCI service CIDR and is not the public Internet rule.
4. Review and apply the Terraform plan in the disposable lab.
5. Give the learner the symptom that HTTP to the recorded endpoint works while HTTPS to the same hostname fails.

Use the same source and hostname for both tests. Confirm the hostname resolves to comparable addresses so DNS or endpoint differences do not invalidate the control.

### Rollback

Restore the removed HTTPS egress resource, review and apply Terraform, then repeat both the HTTP and HTTPS requests.

## Expected behavior

Define the two tested services before starting:

| Flow | Source | Destination | Port | Expected result |
| --- | --- | --- | --- | --- |
| Working control | _Populate_ | _Populate_ | _Populate_ | Allowed and listening |
| Failing comparison | _Populate_ | _Populate_ | _Populate_ | Allowed and listening before the mystery |

The repository already provides useful port distinctions: SSH uses TCP/22, target outbound HTTP uses TCP/80, target outbound HTTPS uses TCP/443, and the Kubernetes Service uses TCP/80.

## Actual behavior

| Test | Actual result | Evidence |
| --- | --- | --- |
| Control port | _Populate_ | _Populate_ |
| Failing port | _Populate_ | _Populate_ |

Record whether the failing port times out, refuses, completes TLS, or returns an application error.

## Initial hypotheses

1. A cloud or Kubernetes policy allows one destination port but not the other.
2. The host firewall treats the ports differently.
3. Only one service is running.
4. The failing service listens on loopback, another interface, or another port.
5. A Kubernetes Service `targetPort` differs from the container listener.
6. The two names resolve to different destination addresses despite appearing to target one host.
7. An application protocol or TLS failure is being mistaken for a TCP failure.

## Investigation

Keep source and destination constant:

```bash
ip route get <destination-ip>
nc -vz -w 5 <destination-ip> <working-port>
nc -vz -w 5 <destination-ip> <failing-port>
curl -v --connect-timeout 5 http://<destination-ip>:<working-port>/
curl -v --connect-timeout 5 http://<destination-ip>:<failing-port>/
```

On the destination:

```bash
ss -lntup
systemctl status <working-service> --no-pager
systemctl status <failing-service> --no-pager
sudo nft list ruleset
sudo firewall-cmd --list-all
```

Compare provider rules by protocol, port, source, and attachment. If Kubernetes is involved, compare:

```bash
kubectl get service netdebug-service -n netdebug -o yaml
kubectl get endpointslice -n netdebug \
  -l kubernetes.io/service-name=netdebug-service -o yaml
kubectl get networkpolicy -n netdebug -o yaml
```

Do not change the common route merely because one port fails. First explain why the same route carries the control port.

## Evidence to collect

- Exact source/destination address pair for both tests.
- Side-by-side connection output.
- Side-by-side cloud/firewall port rules.
- Listener and service state for both ports.
- Service `port` and `targetPort` when Kubernetes is involved.
- DNS answers if different names are used.

## Root cause

_Populate after the port-specific difference is identified._

## Fix

_Populate with a port- or service-specific correction after diagnosis._

## Validation after fix

Repeat both tests. The previously working control must remain working, and the previously failing port must now produce its expected result.

## What makes this mystery misleading

“Same server” encourages broad changes, but per-port policy and listeners are independent. The working port is valuable evidence that common routing is less likely to be the failing layer.

## Provider-specific notes

The method is the same across AWS Security Groups, OCI NSGs/security lists, Linux firewalls, and Kubernetes NetworkPolicy. The syntax differs, but every comparison must preserve the same source and destination while isolating the port difference.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-06/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is the missing target egress rule for public TCP/443. TCP/80 still uses the same instance, default route, and NAT Gateway successfully, which makes general IP routing a weaker hypothesis.

The learner should compare the two egress rules and show that no public HTTPS authorization remains. The minimal fix is to restore only the original TCP/443 egress resource. On OCI, the separate service-CIDR HTTPS rule must not be mistaken for general `0.0.0.0/0` HTTPS permission.

</details>
