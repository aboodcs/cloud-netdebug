# Mystery 3 — IP Works, DNS Fails

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: provider-neutral.

## Scenario

An outbound connection to a known IP succeeds, while access using a hostname fails. The scenario isolates name resolution from basic IP routing.

## Reproducible setup

Stage a host-local DNS-only failure on `target-01`. Use the firewall implementation actually installed on the selected image; the example below uses `nftables`.

1. Record a baseline DNS lookup and HTTP request by hostname.
2. Record a working HTTP request to a verified IP endpoint so the later control uses the same destination and protocol.
3. Keep the current administration session open and schedule an automatic rollback before adding rules.
4. Add a temporary output chain that rejects only new UDP/TCP destination port 53 traffic:

```bash
sudo nft add table inet netdebug_m3
sudo nft 'add chain inet netdebug_m3 output { type filter hook output priority -5; policy accept; }'
sudo nft add rule inet netdebug_m3 output udp dport 53 reject
sudo nft add rule inet netdebug_m3 output tcp dport 53 reject

sudo systemd-run --unit netdebug-m3-rollback --on-active=10m \
  /bin/sh -c 'nft delete table inet netdebug_m3'
```

5. Confirm only the expected temporary rules exist with `sudo nft list table inet netdebug_m3`.
6. Give the learner the IP-works/name-fails symptom without revealing the host firewall change.

If `nft` or `systemd-run` is unavailable, do not improvise an unbounded firewall change. Document an equivalent reversible mechanism for that image before staging the mystery.

### Rollback

```bash
sudo nft delete table inet netdebug_m3
```

The scheduled rollback is a safety fallback. After manual rollback, its later failure to find the already deleted table is harmless and should be recorded if it appears in system logs.

## Expected behavior

`target-01` should use its configured resolver to translate a hostname into an address, then use the private subnet's NAT path for public HTTP/HTTPS traffic. Kubernetes clients add cluster DNS as another resolver layer.

```text
Application
   -> system or cluster resolver
   -> destination IP
   -> route/security/NAT or Kubernetes data plane
   -> destination service
```

## Actual behavior

Populate after reproduction:

| Test | Actual result | Evidence |
| --- | --- | --- |
| Connection to a verified IP endpoint | _Populate_ | _Populate_ |
| `getent` lookup | _Populate_ | _Populate_ |
| `dig` lookup | _Populate_ | _Populate_ |
| Application request by hostname | _Populate_ | _Populate_ |

Use an IP test appropriate to the application. A direct HTTPS request to an IP can fail certificate hostname validation even when networking works.

## Initial hypotheses

1. `/etc/resolv.conf` points to an unavailable or incorrect resolver.
2. The local resolver service is stopped or unhealthy.
3. DNS traffic is blocked while HTTP/HTTPS remains allowed.
4. The requested DNS record does not exist or returns an unexpected address family.
5. Search-domain or `ndots` behavior changes the query.
6. In Kubernetes, CoreDNS, its Service, or the Pod DNS configuration is unhealthy.
7. The application uses a proxy, cache, or resolver path different from the command-line test.

## Investigation

On the failing Linux source:

```bash
cat /etc/resolv.conf
getent ahosts <hostname>
dig A <hostname>
dig AAAA <hostname>
resolvectl status
ip route
ss -lunp
```

Query the configured resolver directly if its address is known from actual configuration:

```bash
dig @<resolver-ip> <hostname> A
```

Compare IP and hostname behavior with the same application protocol:

```bash
curl -v --connect-timeout 5 http://<verified-ip-endpoint>/
curl -v --connect-timeout 5 http://<hostname>/
```

For Kubernetes:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
kubectl get service -n kube-system kube-dns -o wide
kubectl get endpointslice -n kube-system \
  -l kubernetes.io/service-name=kube-dns -o wide
kubectl exec -n <namespace> <client-pod> -- cat /etc/resolv.conf
kubectl exec -n <namespace> <client-pod> -- getent hosts <service-name>
```

Use an existing client Pod or document any temporary test Pod created. The repository itself does not declare the cluster DNS implementation or its addresses.

## Evidence to collect

- Exact hostname and expected record type.
- Resolver configuration and resolver address.
- `getent` and `dig` output with timestamps.
- A comparable successful IP test.
- Route to the resolver and any DNS-specific policy.
- Kubernetes CoreDNS Service/endpoints and Pod resolver file when applicable.

## Root cause

_Populate after the failing resolver component or policy is proven._

## Fix

_Populate after diagnosis. Do not change the NAT route when the evidence isolates DNS._

## Validation after fix

Repeat the original hostname command and the direct DNS query. Keep the previously working IP test as a control.

## What makes this mystery misleading

Applications describe name-resolution failures as connectivity failures. The working IP path proves that some routing and security layers work, but it says nothing about the resolver path or correctness of the DNS record.

## Provider-specific notes

- AWS enables VPC DNS support and hostnames in `aws_vpc.main`.
- OCI gives the VCN and subnets DNS labels, but runtime resolver behavior still must be inspected.
- The repository does not declare Kubernetes cluster DNS settings.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-03/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is a host output firewall rule rejecting DNS on UDP/TCP 53. Existing IP routing, NAT, and HTTP/HTTPS policy remain unchanged, so an IP-based control can work while resolver queries fail.

The learner should identify the configured resolver, observe DNS failure, preserve the successful IP control, and inspect the local firewall before changing cloud routes. The minimal fix is deletion of the temporary `netdebug_m3` table.

</details>
