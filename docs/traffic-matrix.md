# Traffic Matrix

## How to read this matrix

The matrix records intended behavior from the checked-in configuration. “Expected allowed” means the declared cloud path permits the connection; it is not proof that a deployment or service is healthy. Record actual results and evidence in `docs/baseline.md` before introducing a mystery.

Host firewalls, process state, credentials, provider-managed behavior, and runtime Kubernetes networking can still affect a path after the declared route and security controls are correct.

## Cloud and Linux paths

| Source → destination | Protocol/port | Expected result | Route dependency | Security dependency | Provider-specific notes |
| --- | --- | --- | --- | --- | --- |
| Laptop → `admin-01` | TCP/22 | Allowed only from `allowed_ssh_cidr`, assuming SSH is listening and credentials are valid | Internet → public IP → Internet Gateway → public subnet | AWS `admin_sg` or OCI `admin_nsg` ingress TCP/22 | AWS EC2 and OCI Compute both request a public IP for `admin-01` |
| Laptop → `target-01` | TCP/22 | No direct Internet path | `target-01` has no public IP and is in the private subnet | No direct laptop-to-target rule is declared | Use `admin-01` as the path; do not expose the target merely to simplify testing |
| `admin-01` → `target-01` | TCP/22 | Expected allowed if SSH is listening | Provider-local VPC/VCN routing between `10.0.1.0/24` and `10.0.2.0/24` | Admin egress TCP/22 to target security group/NSG; target ingress TCP/22 from admin security group/NSG | A ProxyJump connection keeps the private key on the laptop |
| `target-01` → Internet | TCP/80, TCP/443 | Expected outbound only | Private route table `0.0.0.0/0` → NAT Gateway; NAT must have a valid public path | Target egress TCP/80 and TCP/443 to `0.0.0.0/0`; replies rely on stateful tracking | AWS NAT uses an Elastic IP in the public subnet; OCI NAT attaches to the VCN |
| `target-01` → DNS resolver | Commonly UDP/TCP 53, provider-dependent | Must be validated separately | Resolver location and host resolver configuration | Effective provider and host rules must permit resolution | The repository enables VPC/VCN DNS behavior but does not record runtime resolver addresses |
| `target-01` → public AWS service endpoint | Usually TCP/443 | Expected through the public NAT path when the selected endpoint is reachable | AWS private route table → NAT Gateway | `target_sg` egress TCP/443 | No AWS VPC endpoint is declared; do not describe this as an OCI-style Service Gateway path |
| `target-01` → supported OCI service endpoint | TCP/443 | Expected through the OCI private service path | More-specific service CIDR → OCI Service Gateway | `target_nsg` egress TCP/443 to the OCI service CIDR, plus effective subnet security-list rules | OCI-specific; verify that the chosen endpoint resolves into the selected Oracle Services Network range |
| `target-01` → `admin-01` as a new SSH connection | TCP/22 | Not allowed by the explicitly declared controls | Provider-local route exists | No target egress/admin ingress pair authorizes a new target-initiated SSH connection | Reply traffic for an admin-initiated stateful SSH session is allowed; a reply is not a new connection |
| Internet → `target-01` | Any | Not directly reachable | No public IP and no inbound translation/load balancer | No public ingress rule | This is a design requirement, not a failure |

The Terraform configurations do not explicitly authorize ICMP in the AWS Security Groups or OCI NSGs. A successful or failed `ping` must therefore be interpreted alongside the effective provider controls, including the OCI default security list. ICMP reachability never proves that TCP/22 or TCP/80 is allowed.

## Kubernetes paths

These paths apply to the resources in the `netdebug` namespace. The cluster placement and CNI are not declared in this repository.

| Source → destination | Protocol/port | Expected result | Data-plane dependency | Policy/selector dependency | Notes |
| --- | --- | --- | --- | --- | --- |
| Approved Pod → `netdebug-app` Pod IP | TCP/80 | Expected allowed | CNI Pod routing | Source Pod must be in `netdebug` with `access=allowed`; destination has `app=netdebug-app` | The policy has no port restriction, but nginx is expected on TCP/80 |
| Unapproved Pod → `netdebug-app` Pod IP | TCP/80 | Expected denied when the CNI enforces NetworkPolicy | CNI Pod routing may be healthy even while policy drops the flow | Destination is ingress-isolated by `allow-approved-client`; source label does not match | No approved-client workload is checked in; use a temporary test Pod and record it as evidence |
| Approved Pod → `netdebug-service` | TCP/80 | Expected allowed | ClusterIP routing/load balancing → EndpointSlice address | Service selector must match `app=netdebug-app`; NetworkPolicy still applies at destination Pods | Service DNS also depends on cluster DNS |
| Pod → Service → Pod | TCP/80 → targetPort 80 | Expected when endpoints are ready | Service proxy/data plane rewrites or routes traffic to a ready endpoint | `port: 80`, `targetPort: 80`, selector `app=netdebug-app` | A Service is not itself a traffic-originating process; the client connection is delivered to a Pod |
| Pod → Pod outside the selected workload | Runtime-specific | Not controlled by this repository's policy unless the destination has `app=netdebug-app` | CNI routing | `allow-approved-client` selects only `netdebug-app` Pods | Inspect all policies in both source and destination namespaces before generalizing |
| Node → Pod | Runtime-specific; TCP/80 for this workload | Must be verified on the chosen cluster | Node routes, CNI, kube-proxy/eBPF implementation, and host firewall | NetworkPolicy handling of node-originated traffic is implementation-sensitive | The repository does not declare the cluster network |
| External client → `netdebug-service` | TCP/80 | Not directly exposed by these manifests | No Ingress, NodePort, LoadBalancer, or external route is declared | Service type is `ClusterIP` | `kubectl port-forward` may be used for a local validation tunnel, but it is not external exposure architecture |

## Runtime record

For each test, add an evidence entry rather than changing this intended matrix:

| Date/time | Provider/cluster | Source address | Destination address/name | Protocol/port | Actual result | Evidence file |
| --- | --- | --- | --- | --- | --- | --- |
| _Populate after testing_ |  |  |  |  |  |  |
