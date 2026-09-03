# Addressing Plan

## Source of the values

The AWS and OCI Terraform implementations use the same default IPv4 plan. The values come from `terraform/aws/variables.tf` and `terraform/oci/variables.tf`; neither example variable file overrides the network CIDRs.

| Purpose | AWS variable | OCI variable | Configured CIDR |
| --- | --- | --- | --- |
| Cloud network | `vpc_cidr` | `cidr_blocks` | `10.0.0.0/16` |
| Public subnet | `public_subnet_cidr` | `public_subnet_cidr` | `10.0.1.0/24` |
| Private subnet | `private_subnet_cidr` | `private_subnet_cidr` | `10.0.2.0/24` |

The OCI VCN variable is a list and currently contains one block: `10.0.0.0/16`. The repository declares IPv4 only.

## Allocation strategy

```text
10.0.0.0/16 cloud network
|
+-- 10.0.1.0/24 public subnet
|   `-- admin-01 and, on AWS, the NAT Gateway
|
`-- 10.0.2.0/24 private subnet
    `-- target-01
```

The two `/24` subnets do not overlap and both fit inside `10.0.0.0/16`. The rest of the `/16` is not assigned by the current Terraform and remains available for deliberate future planning.

Using the same CIDRs in two isolated cloud environments makes the exercises easier to compare. It also means the AWS VPC and OCI VCN cannot be routed directly to each other without addressing overlap. The repository declares no cross-cloud peering, VPN, transit gateway, dynamic routing gateway, or other connection between them. If cross-cloud connectivity is added later, one side must be renumbered or an explicit translation design must be introduced.

## Public subnet

The public subnet is `10.0.1.0/24` in each provider.

### AWS

- `aws_subnet.public` enables `map_public_ip_on_launch`.
- `aws_instance.admin_01` explicitly requests a public IP.
- `aws_nat_gateway.main` is also placed in this subnet and uses `aws_eip.nat`.
- `aws_route_table.public` sends `0.0.0.0/0` to `aws_internet_gateway.main`.

### OCI

- `oci_core_subnet.public` sets `prohibit_public_ip_on_vnic = false`.
- `oci_core_instance.admin_01` explicitly requests a public IP on its VNIC.
- `oci_core_route_table.public` sends `0.0.0.0/0` to `oci_core_internet_gateway.main`.
- The OCI NAT Gateway is attached to the VCN; it is not placed in the public subnet as an AWS NAT Gateway is.

`admin-01` receives a provider-assigned private address from this subnet and a provider-assigned public address. Terraform does not fix either instance address. Do not copy the example `.10` addresses from the legacy root architecture image into test records.

## Private subnet

The private subnet is `10.0.2.0/24` in each provider.

### AWS

- `aws_subnet.private` disables automatic public IP assignment.
- `aws_instance.target_01` explicitly sets `associate_public_ip_address = false`.
- `aws_route_table.private` sends `0.0.0.0/0` to `aws_nat_gateway.main`.

### OCI

- `oci_core_subnet.private` prohibits public IPs on VNICs.
- `oci_core_instance.target_01` explicitly sets `assign_public_ip = false`.
- `oci_core_route_table.private` sends `0.0.0.0/0` to the OCI NAT Gateway.
- A more-specific OCI service-CIDR route sends supported Oracle Services Network traffic to the OCI Service Gateway.

`target-01` receives only a provider-assigned private address. The AWS configuration exposes that address through the `target_private_ip` Terraform output. `terraform/oci/outputs.tf` is currently empty, so the OCI private address must be obtained from Terraform state or OCI runtime inspection.

## Public and private are path properties

A subnet is not operationally public merely because it has “public” in its name. Public inbound connectivity requires all of the following:

1. A public IP on the destination interface.
2. A subnet route that reaches an Internet Gateway.
3. Security rules permitting the flow.
4. A valid return path.
5. A host process listening on the expected address and port.

Likewise, a private subnet does not gain outbound Internet access merely because a NAT Gateway exists. The correct route table must be associated with the subnet, the NAT Gateway must be usable, egress must be allowed, DNS must work when names are used, and the destination service must respond.

## Kubernetes addressing

The repository does not configure a Kubernetes cluster, CNI, Pod CIDR, or Service CIDR. The manifests request a `ClusterIP` Service but do not set `clusterIP`, so Kubernetes allocates it at runtime. Pod IPs are also allocated at runtime by the cluster network.

Record actual values after deployment rather than guessing:

```bash
kubectl get nodes -o custom-columns='NAME:.metadata.name,POD_CIDR:.spec.podCIDR'
kubectl get pods -n netdebug -o wide
kubectl get service netdebug-service -n netdebug -o wide
kubectl get endpointslice -n netdebug \
  -l kubernetes.io/service-name=netdebug-service -o wide
```

Some cluster implementations do not expose the complete cluster CIDR through these fields. If so, record the cluster configuration or CNI output used to confirm it and leave the value marked unknown until then.

| Kubernetes range | Repository value | Runtime observation |
| --- | --- | --- |
| Node subnet/CIDR | Not declared | _Populate after cluster inspection_ |
| Pod CIDR | Not declared | _Populate after cluster inspection_ |
| Service CIDR | Not declared | _Populate after cluster inspection_ |
| `netdebug-service` ClusterIP | Allocated dynamically | _Populate after deployment_ |

### Recorded local minikube snapshot

The point-in-time evidence in `docs/evidence/baseline/2026-09-03-kubernetes.md` records these runtime values:

| Field | Observed value |
| --- | --- |
| Kubernetes context | `minikube` |
| Node internal IP | `192.168.49.2` |
| Node `.spec.podCIDR` | `10.244.0.0/24` |
| Calico IPPool | `10.244.0.0/16` |
| API server Service CIDR | `10.96.0.0/12` |
| `netdebug-service` ClusterIP | `10.98.133.36` |
| Observed application Pod IPs | `10.244.120.68`, `10.244.120.69` |

These values belong to that local cluster snapshot, not to the AWS VPC or OCI VCN Terraform configuration. Re-query them after recreating or reconfiguring minikube.

## Why this matters during troubleshooting

CIDR knowledge answers routing and source-identity questions before packet tests begin:

- Is the destination local to the cloud network or reached through a default route?
- Does a security rule reference the correct source range?
- Are AWS and OCI ranges overlapping if a future cross-cloud path is attempted?
- Is a Kubernetes address a Pod IP, Service IP, node IP, or cloud-subnet IP?
- Is the return route valid for the address that the destination actually sees?

Always record the observed source and destination addresses with a test. “The network looks correct” is not useful evidence without the address pair and route decision.
