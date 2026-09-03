# Multi-Cloud NetDebug Lab

This repository is a networking troubleshooting lab with separate Terraform implementations for AWS and Oracle Cloud Infrastructure (OCI). It uses the same core learning flow across both providers: plan the network, establish a known-good Linux baseline, introduce controlled failures, collect evidence, identify the failing layer, and apply the smallest reasonable fix.

```text
Multi-Cloud NetDebug Lab
├── AWS implementation
│   └── terraform/aws/
├── OCI implementation
│   └── terraform/oci/
├── Kubernetes workload
├── Helm packaging
└── Networking troubleshooting mysteries
```

## Provider implementations

Both Terraform implementations declare a public `admin-01` virtual machine and a private `target-01` virtual machine, public and private subnets, route tables, controlled SSH access, an Internet Gateway, and outbound Internet access for the private subnet through a NAT Gateway.

| Concept | AWS | OCI |
| --- | --- | --- |
| Cloud network | VPC | VCN |
| Compute | EC2 instance | Compute instance |
| Public Internet gateway | Internet Gateway | Internet Gateway |
| Private outbound Internet | NAT Gateway in a public subnet | NAT Gateway attached to the VCN |
| Instance-level network security | Security Group | Network Security Group (NSG) |
| Routing | VPC route tables and subnet associations | VCN route tables assigned to subnets |

The providers are not treated as identical. The OCI implementation also includes a Service Gateway and a service-CIDR route for private access to the Oracle Services Network. The AWS implementation does not currently define VPC endpoints; AWS endpoint options are service-specific and are not a direct one-for-one replacement for OCI Service Gateway behavior.

## Shared lab layers

- `terraform/aws/` contains the AWS VPC and EC2 implementation.
- `terraform/oci/` contains the OCI VCN and Compute implementation.
- `kubernetes/` contains the provider-neutral Kubernetes workload and NetworkPolicy.
- `helm/oci-netdebug/` packages that workload as a reusable Helm chart.
- `docs/mysteries/` is reserved for evidence-based troubleshooting reports.
- `TASKS.md` preserves the full learning sequence and report requirements.

The Kubernetes, Helm, Linux, traffic-analysis, and troubleshooting exercises are provider-neutral unless a task explicitly identifies a provider-specific network path. The `oci-netdebug` Helm directory and chart name are retained as legacy identifiers; they do not limit the Kubernetes workload to OCI.

## Troubleshooting method

Every mystery follows the same discipline: observe the symptom, compare working and failing paths, form and test a hypothesis, collect evidence, identify the root cause, make a minimal fix, verify the result, and document what was learned. The task list is a roadmap; unchecked tasks and report placeholders are not claims that an exercise has already been completed.
