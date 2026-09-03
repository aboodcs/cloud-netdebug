# Known-Good Baseline

## Purpose

A mystery is useful only when the same path was known to work before it was changed. This document defines how to establish that baseline for either cloud implementation and for the Kubernetes workload.

No successful result is asserted here. Run the checks in the environment being tested, record the observed values, and store supporting output under `docs/evidence/`. Do not replace an expected result with “passed” until evidence has been captured.

## Baseline identity

Record enough context to reproduce the checks:

| Field | Observed value |
| --- | --- |
| Date and time, including timezone | _Populate after testing_ |
| Provider and account/tenancy | _Populate after testing_ |
| Region | _Populate after testing_ |
| Terraform commit/revision | _Populate after testing_ |
| Terraform workspace | _Populate after testing_ |
| Kubernetes context | _Populate after testing_ |
| Kubernetes version | _Populate after testing_ |
| CNI implementation | _Populate after testing_ |

Do not store credentials, private keys, session tokens, or unsanitized account identifiers in evidence.

The procedures assume Terraform, the relevant provider CLI, SSH tools, `kubectl`, and Helm are installed and authenticated. The AWS module defaults to `eu-central-1`, and the OCI module defaults to `me-jeddah-1`. A local, ignored `terraform.tfvars` can override either value; ensure the provider CLI profile or region option matches the effective Terraform input. Record effective values rather than copying defaults blindly.

## 1. Validate Terraform configuration

Run the commands separately because `terraform/aws/` and `terraform/oci/` are independent root modules with independent provider configuration and state.

### AWS

```bash
terraform -chdir=terraform/aws fmt -check
terraform -chdir=terraform/aws init
terraform -chdir=terraform/aws validate
terraform -chdir=terraform/aws plan
terraform -chdir=terraform/aws state list
terraform -chdir=terraform/aws output
```

Expected result:

- Formatting and validation report no errors.
- The plan is understood before any apply; unexpected changes are investigated as possible drift.
- State, if present, contains the VPC, two subnets, two route tables and associations, Internet Gateway, NAT Gateway and Elastic IP, two Security Groups, key pair, and two EC2 instances.
- AWS outputs provide `admin_public_ip`, `admin_private_ip`, and `target_private_ip` only after corresponding resources exist in state.

### OCI

```bash
terraform -chdir=terraform/oci fmt -check
terraform -chdir=terraform/oci init
terraform -chdir=terraform/oci validate
terraform -chdir=terraform/oci plan
terraform -chdir=terraform/oci state list
```

Expected result:

- Formatting and validation report no errors.
- The plan is understood before any apply.
- State, if present, contains the VCN, two subnets, two route tables, Internet Gateway, NAT Gateway, Service Gateway, two NSGs, their rules, and two Compute instances.
- `terraform/oci/outputs.tf` is empty, so there are no declared OCI Terraform outputs to use for instance addresses.

`terraform plan` can contact the provider and refresh remote objects. It does not change infrastructure unless followed by `apply`. If initialization cannot download a provider, record that tooling/network failure separately from an infrastructure failure.

## 2. Confirm cloud resource state

Terraform configuration proves intent; the provider API proves current existence and associations. Set the placeholders from the environment under test.

### AWS inspection

```bash
NETDEBUG_AWS_REGION="eu-central-1"
NETDEBUG_AWS_PROJECT="aws-netdebug"

aws ec2 describe-instances \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=tag:Project,Values=$NETDEBUG_AWS_PROJECT" \
  --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,State:State.Name,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress,Subnet:SubnetId,Vpc:VpcId}' \
  --output table

aws ec2 describe-vpcs \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=tag:Project,Values=$NETDEBUG_AWS_PROJECT" \
  --output table
```

After obtaining the VPC ID:

```bash
NETDEBUG_AWS_VPC_ID="<vpc-id>"

aws ec2 describe-subnets \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=vpc-id,Values=$NETDEBUG_AWS_VPC_ID" \
  --output table

aws ec2 describe-route-tables \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=vpc-id,Values=$NETDEBUG_AWS_VPC_ID" \
  --output json

aws ec2 describe-internet-gateways \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=attachment.vpc-id,Values=$NETDEBUG_AWS_VPC_ID" \
  --output table

aws ec2 describe-nat-gateways \
  --region "$NETDEBUG_AWS_REGION" \
  --filter "Name=vpc-id,Values=$NETDEBUG_AWS_VPC_ID" \
  --output table

aws ec2 describe-security-groups \
  --region "$NETDEBUG_AWS_REGION" \
  --filters "Name=vpc-id,Values=$NETDEBUG_AWS_VPC_ID" \
  --output json
```

Expected result:

- `aws-netdebug-admin-01` is running in the public subnet with private and public IPv4 addresses.
- `aws-netdebug-target-01` is running in the private subnet with a private address and no public address.
- The public subnet is associated with the route table whose `0.0.0.0/0` target is the Internet Gateway.
- The private subnet is associated with the route table whose `0.0.0.0/0` target is the available NAT Gateway.
- Security Group attachments and rules match `terraform/aws/security.tf`.

### OCI inspection

The examples below use the region configured by the active OCI CLI profile. Add `--region <oci-region>` when the profile does not already match the Terraform region.

```bash
NETDEBUG_OCI_COMPARTMENT_ID="<compartment-ocid>"

oci compute instance list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --display-name oci-netdebug-admin-01 \
  --output table

oci compute instance list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --display-name oci-netdebug-target-01 \
  --output table

oci network vcn list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --display-name oci-netdebug-vcn \
  --output table
```

After obtaining the VCN ID:

```bash
NETDEBUG_OCI_VCN_ID="<vcn-ocid>"

oci network subnet list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID" \
  --output table

oci network route-table list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID" \
  --output json

oci network internet-gateway list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID" \
  --output table

oci network nat-gateway list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID" \
  --output table

oci network service-gateway list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID" \
  --output table

oci network nsg list \
  --compartment-id "$NETDEBUG_OCI_COMPARTMENT_ID" \
  --vcn-id "$NETDEBUG_OCI_VCN_ID" \
  --output table
```

Inspect each returned NSG and the VCN default security list:

```bash
NETDEBUG_OCI_NSG_ID="<nsg-ocid>"
NETDEBUG_OCI_SECURITY_LIST_ID="<default-security-list-ocid>"

oci network nsg rules list --nsg-id "$NETDEBUG_OCI_NSG_ID"
oci network security-list get --security-list-id "$NETDEBUG_OCI_SECURITY_LIST_ID"
```

Expected result:

- `oci-netdebug-admin-01` is running with a private and public IPv4 address.
- `oci-netdebug-target-01` is running with a private address and no public address.
- The public subnet references the public route table; the private subnet references the private route table.
- The Internet, NAT, and Service Gateways are available and attached to the expected VCN.
- The private route table has both `0.0.0.0/0` through the NAT Gateway and the OCI service CIDR through the Service Gateway.
- Effective NSG and security-list behavior matches the intended traffic matrix.

## 3. Validate instance addressing and Linux state

Use the provider-appropriate default image user: `ec2-user` for the selected Amazon Linux 2 AMI and `opc` for the selected Oracle Linux image. If the image behavior has been customized, record the actual user instead.

From the laptop, confirm the public hop and private ProxyJump path without copying the private key to `admin-01`:

```bash
NETDEBUG_SSH_KEY="<path-to-private-key>"
NETDEBUG_ADMIN_PUBLIC_IP="<observed-admin-public-ip>"
NETDEBUG_TARGET_PRIVATE_IP="<observed-target-private-ip>"

# AWS
ssh -i "$NETDEBUG_SSH_KEY" "ec2-user@$NETDEBUG_ADMIN_PUBLIC_IP"
ssh -i "$NETDEBUG_SSH_KEY" \
  -J "ec2-user@$NETDEBUG_ADMIN_PUBLIC_IP" \
  "ec2-user@$NETDEBUG_TARGET_PRIVATE_IP"

# OCI
ssh -i "$NETDEBUG_SSH_KEY" "opc@$NETDEBUG_ADMIN_PUBLIC_IP"
ssh -i "$NETDEBUG_SSH_KEY" \
  -J "opc@$NETDEBUG_ADMIN_PUBLIC_IP" \
  "opc@$NETDEBUG_TARGET_PRIVATE_IP"
```

Expected result:

- Direct SSH to `admin-01` reaches the public host only from `allowed_ssh_cidr`.
- ProxyJump SSH reaches `target-01` through `admin-01`.
- A direct Internet SSH attempt to `target-01` has no public destination address and is not part of the design.

On each instance, collect:

```bash
hostname
ip -brief address
ip route
ip route get "$NETDEBUG_TARGET_PRIVATE_IP"
ip neigh
cat /etc/resolv.conf
ss -lntup
systemctl status sshd --no-pager
```

Run `ip route get` with the actual test destination. On `target-01`, use a known Internet address as well as `admin-01`'s private address. Expected result: interfaces are up, assigned addresses belong to the intended subnet, the default route is present, and `sshd` listens on TCP/22 on an address reachable by the intended source.

## 4. Validate target outbound access and DNS

Run on `target-01`:

```bash
ip route
getent ahostsv4 example.com
curl -4 -I --connect-timeout 5 http://example.com/
curl -4 -I --connect-timeout 5 https://example.com/
```

If installed, add resolver-specific evidence:

```bash
dig A example.com
resolvectl status
tracepath example.com
```

Expected result:

- Name resolution returns at least one address.
- HTTP and HTTPS establish outbound connections through the private subnet's NAT path.
- `tracepath` may hide intermediate hops; missing hop replies alone do not prove failure.
- IP connectivity and DNS resolution are recorded as separate tests.

For provider-service connectivity, select an endpoint that is valid for the configured region and record its resolved addresses before testing:

```bash
NETDEBUG_PROVIDER_ENDPOINT="<verified-provider-service-hostname>"
getent ahostsv4 "$NETDEBUG_PROVIDER_ENDPOINT"
curl -4 -I --connect-timeout 5 "https://$NETDEBUG_PROVIDER_ENDPOINT/"
```

Expected result:

- On AWS, the current repository has no VPC endpoint; a public AWS service endpoint uses the NAT path.
- On OCI, an endpoint within the selected Oracle Services Network service CIDR should follow the Service Gateway route.
- An HTTP authentication or authorization response can still prove TCP/TLS reachability; record the response without presenting it as application authorization success.

## 5. Validate Kubernetes objects

First validate the files without persisting them:

```bash
kubectl apply --dry-run=server -f kubernetes/
helm lint helm/oci-netdebug
helm template netdebug helm/oci-netdebug
```

After the workload has intentionally been deployed, inspect current state:

```bash
kubectl config current-context
kubectl get namespace netdebug
kubectl get deployment netdebug-app -n netdebug -o wide
kubectl rollout status deployment/netdebug-app -n netdebug --timeout=120s
kubectl get pods -n netdebug -l app=netdebug-app -o wide --show-labels
kubectl get service netdebug-service -n netdebug -o wide
kubectl describe service netdebug-service -n netdebug
kubectl get endpointslice -n netdebug \
  -l kubernetes.io/service-name=netdebug-service -o wide
kubectl get networkpolicy allow-approved-client -n netdebug -o yaml
```

Expected result:

- Namespace `netdebug` exists.
- Deployment `netdebug-app` has two desired replicas and two ready Pods.
- Pods carry `app=netdebug-app`.
- Service `netdebug-service` is `ClusterIP`, exposes TCP/80, targets port 80, and selects `app=netdebug-app`.
- EndpointSlices contain one ready endpoint per ready selected Pod. Record the actual count; do not assume two if the Deployment is unhealthy.
- NetworkPolicy `allow-approved-client` selects the application Pods for ingress and permits sources in the same namespace with `access=allowed`.

There is no approved-client manifest in the repository. The following checks create temporary Pods and remove them on exit; record this mutation in the evidence notes:

```bash
kubectl run netdebug-approved \
  --namespace netdebug \
  --image=curlimages/curl \
  --restart=Never \
  --labels=access=allowed \
  --rm -it -- \
  curl -v --max-time 10 http://netdebug-service:80/

kubectl run netdebug-unapproved \
  --namespace netdebug \
  --image=curlimages/curl \
  --restart=Never \
  --labels=access=denied \
  --rm -it -- \
  curl -v --max-time 10 http://netdebug-service:80/
```

Expected result with a NetworkPolicy-capable CNI:

- The approved client reaches nginx through the Service.
- The unapproved client times out or is otherwise denied.
- If both clients connect, investigate CNI policy enforcement before changing the policy YAML.

For a local application check without creating a client Pod:

```bash
kubectl port-forward -n netdebug service/netdebug-service 8080:80
```

In another terminal:

```bash
curl -v http://127.0.0.1:8080/
```

Expected result: nginx responds through the temporary tunnel. Port-forwarding is useful for process-level validation, but it is not proof of normal ClusterIP routing or an external exposure design.

## 6. Record the baseline

Complete one row per actual test:

| Test | Expected result | Actual result | Source | Destination | Protocol/port | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| Laptop → `admin-01` | SSH allowed from configured operator CIDR | _Populate_ | _Populate_ | _Populate_ | TCP/22 | _Populate_ |
| `admin-01` → `target-01` | SSH allowed through private path | _Populate_ | _Populate_ | _Populate_ | TCP/22 | _Populate_ |
| `target-01` → Internet IP/HTTP endpoint | Outbound NAT path works | _Populate_ | _Populate_ | _Populate_ | TCP/80 or 443 | _Populate_ |
| `target-01` → hostname | DNS plus outbound path works | _Populate_ | _Populate_ | _Populate_ | DNS and TCP/80 or 443 | _Populate_ |
| `target-01` → provider service | Provider-specific path works | _Populate_ | _Populate_ | _Populate_ | Usually TCP/443 | _Populate_ |
| Approved Pod → Service | Allowed by Service and NetworkPolicy | _Populate_ | _Populate_ | `netdebug-service` | TCP/80 | _Populate_ |
| Unapproved Pod → Service | Denied by NetworkPolicy | _Populate_ | _Populate_ | `netdebug-service` | TCP/80 | _Populate_ |

Do not start a mystery until the relevant row has a recorded known-good result. A baseline for AWS does not prove the OCI path, and a working Pod IP does not prove the Service path.

## Recorded evidence

- `docs/evidence/baseline/2026-09-03-local-validation.md` records local configuration parsing, Helm lint, Terraform state presence, and the current Terraform provider-validation limitation.
- `docs/evidence/baseline/2026-09-03-kubernetes.md` records a real minikube snapshot in which the Deployment had two available replicas, the Service had two matching endpoints, and the Kubernetes API service-proxy request returned nginx content.

That Kubernetes snapshot did not test an approved and unapproved client, so NetworkPolicy enforcement remains an explicit validation placeholder. No AWS or OCI cloud-connectivity baseline has been recorded.
