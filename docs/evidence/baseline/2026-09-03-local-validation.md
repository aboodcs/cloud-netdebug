# Local Configuration Validation — 2026-09-03

Captured between `2026-09-03T16:33:55+03:00` and `2026-09-03T16:37:09+03:00` from Git revision `b46db61`.

This evidence validates files and local Terraform state only. It does not prove that AWS or OCI resources currently exist or that cloud traffic succeeds.

## Terraform formatting

Commands:

```bash
terraform -chdir=terraform/aws fmt -check
terraform -chdir=terraform/oci fmt -check
```

Observed result:

```text
aws_fmt=PASS
oci_fmt=PASS
```

## Terraform state presence

Command:

```bash
terraform -chdir=terraform/aws state list
```

Observed AWS local-state addresses:

```text
data.aws_ami.amazon_linux
aws_eip.nat
aws_instance.admin_01
aws_instance.target_01
aws_internet_gateway.main
aws_key_pair.netdebug
aws_nat_gateway.main
aws_route_table.private
aws_route_table.public
aws_route_table_association.private
aws_route_table_association.public
aws_security_group.admin_sg
aws_security_group.target_sg
aws_subnet.private
aws_subnet.public
aws_vpc.main
aws_vpc_security_group_egress_rule.admin_allow_ssh_to_target
aws_vpc_security_group_egress_rule.target_allow_http
aws_vpc_security_group_egress_rule.target_allow_https
aws_vpc_security_group_ingress_rule.admin_allow_ssh_from_laptop
aws_vpc_security_group_ingress_rule.target_allow_ssh_from_admin
```

Command:

```bash
terraform -chdir=terraform/oci state list
```

Observed result:

```text
No state file was found.
```

The AWS list proves only that a local state snapshot exists. It is not a provider refresh and must not be used as proof that every remote object is current. No OCI runtime claim can be made from local Terraform state.

## Terraform validation limitation

Commands:

```bash
terraform -chdir=terraform/aws validate -no-color
terraform -chdir=terraform/oci validate -no-color
```

Observed result: both commands exited with status `1` while loading provider schemas. The cached `hashicorp/aws` and `oracle/oci` provider processes produced an unrecognized plugin message and no schema response. Therefore this capture does not claim successful `terraform validate`; provider execution must be repaired or reinitialized before validation evidence can be recorded.

## Helm lint

Command:

```bash
helm lint ./helm/oci-netdebug
```

Observed result:

```text
==> Linting ./helm/oci-netdebug
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

## Rendered Helm resource parsing

Command:

```bash
helm template evidence-check ./helm/oci-netdebug \
  | kubectl create --dry-run=client --validate=false -f - -o name
```

Observed result:

```text
namespace/netdebug
networkpolicy.networking.k8s.io/allow-approved-client
service/netdebug-service
deployment.apps/netdebug-app
```

## Raw Kubernetes manifest parsing

Command:

```bash
kubectl create --dry-run=client --validate=false -f kubernetes/ -o name
```

Observed result:

```text
deployment.apps/netdebug-app
namespace/netdebug
networkpolicy.networking.k8s.io/allow-approved-client
service/netdebug-service
```

These are client-side dry runs. They confirm local decoding and resource recognition but are not server admission or deployment evidence.
