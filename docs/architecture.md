# Architecture

## Purpose and source of truth

Multi-Cloud NetDebug is one troubleshooting lab with parallel infrastructure implementations for AWS and Oracle Cloud Infrastructure (OCI). Both implementations create the same logical exercise: a public administration host, a private target host, controlled network paths, and enough separation to diagnose routing, security, DNS, and service failures. Kubernetes and Helm add a provider-neutral application-networking layer.

This document describes resources declared in:

- `terraform/aws/`
- `terraform/oci/`
- `kubernetes/`
- `helm/oci-netdebug/`

It describes desired configuration, not proof of a successful deployment. Runtime addresses, health, and connectivity must be recorded in `docs/baseline.md` after validation.

The root `architecture.png` is a legacy OCI-only illustration. It contains example instance IP addresses and shows Kubernetes inside OCI, neither of which is fixed by the current repository configuration. Treat any locally generated files under `terraform/*/netpath-output/` as disposable views and verify them against the current code. Use the Terraform and Kubernetes source files, plus this document, as the current architecture source of truth.

## Shared logical design

```text
Operator laptop
     |
     | Internet, TCP/22 from allowed_ssh_cidr
     v
Cloud Internet Gateway
     |
Public subnet: 10.0.1.0/24
     |
     +-- admin-01
     |     - public IP: requested
     |     - private IP: provider-assigned
     |     - role: SSH entry point / troubleshooting host
     |
     +-- AWS NAT Gateway and Elastic IP (AWS implementation only)
            |
            | private-subnet default route
            v
Private subnet: 10.0.2.0/24
     |
     +-- target-01
           - public IP: disabled
           - private IP: provider-assigned
           - role: private troubleshooting target
           |
           +-- TCP/80 and TCP/443 --> NAT Gateway --> Internet
           +-- TCP/443 --> OCI Service Gateway --> OCI services (OCI only)
```

The public and private subnets are inside `10.0.0.0/16` in both implementations. Internal traffic uses the provider's implicit local route. Public ingress requires more than a public-subnet label: the route, public IP, security control, host firewall, and listening process must all agree.

## AWS architecture

The AWS implementation is under `terraform/aws/` and uses Amazon Linux 2 EC2 instances.

```text
AWS VPC: aws_vpc.main (10.0.0.0/16)
|
+-- aws_internet_gateway.main
|
+-- Public subnet: aws_subnet.public (10.0.1.0/24)
|   +-- map_public_ip_on_launch = true
|   +-- aws_instance.admin_01
|   |   +-- public IP requested explicitly
|   |   `-- aws_security_group.admin_sg
|   `-- aws_nat_gateway.main
|       `-- aws_eip.nat
|
+-- Private subnet: aws_subnet.private (10.0.2.0/24)
|   +-- map_public_ip_on_launch = false
|   `-- aws_instance.target_01
|       +-- no public IP
|       `-- aws_security_group.target_sg
|
+-- aws_route_table.public
|   `-- 0.0.0.0/0 -> aws_internet_gateway.main
|
`-- aws_route_table.private
    `-- 0.0.0.0/0 -> aws_nat_gateway.main
```

Explicit route-table association resources attach the public route table to `aws_subnet.public` and the private route table to `aws_subnet.private`. The NAT Gateway is in the public subnet and depends on the Internet Gateway. Its Elastic IP supplies the public source address for private-subnet outbound traffic.

With the default `project_name`, externally visible resource names and tags use the `aws-netdebug` prefix. The EC2 Name tags become `aws-netdebug-admin-01` and `aws-netdebug-target-01`; the logical Terraform addresses remain `aws_instance.admin_01` and `aws_instance.target_01`.

### AWS security controls

- `admin_sg` allows inbound TCP/22 from `allowed_ssh_cidr`.
- `admin_sg` allows outbound TCP/22 to `target_sg`.
- `target_sg` allows inbound TCP/22 from `admin_sg`.
- `target_sg` allows outbound TCP/80 and TCP/443 to `0.0.0.0/0`.
- The Terraform configuration does not create custom network ACL rules or VPC endpoints.

AWS Security Groups are stateful, so reply traffic for an allowed connection does not require a separate reverse-direction rule. That does not authorize `target-01` to initiate a new SSH connection to `admin-01`.

## OCI architecture

The OCI implementation is under `terraform/oci/` and uses Oracle Linux Compute instances in the first availability domain returned for the configured compartment.

```text
OCI VCN: oci_core_vcn.main (10.0.0.0/16)
|
+-- oci_core_internet_gateway.main
+-- oci_core_nat_gateway.main
+-- oci_core_service_gateway.service_gateway
|
+-- Public subnet: oci_core_subnet.public (10.0.1.0/24)
|   +-- public IPs permitted
|   `-- oci_core_instance.admin_01
|       +-- public IP requested explicitly
|       `-- oci_core_network_security_group.admin_nsg
|
+-- Private subnet: oci_core_subnet.private (10.0.2.0/24)
|   +-- public IPs prohibited
|   `-- oci_core_instance.target_01
|       +-- no public IP
|       `-- oci_core_network_security_group.target_nsg
|
+-- oci_core_route_table.public
|   `-- 0.0.0.0/0 -> Internet Gateway
|
`-- oci_core_route_table.private
    +-- OCI service CIDR -> Service Gateway
    `-- 0.0.0.0/0 -> NAT Gateway
```

The OCI route tables are assigned directly through each subnet's `route_table_id`. The more-specific service-CIDR rule sends supported Oracle Services Network traffic through the Service Gateway; general Internet traffic uses the NAT Gateway. The Service Gateway is an OCI-specific feature in this repository. No AWS VPC endpoint resources are declared.

With the default `project_name`, OCI display names use the `oci-netdebug` prefix. The instances are `oci-netdebug-admin-01` and `oci-netdebug-target-01`.

### OCI security controls

- `admin_nsg` allows stateful inbound TCP/22 from `allowed_ssh_cidr`.
- `admin_nsg` allows stateful outbound TCP/22 to `target_nsg`.
- `target_nsg` allows stateful inbound TCP/22 from `admin_nsg`.
- `target_nsg` allows stateful outbound TCP/80 and TCP/443 to `0.0.0.0/0`.
- `target_nsg` also allows stateful outbound TCP/443 to the selected OCI service CIDR.

Both subnets explicitly retain the VCN default security list. OCI security lists and NSGs are additive, so troubleshooting must inspect the default security list as well as the NSG rules before claiming that an NSG alone defines the effective policy.

## Role of the two instances

`admin-01` is the controlled public entry point. It is placed in the public subnet, receives both private and public addressing, and is the intended source for SSH to `target-01`. A public IP alone is insufficient: the Internet Gateway route and security rules are also required.

`target-01` is deliberately private. It has no public IP and its subnet does not permit automatic public addressing. It should be reached through `admin-01`, while outbound HTTP/HTTPS follows the private route table to the NAT Gateway. Only reply traffic is automatically covered by stateful rules; a new connection in the reverse direction must have its own authorization.

## Kubernetes and Helm layer

The repository does not declare a managed Kubernetes cluster or attach Kubernetes to either cloud network. Cluster location, node CIDRs, Pod CIDRs, Service CIDRs, ingress controllers, and external load balancers are therefore runtime concerns and must not be inferred from the AWS or OCI subnet CIDRs.

The checked-in workload is provider-neutral:

```text
Namespace: netdebug
|
+-- Deployment: netdebug-app
|   +-- replicas: 2
|   +-- image: nginx:latest
|   `-- Pod label: app=netdebug-app
|
+-- Service: netdebug-service
|   +-- type: ClusterIP
|   +-- TCP/80 -> targetPort 80
|   `-- selector: app=netdebug-app
|
`-- NetworkPolicy: allow-approved-client
    +-- selects: app=netdebug-app
    +-- policy type: Ingress
    `-- allows same-namespace Pods with access=allowed
```

The Service is not externally exposed by the manifests. Kubernetes should create EndpointSlices from ready Pods whose labels match the Service selector. The NetworkPolicy supplies no `namespaceSelector`, so its `podSelector` source matches approved Pods only in the `netdebug` namespace. There is no approved-client Pod manifest in the repository; policy behavior requires a runtime test client and a NetworkPolicy-capable CNI.

The Helm chart at `helm/oci-netdebug/` renders the same logical Namespace, Deployment, Service, and optional NetworkPolicy. Its path and chart name are legacy identifiers; the rendered Kubernetes workload is not OCI-specific.

## Similarities and differences

| Area | Shared design | AWS implementation | OCI implementation |
| --- | --- | --- | --- |
| Cloud network | `10.0.0.0/16` with public/private `/24` subnets | VPC | VCN |
| Public entry | `admin-01` with public and private IPs | EC2 + Security Group | Compute instance + NSG and subnet security list |
| Private target | `target-01` without a public IP | EC2 | Compute instance |
| Public routing | `0.0.0.0/0` through an Internet Gateway | Route-table association resource | Route table assigned on subnet |
| Private Internet | `0.0.0.0/0` through a NAT Gateway | NAT Gateway in public subnet with Elastic IP | NAT Gateway attached to VCN |
| Private provider services | Provider-specific | No VPC endpoints declared | Service CIDR through Service Gateway |
| Security state | Stateful rules used | Security Groups are stateful | NSG rules explicitly set `stateless = false` |

## Troubleshooting boundaries

A failure can occur at several independent layers:

1. Terraform desired state or drift.
2. Cloud resource existence and association.
3. Subnet route table and gateway state.
4. Security Group, NSG, or OCI default security-list rules.
5. Instance addressing, interface state, host route, DNS, or firewall.
6. Process state, listening address, and listening port.
7. Kubernetes labels, selectors, EndpointSlices, ports, namespace, or NetworkPolicy.
8. Helm values that render incorrect Kubernetes state.

The purpose of the architecture is to make those boundaries observable. A working path should be used to eliminate shared components before any resource is recreated.
