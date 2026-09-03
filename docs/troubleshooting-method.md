# Troubleshooting Method

## First principle: investigate before recreation

Do not immediately destroy and recreate infrastructure when connectivity fails. Recreation removes evidence, can hide an association or state problem, and teaches little about the failed layer. A useful investigation identifies the exact source, destination, protocol, port, path, and first point where observed behavior differs from the known-good baseline.

Values written as `<placeholder>` in commands must be replaced with observations from the environment before execution. They are intentionally not guessed in this repository.

Use this loop:

```text
Define the failed flow
        |
        v
Confirm current state and preserve evidence
        |
        v
Compare with a nearby working flow
        |
        v
Form one falsifiable hypothesis
        |
        v
Run the smallest discriminating test
        |
        +---- hypothesis rejected ----> form the next hypothesis
        |
        `---- hypothesis supported ---> apply the smallest fix
                                             |
                                             v
                                    repeat the original test
                                             |
                                             v
                                     document the evidence
```

## 1. Define the flow precisely

Replace “the network is down” with a concrete tuple:

| Field | Question |
| --- | --- |
| Source | Which host, Pod, interface, namespace, and source IP initiates the connection? |
| Destination | Which hostname or IP is used? What does the hostname resolve to? |
| Protocol | ICMP, TCP, UDP, or something else? |
| Port | Which destination port? Is a source port assumption relevant? |
| Expected path | Local subnet, Internet Gateway, NAT Gateway, OCI Service Gateway, Kubernetes Service, or another path? |
| Expected result | Connect, timeout, reject, DNS answer, HTTP response, or policy denial? |
| Last known good | When did this exact flow last work, and what changed since? |

Test from the real failing source. A successful connection from `admin-01` does not prove that another source is authorized. A successful Pod-IP request does not prove that the Service selector is correct.

## 2. Preserve state before changing it

Record timestamps and collect read-only state first:

```bash
date --iso-8601=seconds
git status --short
terraform -chdir=terraform/aws state list
terraform -chdir=terraform/oci state list
kubectl config current-context
kubectl get all -n netdebug -o wide
```

Use only the provider directory being investigated. If a command fails because credentials or cluster access are unavailable, record that as a tooling/control-plane problem rather than interpreting it as a packet-path failure.

Do not include secrets in captured output. Store useful sanitized evidence under `docs/evidence/`.

## 3. Walk the path layer by layer

### Step 1: Does the resource exist?

Check desired state and current provider state separately.

```bash
terraform -chdir=terraform/aws validate
terraform -chdir=terraform/aws plan -refresh-only
terraform -chdir=terraform/aws state list

terraform -chdir=terraform/oci validate
terraform -chdir=terraform/oci plan -refresh-only
terraform -chdir=terraform/oci state list
```

Why it matters: configuration text, Terraform state, and remote objects can disagree. A route table in configuration is irrelevant if it was never applied; a remote object can exist but be unmanaged or associated with the wrong subnet.

Useful provider checks:

```bash
# AWS: fill in values from the environment being investigated.
NETDEBUG_AWS_REGION="<aws-region>"
NETDEBUG_AWS_VPC_ID="<vpc-id>"

aws ec2 describe-instances --region "$NETDEBUG_AWS_REGION"
aws ec2 describe-route-tables \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=vpc-id,Values=$NETDEBUG_AWS_VPC_ID"
aws ec2 describe-security-groups \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=vpc-id,Values=$NETDEBUG_AWS_VPC_ID"
aws ec2 describe-nat-gateways \
  --region "$NETDEBUG_AWS_REGION" \
  --filter "Name=vpc-id,Values=$NETDEBUG_AWS_VPC_ID"
```

```bash
# OCI: fill in values from the environment being investigated.
NETDEBUG_OCI_COMPARTMENT_ID="<compartment-ocid>"
NETDEBUG_OCI_VCN_ID="<vcn-ocid>"

oci compute instance list --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID"
oci network subnet list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID"
oci network route-table list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID"
oci network nsg list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID"
oci network nat-gateway list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID"
oci network service-gateway list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID"
```

### Step 2: Is the interface up?

On the source and destination Linux hosts:

```bash
ip -brief link
ip -brief address
```

Why it matters: a correct cloud route cannot compensate for a down interface or an address missing from the guest. Confirm the interface state rather than assuming that a running VM means networking is configured.

### Step 3: Does the resource have the expected IP?

```bash
ip -brief address
hostname -I
```

Compare the guest address with the provider API and the addressing plan:

- `admin-01` should have a private address from `10.0.1.0/24` and a provider-side public address.
- `target-01` should have a private address from `10.0.2.0/24` and no public address.
- Instance IPs are assigned at runtime; do not use addresses from the legacy diagram as evidence.

For Kubernetes:

```bash
kubectl get pods -n netdebug -o wide
kubectl get service netdebug-service -n netdebug -o wide
```

Identify whether an address is a node IP, Pod IP, or Service ClusterIP. These have different routing and policy behavior.

### Step 4: Is Layer 3 reachability plausible?

Use the kernel's route decision before sending packets:

```bash
ip route
ip route get <destination-ip>
ip neigh
```

Then test cautiously:

```bash
ping -c 3 <destination-ip>
tracepath <destination-ip>
# If tracepath is unavailable:
traceroute <destination-ip>
```

Why it matters: `ip route get` identifies the selected interface, next hop, and source address. `ip neigh` helps diagnose directly connected next-hop resolution. `ping` tests ICMP only; it can fail while TCP works or succeed while TCP/22 is blocked. Traces can contain silent hops because many routers do not return TTL-expired messages.

For the private cloud path, the provider-local route should cover traffic between `10.0.1.0/24` and `10.0.2.0/24`. Internet traffic from `target-01` should select its default route, after which the cloud private route table should select the NAT Gateway.

### Step 5: Is the cloud route correct and associated?

Inspect both route content and association.

AWS:

```bash
NETDEBUG_AWS_SUBNET_ID="<subnet-id>"

aws ec2 describe-route-tables \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=association.subnet-id,Values=$NETDEBUG_AWS_SUBNET_ID" \
  --output json
```

OCI:

```bash
NETDEBUG_OCI_SUBNET_ID="<subnet-ocid>"

oci network subnet get --subnet-id "$NETDEBUG_OCI_SUBNET_ID"
```

Take the returned OCI `route-table-id` and inspect it:

```bash
NETDEBUG_OCI_ROUTE_TABLE_ID="<route-table-ocid>"
oci network route-table get --rt-id "$NETDEBUG_OCI_ROUTE_TABLE_ID"
```

Why it matters: a correct route table that is attached to another subnet does not affect the failing packet. A gateway that exists but is not the target of the selected route is not in the path.

Expected routes in this repository:

- AWS public subnet: `0.0.0.0/0` to the Internet Gateway.
- AWS private subnet: `0.0.0.0/0` to the NAT Gateway.
- OCI public subnet: `0.0.0.0/0` to the Internet Gateway.
- OCI private subnet: `0.0.0.0/0` to the NAT Gateway and the selected OCI service CIDR to the Service Gateway.

### Step 6: Is DNS working independently?

```bash
cat /etc/resolv.conf
getent ahosts <hostname>
dig A <hostname>
dig AAAA <hostname>
resolvectl status
```

If `dig` or `resolvectl` is unavailable, record that rather than installing tools in the middle of evidence collection without noting the change.

Why it matters: a name-based connection includes a DNS dependency that an IP-based connection does not. Compare:

```bash
curl -v --connect-timeout 5 http://<known-reachable-ip>/
curl -v --connect-timeout 5 http://<hostname>/
```

Use a destination that is valid for the environment and protocol. HTTPS tests by IP can fail certificate validation even when TCP connectivity is healthy, so do not label a certificate-name error as a routing failure.

### Step 7: Is the destination port reachable?

From the failing source:

```bash
nc -vz -w 5 <destination> <port>
curl -v --connect-timeout 5 http://<destination>:<port>/
ssh -vvv -o ConnectTimeout=5 <user>@<destination>
```

Interpret the symptom:

| Symptom | What it suggests, not proves |
| --- | --- |
| Immediate connection refused | Destination reachable, but nothing accepts the port or a firewall actively rejects it |
| Timeout | Packet drop, missing route/return path, silent firewall/policy, or an unresponsive destination |
| SSH authentication failure | TCP/22 and SSH negotiation work; investigate user/key/authentication rather than the route |
| HTTP 4xx/5xx | TCP and HTTP reached an application endpoint; investigate application/authentication separately |
| DNS error before connection | Resolver path or record problem; no destination-port test occurred |

### Step 8: Is the service listening correctly?

On the destination:

```bash
ss -lntup
ss -lntp '( sport = :22 )'
systemctl status sshd --no-pager
journalctl -u sshd --since '-15 minutes' --no-pager
```

For another service, replace the unit and port. Also inspect host firewall state where applicable:

```bash
sudo nft list ruleset
sudo firewall-cmd --list-all
```

Why it matters: an allowed cloud port does not start a process. A process bound only to `127.0.0.1` is unavailable on the instance's private IP even if every cloud rule is correct.

### Step 9: Are cloud security rules correct?

Verify both directions conceptually:

1. The source is permitted to send the requested protocol/port.
2. The destination permits that exact source identity and destination port.
3. The rule is attached to the actual interface/resource in the path.
4. Any subnet-level control is also accounted for.

AWS uses stateful Security Groups. OCI NSG rules in this repository are stateful because `stateless = false`. OCI subnets also use the VCN default security list, and rules from the security list and NSG are additive. The AWS configuration declares no custom network ACL, but the VPC still has provider-created default resources that should be inspected if observed behavior disagrees with the declared Security Groups.

Do not temporarily allow all traffic as the first test. Prefer a narrowly scoped rule only after evidence identifies the security layer, and record the before/after rule.

### Step 10: Is the return path valid?

Connection state does not eliminate routing requirements. The destination must return traffic toward the source through a valid path, and middleboxes must see a flow they can associate with the original connection.

Check:

```bash
ip route get <source-ip>
sudo tcpdump -ni any host <peer-ip>
```

Capture only what is needed and note that `tcpdump` may expose payload data. Typical packet evidence:

- SYN leaves source, nothing arrives at destination: inspect route, gateway, and intermediate policy.
- SYN arrives, no SYN-ACK leaves: inspect listening process and destination firewall.
- SYN-ACK leaves destination, never returns to source: inspect return routing or asymmetric filtering.
- Full handshake followed by application error: the basic network path works.

## 4. Kubernetes decision flow

Kubernetes adds indirection. Follow the chain rather than recreating the Deployment:

```text
Client name/IP
    |
    v
Service exists in expected namespace?
    |
    v
Service port and targetPort correct?
    |
    v
Selector matches Pod labels?
    |
    v
EndpointSlice contains ready Pod IPs?
    |
    v
Pod process listens on targetPort?
    |
    v
NetworkPolicy permits actual source?
    |
    v
CNI/node/cloud path carries the packet?
```

### Resource and namespace

```bash
kubectl config current-context
kubectl get namespace netdebug
kubectl get deployment netdebug-app -n netdebug -o yaml
kubectl get pods -n netdebug -o wide --show-labels
kubectl get service netdebug-service -n netdebug -o yaml
```

Why it matters: the same name in another namespace is a different object. Always include `-n netdebug` during this lab.

### Labels and selector

```bash
kubectl get service netdebug-service -n netdebug \
  -o jsonpath='{.spec.selector}{"\n"}'
kubectl get pods -n netdebug -l app=netdebug-app --show-labels
```

Expected configuration: the Service selector is `app=netdebug-app`, and the Deployment template applies that label. A Service with no matching Pods can exist normally but has no application endpoints.

### EndpointSlice

```bash
kubectl get endpointslice -n netdebug \
  -l kubernetes.io/service-name=netdebug-service -o yaml
```

Why it matters: EndpointSlices connect the Service abstraction to ready backend addresses. Empty endpoints usually point to label, selector, readiness, or namespace problems. Populated endpoints narrow the investigation toward ports, process state, policy, or data-plane routing.

### Service port and targetPort

```bash
kubectl describe service netdebug-service -n netdebug
kubectl get service netdebug-service -n netdebug \
  -o jsonpath='{range .spec.ports[*]}port={.port} targetPort={.targetPort} protocol={.protocol}{"\n"}{end}'
```

The repository expects TCP Service port 80 and targetPort 80. The Service `port` is what the client uses; `targetPort` is where the selected Pod must listen.

### Pod health and listening service

```bash
kubectl get pods -n netdebug -l app=netdebug-app
kubectl describe pod -n netdebug -l app=netdebug-app
kubectl logs -n netdebug -l app=netdebug-app --tail=100
```

The raw Deployment does not declare readiness or liveness probes. A Pod being Ready therefore does not replace an explicit HTTP connectivity test.

### NetworkPolicy

```bash
kubectl get networkpolicy -n netdebug
kubectl describe networkpolicy allow-approved-client -n netdebug
kubectl get pods -n netdebug --show-labels
```

Ask:

- Does the policy select the destination Pod with `app=netdebug-app`?
- Is the source Pod in the same namespace?
- Does the source Pod have `access=allowed`?
- Does the CNI enforce NetworkPolicy?
- Is another ingress or egress policy also involved?

The checked-in policy has only a source `podSelector`; it does not allow identically labeled Pods from other namespaces. It has no egress policy and no port restriction. There is no approved-client Pod in the repository.

### Helm-generated state

```bash
helm lint helm/oci-netdebug
helm template netdebug helm/oci-netdebug
helm get values <release-name> -n netdebug
helm get manifest <release-name> -n netdebug
```

Compare three states:

1. Chart templates and default values in Git.
2. Values and manifest stored for the installed Helm release.
3. Live Kubernetes objects returned by `kubectl get ... -o yaml`.

Why it matters: a valid chart can render an incorrect selector or target port after an override. Debug the rendered object that Kubernetes received, not just the template source.

## 5. Use working paths to eliminate layers

Examples:

- If `admin-01` reaches `target-01` but `target-01` cannot reach the Internet, the target interface and some internal routing are working. Focus on default routing, NAT, outbound policy, DNS, and remote service behavior.
- If an Internet IP works but a hostname fails, preserve the IP test and inspect DNS before changing the NAT route.
- If one TCP port works to the same IP but another fails, common IP routing is less likely; compare per-port security, firewall, and listener state.
- If Pod IP works but Service DNS/IP fails, inspect Service fields, EndpointSlices, and cluster DNS/data plane.
- If a Service worked before a Helm upgrade, compare release values and rendered manifests before rolling back or recreating Pods.

A working comparison reduces the search space only when source, destination, and path differences are stated explicitly.

## 6. Keep a hypothesis log

For each step, write:

```text
Hypothesis:
Evidence already available:
Test:
Expected result if the hypothesis is true:
Observed result:
Conclusion: supported / weakened / inconclusive
Next smallest test:
```

Avoid stacking unrelated changes. If the result changes after three simultaneous edits, the root cause remains unproven.

## 7. Fix and verify

After identifying the failing layer:

1. Save the pre-fix evidence.
2. Apply the smallest change that addresses the proven cause.
3. Repeat the exact original failing command from the same source.
4. Repeat a nearby working control test to detect regressions.
5. Run `terraform plan` if cloud configuration was changed and inspect remaining drift.
6. Capture post-fix provider, Linux, or Kubernetes state.
7. Complete a report using `docs/mystery-template.md`.

Recreation is justified only when evidence proves the resource itself is irrecoverable or replacement is the intended minimal fix. “It might clear the problem” is not evidence.
