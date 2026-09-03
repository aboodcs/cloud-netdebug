# What This Lab Teaches

This is a learning summary of the concepts encoded by the repository. It does not claim that every task or mystery has been executed. Results belong in the baseline and mystery reports after they are observed.

## Addressing and subnets

An IP address is meaningful only with its prefix and routing context. Both cloud implementations divide `10.0.0.0/16` into a public `10.0.1.0/24` subnet and a private `10.0.2.0/24` subnet. The names communicate intent, but routes and address assignment create the behavior.

The design reinforces several practical points:

- Subnet CIDRs must fit inside the cloud-network CIDR and must not overlap.
- A public subnet needs a route to an Internet Gateway; an instance also needs a public address and an allowed ingress path.
- A private instance can initiate Internet traffic through NAT without accepting unsolicited Internet connections.
- Provider-assigned instance IPs are runtime data. Diagrams should not be treated as address inventory.
- Reusing `10.0.0.0/16` in AWS and OCI is acceptable while the environments are isolated, but it prevents straightforward routing between them later.
- Kubernetes Pod and Service addresses belong to cluster networking and cannot be derived from the AWS/OCI subnet plan in this repository.

## Routing is a selection problem

Creating a gateway does not put it in a packet path. The source host chooses an interface and next hop, then the subnet's associated route table selects the next cloud network entity. The most useful questions are therefore:

1. Which source address and interface did the kernel select?
2. Which route table is associated with the source subnet?
3. Which route is the best match for the destination?
4. Is the route target available?
5. Can the destination return traffic to the observed source?

`ip route get <destination>` answers the host-side decision. Provider APIs answer the subnet association and gateway decision. Both are needed.

AWS expresses subnet-to-route-table relationships with explicit association resources in this project. OCI assigns `route_table_id` on each subnet. The concept is shared, but the configuration shape is not identical.

## Public access, NAT, and gateways

The Internet Gateway is used for the public subnet's default route. `admin-01` is the controlled public entry point. It is not public merely because it is placed in `10.0.1.0/24`; it also requests a public address and needs TCP/22 allowed from `allowed_ssh_cidr`.

The private subnet's `0.0.0.0/0` route points to a NAT Gateway. `target-01` can initiate allowed HTTP/HTTPS traffic, while the NAT design does not provide a general unsolicited inbound path.

The provider implementations differ:

- AWS places the NAT Gateway in the public subnet and associates an Elastic IP with it.
- OCI attaches the NAT Gateway to the VCN rather than placing it in a subnet.
- OCI also provides a Service Gateway. The private OCI route table sends the selected Oracle Services Network service CIDR to that gateway.
- The AWS configuration contains no VPC endpoints. AWS gateway/interface endpoints are service-specific and should not be described as a direct replacement for the OCI Service Gateway.

## Security is separate from routing

A route says where a packet should go. It does not authorize the packet. Conversely, an allowed security rule is ineffective if no route reaches the destination.

The declared pattern is deliberately narrow:

- Laptop to `admin-01`: inbound TCP/22 from `allowed_ssh_cidr`.
- `admin-01` to `target-01`: outbound and inbound TCP/22 using Security Group/NSG references.
- `target-01` to the Internet: outbound TCP/80 and TCP/443.
- `target-01` to OCI services: an additional OCI service-CIDR TCP/443 rule.

AWS Security Groups are stateful. The OCI NSG rules in this project are also stateful because they set `stateless = false`. Reply traffic for an allowed flow is handled as connection state, but that does not authorize a new reverse-direction connection.

Effective policy can include more than the obvious instance control. OCI subnets in this repository retain the VCN default security list, whose rules combine with the NSGs. AWS has provider-created network ACL behavior even though no custom ACL resource is declared. A good diagnosis inspects every applicable control instead of assuming that one named group is the entire policy.

## Linux networking and service availability

Cloud configuration ends at the virtual interface. Linux still has to choose the correct route and run a process on the expected port.

Useful checks answer distinct questions:

- `ip a` or `ip -brief address`: which addresses are present?
- `ip route`: what routes exist?
- `ip route get <destination>`: which source, interface, and next hop will be selected?
- `ip neigh`: can directly connected neighbors be resolved?
- `ping`: does ICMP receive a reply? This says nothing conclusive about TCP.
- `getent` and `dig`: does name resolution work, and through which resolver?
- `ss -lntup`: is a process listening on the intended address, protocol, and port?
- `curl -v`, `nc`, and `ssh -vvv`: how far does an application connection progress?
- `systemctl` and `journalctl`: is the service running, and what did it report?

“Port allowed” and “service available” are different claims. A Security Group or NSG can allow TCP/80 while the process is stopped, bound to loopback, listening on another port, rejected by the host firewall, or returning an application error.

## DNS is its own dependency

An IP-based test and a hostname-based test do not exercise the same path. If an IP works but a name fails, changing the NAT route without inspecting the resolver destroys a useful distinction.

A DNS investigation records:

- `/etc/resolv.conf` and, where applicable, `resolvectl status`.
- `getent` results, because applications commonly use the system resolver path.
- `dig` results for direct DNS visibility.
- The resolved address family and destination addresses.
- Whether TCP/UDP 53 or provider-resolver behavior is affected by policy.

An HTTPS request made directly to an IP can fail hostname/certificate validation even when the packet path is healthy. Error classification matters.

## Terraform as desired-state evidence

Terraform configuration, state, and remote provider state answer different questions:

- Configuration says what the repository intends.
- State records what Terraform associates with that configuration.
- A refresh or provider CLI query reports what currently exists remotely.
- A plan explains the proposed reconciliation between those views.

For troubleshooting, `terraform validate`, `terraform state list`, `terraform show`, and `terraform plan -refresh-only` are evidence tools. An unexpected plan can reveal manual drift, changed inputs, or missing remote resources. Applying immediately may erase the comparison needed to understand the problem.

The AWS and OCI directories are separate Terraform root modules. Success or state in one directory says nothing about the other. The AWS module declares address outputs; the OCI `outputs.tf` is currently empty, so OCI runtime addresses require another inspection method.

## Kubernetes networking

Kubernetes introduces names and virtual addresses between the client and process:

```text
Client Pod
   -> Service DNS / ClusterIP:80
   -> Service selector app=netdebug-app
   -> EndpointSlice ready Pod IPs
   -> container TCP/80
```

Each link can fail independently.

### Labels and selectors

The `netdebug-app` Deployment gives Pods `app=netdebug-app`. The `netdebug-service` Service selects that label. A selector typo does not stop the Service object from existing; it produces no matching endpoints.

Labels are data used by controllers and policy. Similar-looking names do not create a relationship unless selectors match the exact key/value pairs.

### Services and EndpointSlices

The Service is `ClusterIP`, exposes TCP/80, and forwards to targetPort 80. It is internal to the cluster because no NodePort, LoadBalancer, or Ingress is declared.

EndpointSlices show which ready backend addresses Kubernetes associated with the Service. They provide a decisive branch in an investigation:

- Empty EndpointSlice: inspect selector, labels, namespace, and Pod readiness.
- Populated EndpointSlice: inspect target port, listening process, NetworkPolicy, and CNI/service data plane.

A Service is not a process that originates a separate connection. It is a routing/load-balancing abstraction that delivers the client's connection to a backend Pod.

### NetworkPolicy

`allow-approved-client` selects Pods with `app=netdebug-app` and isolates their ingress. It allows sources with `access=allowed` in the same namespace. It declares no egress policy and no allowed-port restriction.

The lesson is not merely to read the policy name. Verify:

- Which destination Pods the policy selects.
- Which source identity the ingress rule matches.
- Whether a `namespaceSelector` is present.
- Whether another policy also applies.
- Whether the cluster CNI enforces NetworkPolicy.

No approved-client Pod is checked into the repository, so allowed and denied behavior must be tested with a documented runtime client.

## Helm and generated configuration

Helm adds another desired-state layer. The chart can render valid YAML that is semantically wrong for the intended traffic. Troubleshooting therefore compares:

1. Default values and templates in Git.
2. Values stored for the installed release.
3. The manifest Helm rendered.
4. The live Kubernetes object.

In this chart, namespace creation, image, replicas, labels, Service port/targetPort/type, and NetworkPolicy are configurable. A value change to a label, selector, or target port can produce a networking symptom even when Kubernetes itself behaves correctly.

The chart's `oci-netdebug` name is historical. Its resources use standard Kubernetes APIs and do not encode an OCI-specific cluster dependency.

## Practical troubleshooting discipline

The durable method is:

1. Define one exact failing flow.
2. Preserve current state and compare it with the baseline.
3. Find a nearby working flow and list what differs.
4. Form one hypothesis that a small test can reject.
5. Test at the real source and destination.
6. Separate resource existence, association, routing, policy, process, and application behavior.
7. Check the return path.
8. Apply the smallest fix only after the failed layer is identified.
9. Repeat the original test and a control test.
10. Store sanitized evidence and explain why the evidence supports the conclusion.

Recreating everything can make a symptom disappear while leaving the cause unknown. The engineering goal is not merely to restore traffic; it is to know which layer owned the failure and why.
