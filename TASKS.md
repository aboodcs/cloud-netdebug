# OCI NetDebug — Project Tasks

Hands-on OCI, Linux, Kubernetes, and Helm networking troubleshooting project.

The project begins with a known-good Oracle Cloud Infrastructure network and gradually introduces realistic failures.

The main rule of the project:

> Do not randomly change configuration. Observe, investigate, prove the root cause, then fix it.

---

# Phase 0 — Architecture & Planning

## Task 0.1 — Design the architecture

* [ ] Draw the complete OCI architecture
* [ ] Include your laptop
* [ ] Include the OCI VCN
* [ ] Include public and private subnets
* [ ] Include `admin-01`
* [ ] Include `target-01`
* [ ] Include Internet Gateway
* [ ] Include NAT Gateway
* [ ] Include Service Gateway
* [ ] Include route tables
* [ ] Include NSGs
* [ ] Show expected traffic paths

Save:

`docs/architecture.md`

### You should understand

* Why two servers are required
* Why `admin-01` is public
* Why `target-01` is private
* Which traffic uses each gateway

---

## Task 0.2 — Design the IP addressing plan

* [ ] Choose VCN CIDR
* [ ] Choose public subnet CIDR
* [ ] Choose private subnet CIDR
* [ ] Verify that subnet CIDRs do not overlap
* [ ] Document expected private address ranges

Save:

`docs/addressing-plan.md`

---

## Task 0.3 — Create the traffic matrix

Define expected behavior for:

* [ ] Laptop → admin-01
* [ ] Laptop → target-01
* [ ] admin-01 → target-01
* [ ] target-01 → admin-01
* [ ] target-01 → Internet
* [ ] target-01 → OCI services
* [ ] Internet → target-01

For each path document:

* source
* destination
* protocol
* port
* expected result
* expected network path

Save:

`docs/traffic-matrix.md`

---

# Phase 1 — Terraform Foundation

## Task 1.1 — Configure Terraform

Files:

* `terraform/versions.tf`
* `terraform/providers.tf`
* `terraform/variables.tf`

Requirements:

* [ ] Define Terraform version requirements
* [ ] Configure OCI provider
* [ ] Define reusable variables
* [ ] Keep credentials outside Git
* [ ] Verify Terraform can initialize successfully

### Definition of Done

Terraform is ready to manage OCI infrastructure, but no infrastructure needs to exist yet.

---

## Task 1.2 — Create the VCN

File:

`terraform/network.tf`

* [ ] Create the VCN
* [ ] Use the CIDR from your addressing plan
* [ ] Configure required DNS behavior
* [ ] Apply meaningful names/tags

### You should understand

* What a VCN represents
* Why CIDR planning matters
* How OCI DNS relates to a VCN

---

## Task 1.3 — Create the public subnet

* [ ] Create the subnet for `admin-01`
* [ ] Associate the correct route configuration
* [ ] Understand why a public subnet does not automatically make every VM publicly reachable

---

## Task 1.4 — Create the private subnet

* [ ] Create the subnet for `target-01`
* [ ] Keep direct Internet exposure disabled
* [ ] Support internal VCN communication
* [ ] Prepare it for outbound connectivity

---

# Phase 2 — OCI Routing & Gateways

## Task 2.1 — Create the Internet Gateway

* [ ] Create an Internet Gateway
* [ ] Connect the public network path correctly
* [ ] Understand which traffic should use it

---

## Task 2.2 — Configure the public route table

* [ ] Create the required route rule
* [ ] Associate the route table with the correct subnet
* [ ] Verify the subnet is actually using the expected route table

### Question you must answer

Why does creating an Internet Gateway alone not provide Internet access?

---

## Task 2.3 — Create the NAT Gateway

Goal:

Allow `target-01` to initiate outbound Internet connections without giving it a public IP.

* [ ] Create the NAT Gateway
* [ ] Determine which route must use it
* [ ] Keep inbound Internet exposure disabled

---

## Task 2.4 — Configure private routing

* [ ] Configure outbound routing for the private subnet
* [ ] Associate the correct route table
* [ ] Verify the route path logically

### You should understand

`NAT Gateway exists` does not mean `private subnet uses NAT Gateway`.

---

## Task 2.5 — Configure the Service Gateway

* [ ] Create the Service Gateway
* [ ] Determine which OCI service traffic should use it
* [ ] Add the required route
* [ ] Verify private OCI service connectivity later

### You must understand

NAT Gateway vs Service Gateway.

---

# Phase 3 — OCI Security

## Task 3.1 — Design security requirements

Before creating rules, determine what must actually be allowed.

Consider:

* [ ] Laptop → admin-01
* [ ] admin-01 → target-01
* [ ] target-01 → Internet
* [ ] target-01 → OCI services
* [ ] target-01 → admin-01

Do not solve everything using unrestricted rules.

---

## Task 3.2 — Create Network Security Groups

File:

`terraform/security.tf`

* [ ] Create security policy for `admin-01`
* [ ] Create security policy for `target-01`
* [ ] Restrict administrative access
* [ ] Configure only required protocols and ports
* [ ] Configure required egress rules

---

## Task 3.3 — Understand OCI security rules

Before continuing, explain:

* ingress
* egress
* source
* destination
* protocol
* port
* stateful vs stateless behavior

---

# Phase 4 — Compute

## Task 4.1 — Create `admin-01`

File:

`terraform/compute.tf`

Requirements:

* [ ] Linux
* [ ] Public subnet
* [ ] Private IP
* [ ] Required public connectivity
* [ ] SSH administration
* [ ] Correct NSG association

---

## Task 4.2 — Create `target-01`

Requirements:

* [ ] Linux
* [ ] Private subnet
* [ ] Private IP only
* [ ] No direct public exposure
* [ ] Reachable from `admin-01`
* [ ] Correct NSG association

---

## Task 4.3 — Terraform outputs

File:

`terraform/outputs.tf`

Output useful operational information.

Do not expose secrets.

---

# Phase 5 — Linux SysAdmin Baseline

## Task 5.1 — Inspect Linux networking

On both machines determine:

* [ ] hostname
* [ ] network interfaces
* [ ] private IP
* [ ] routing table
* [ ] default route
* [ ] DNS configuration
* [ ] running services
* [ ] listening ports

Do not just collect output.

Explain what each piece tells you.

---

## Task 5.2 — Understand SSH

Investigate:

* [ ] SSH client
* [ ] SSH server
* [ ] SSH service state
* [ ] listening port
* [ ] listening interface
* [ ] authentication
* [ ] logs

Understand the complete path:

Laptop/admin → OCI network → security rules → Linux → SSH service

---

## Task 5.3 — Linux service troubleshooting

Learn how to determine:

* [ ] whether a service exists
* [ ] whether it is running
* [ ] whether it failed
* [ ] whether it starts automatically
* [ ] which port it listens on
* [ ] where its logs are

---

## Task 5.4 — Linux network troubleshooting

Be able to answer:

* [ ] Which IP does this machine have?
* [ ] Which default gateway does it use?
* [ ] Which route will traffic use?
* [ ] Which DNS resolver is configured?
* [ ] Which ports are listening?
* [ ] Which processes own those ports?

---

# Phase 6 — Known-Good Baseline

Do not intentionally break anything before this phase passes.

## Task 6.1

Verify:

Laptop → admin-01

---

## Task 6.2

Verify:

admin-01 → target-01

---

## Task 6.3

Verify:

target-01 → admin-01

---

## Task 6.4

Verify:

target-01 → Internet IP

---

## Task 6.5

Verify:

target-01 → Internet hostname

This must test DNS separately from basic connectivity.

---

## Task 6.6

Verify:

target-01 → OCI service

---

## Task 6.7 — Document the baseline

Save:

`docs/baseline.md`

For every test record:

* expected result
* actual result
* protocol
* source
* destination
* evidence

---

# Phase 7 — Troubleshooting Method

## Task 7.1 — Create your troubleshooting checklist

Save:

`docs/troubleshooting-method.md`

Your investigation should consider:

1. Compute resource
2. Subnet
3. Route table
4. Gateway
5. OCI security
6. Linux interface
7. Linux routing
8. DNS
9. Service
10. Protocol

---

## Task 7.2 — Hypothesis-driven troubleshooting

Before changing configuration, write:

> I think _____ is broken.

> My evidence is _____.

> I will test _____.

> If _____ happens, my hypothesis becomes stronger.

> If _____ happens, my hypothesis is probably wrong.

---

# Phase 8 — Mystery 1

## Ping works, SSH fails

Situation:

* [ ] Basic network reachability works
* [ ] SSH fails

Your mission:

Determine which layer caused the failure.

Do not randomly modify OCI rules.

Document:

`docs/mysteries/01-ping-works-ssh-fails.md`

---

# Phase 9 — Mystery 2

## Private network works, Internet fails

Situation:

* [ ] admin-01 → target-01 works
* [ ] target-01 → Internet fails

Use the working internal path as evidence.

Document:

`docs/mysteries/02-private-network-works-internet-fails.md`

---

# Phase 10 — Mystery 3

## IP works, DNS fails

Situation:

* [ ] Internet IP connectivity works
* [ ] Domain-name connectivity fails

Determine why.

Lesson:

Network connectivity and DNS resolution are separate capabilities.

Document:

`docs/mysteries/03-ip-works-dns-fails.md`

---

# Phase 11 — Mystery 4

## OCI service works, Internet fails

Situation:

* [ ] Normal Internet access fails
* [ ] OCI service connectivity works

Compare the two paths.

Explain how both conditions can exist simultaneously.

Document:

`docs/mysteries/04-oci-service-works-internet-fails.md`

---

# Phase 12 — Mystery 5

## Port allowed, service unavailable

OCI networking appears correct.

The destination port still does not provide the expected response.

Determine whether the problem exists in:

* OCI
* Linux networking
* Linux firewall
* service/process
* listening address
* listening port

Document:

`docs/mysteries/05-port-allowed-service-unavailable.md`

---

# Phase 13 — Mystery 6

## One port works, another fails

Situation:

* [ ] One TCP service works
* [ ] Another TCP service fails

Use the working connection to eliminate possible causes.

Document:

`docs/mysteries/06-one-port-works-another-fails.md`

---

# Phase 14 — Mystery 7

## Correct resources, wrong association

You find:

* [ ] Gateway exists
* [ ] Route table exists
* [ ] Route rule exists
* [ ] Instance exists
* [ ] Connectivity still fails

Investigate relationships between resources.

Do not create duplicate infrastructure just because connectivity fails.

Document:

`docs/mysteries/07-wrong-route-table-association.md`

---

# Phase 15 — Mystery 8

## Terraform drift

Create one controlled manual OCI configuration change.

Then:

* [ ] Detect the drift
* [ ] Determine exactly what changed
* [ ] Understand the impact
* [ ] Compare desired vs actual state
* [ ] Restore the intended configuration

Document:

`docs/mysteries/08-terraform-drift.md`

---

# Phase 16 — Mystery 9

## Works from one source, fails from another

Situation:

* [ ] admin-01 → target-01 works
* [ ] another source → target-01 fails

Compare:

* source address
* network path
* routing
* public/private exposure
* NSGs
* protocol

Document:

`docs/mysteries/09-source-dependent-connectivity.md`

---

# Phase 17 — Kubernetes Networking Extension

Do this only after the OCI/Linux mysteries work.

## Task 17.1 — Prepare Kubernetes environment

* [ ] Create/use a Kubernetes cluster
* [ ] Verify cluster access
* [ ] Understand nodes, Pods, Services and namespaces before deploying anything

---

## Task 17.2 — Deploy a minimal test workload

Files:

* `kubernetes/namespace.yaml`
* `kubernetes/deployment.yaml`
* `kubernetes/service.yaml`

Requirements:

* [ ] Create a namespace
* [ ] Deploy a minimal network-test workload
* [ ] Expose it using a Kubernetes Service
* [ ] Verify Pod health
* [ ] Verify Service connectivity

The application itself should remain trivial.

Networking is still the subject.

---

## Task 17.3 — Understand Kubernetes traffic paths

Be able to explain:

Pod → Pod

Pod → Service

Service → Pod

Node → Pod

External client → Service

Do not continue until you understand the difference.

---

## Task 17.4 — Kubernetes networking mystery

Create a controlled scenario where:

* [ ] Pod exists
* [ ] Pod is healthy
* [ ] Service exists
* [ ] Expected connectivity fails

Investigate:

* selectors
* labels
* endpoints
* ports
* target ports
* namespace
* NetworkPolicy

Do not immediately recreate the workload.

---

## Task 17.5 — NetworkPolicy

File:

`kubernetes/networkpolicy.yaml`

* [ ] Create a NetworkPolicy
* [ ] Restrict selected traffic
* [ ] Verify allowed traffic
* [ ] Verify denied traffic
* [ ] Explain why each result occurs

---

# Phase 18 — Helm Extension

## Task 18.1 — Convert the Kubernetes workload into Helm

Files:

* `helm/oci-netdebug/Chart.yaml`
* `helm/oci-netdebug/values.yaml`
* `helm/oci-netdebug/templates/`

Move the Kubernetes configuration into a reusable Helm chart.

---

## Task 18.2 — Parameterize configuration

Determine which values should be configurable.

Possible categories:

* image
* replica count
* ports
* Service configuration
* labels
* namespace behavior
* NetworkPolicy configuration

Do not parameterize everything just because Helm allows it.

---

## Task 18.3 — Validate the Helm chart

Verify:

* [ ] chart structure
* [ ] rendered manifests
* [ ] Kubernetes resources
* [ ] successful deployment
* [ ] expected networking behavior

---

## Task 18.4 — Helm configuration mystery

Create a controlled Helm configuration problem that produces a networking symptom.

Examples of areas to investigate:

* Service port
* targetPort
* selector
* labels
* NetworkPolicy values

Your mission is to determine:

> Is the problem Kubernetes networking or the Helm configuration that generated Kubernetes resources?

---

# Phase 19 — Cross-Layer Troubleshooting

## Task 19.1 — OCI vs Kubernetes failure

Create a failure where the symptom could plausibly come from:

* OCI networking
* Kubernetes networking

Determine which layer actually owns the problem.

---

## Task 19.2 — Linux vs Kubernetes failure

Create a scenario where:

* node/network appears reachable
* Kubernetes service is not

Determine whether the issue exists at:

Linux/network layer

or:

Kubernetes layer.

---

## Task 19.3 — Helm vs Kubernetes failure

Receive only this symptom:

> The application worked before the Helm upgrade. Now the Service is unreachable.

Investigate without immediately rolling everything back.

Determine:

* what changed
* generated Kubernetes state
* runtime Kubernetes state
* networking behavior
* root cause

---

# Phase 20 — Final Boss

You receive only:

> A required service cannot be reached.

No layer is provided.

You must determine whether the problem exists in:

* OCI Compute
* OCI routing
* gateway configuration
* OCI NSG/security
* Linux networking
* DNS
* Linux service
* Kubernetes Pod
* Kubernetes Service
* NetworkPolicy
* Helm configuration

Rules:

* [ ] Do not rebuild everything
* [ ] Do not disable all security
* [ ] Do not expose private resources publicly
* [ ] Do not make several random changes
* [ ] Form a hypothesis before making corrective changes
* [ ] Save evidence
* [ ] Identify root cause
* [ ] Apply the smallest reasonable fix
* [ ] Prove the fix

---

# Phase 21 — Final Documentation

## Task 21.1 — Architecture

Update:

`docs/architecture.md`

Show both:

1. OCI/Linux architecture
2. Kubernetes/Helm extension

---

## Task 21.2 — Mystery reports

Every report should contain:

### Symptoms

### Expected Behavior

### Initial Hypotheses

### Investigation

### Evidence

### Root Cause

### Fix

### Verification

### Why My Diagnosis Was Correct

### What I Learned

---

## Task 21.3 — Evidence

Store screenshots and useful terminal evidence under:

`docs/evidence/`

Keep evidence organized by mystery.

---

## Task 21.4 — What I Learned

Finish:

`docs/what-i-learned.md`

You should be able to explain:

### OCI

* VCN
* public/private subnet
* Internet Gateway
* NAT Gateway
* Service Gateway
* routing
* NSGs
* OCI DNS

### Linux

* interfaces
* routes
* DNS
* ports
* services
* SSH
* logs
* processes

### Terraform

* infrastructure state
* dependencies
* drift
* desired vs actual state

### Kubernetes

* Pod networking
* Services
* selectors
* endpoints
* ports
* NetworkPolicy

### Helm

* charts
* values
* templates
* rendered manifests
* configuration-related networking failures

---

## Task 21.5 — Final README

Create a professional README covering:

* project purpose
* architecture
* technology stack
* troubleshooting methodology
* mystery catalog
* screenshots
* skills demonstrated
* how the lab works

Do not turn the README into a giant tutorial.

---

# Final Project Order

```text
Architecture
     ↓
Terraform
     ↓
OCI Networking
     ↓
Linux
     ↓
Known-Good Baseline
     ↓
OCI/Linux Mysteries
     ↓
Kubernetes Networking
     ↓
Helm
     ↓
Cross-Layer Mysteries
     ↓
Final Boss
     ↓
Documentation
```

# Technologies

Core:

* Oracle Cloud Infrastructure
* Terraform
* Linux
* Networking
* Git

Extension:

* Kubernetes
* Helm

# Project Rule

For every failure:

```text
Symptoms
   ↓
Observe
   ↓
Compare working vs failing paths
   ↓
Form hypothesis
   ↓
Test hypothesis
   ↓
Collect evidence
   ↓
Identify root cause
   ↓
Apply minimal fix
   ↓
Verify
   ↓
Document
```

