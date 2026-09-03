# Evidence for Mystery 04 — OCI Service Works, Internet Fails

> Evidence status: not executed. This is an OCI-only mystery, and this directory contains collection instructions only.

Related guide: [`04-oci-service-works-internet-fails.md`](../../mysteries/04-oci-service-works-internet-fails.md)

This mystery compares the OCI Service Gateway route with the NAT Gateway route. Do not substitute an AWS endpoint or describe an AWS VPC endpoint as an equivalent implementation.

## Required captures

- OCI region, timestamp, and sanitized VCN, subnet, route-table, NAT Gateway, and Service Gateway identifiers.
- The verified OCI service endpoint and verified public Internet endpoint used by the baseline.
- Baseline results to both endpoints from `target-01`.
- Private route-table output showing both the OCI service-CIDR route and default NAT route.
- NAT Gateway state before, during, and after `block_traffic = true`.
- Tests to both endpoints while NAT traffic is blocked.
- Terraform plan/apply records for staging and rollback.

## Command checklist

```bash
date --iso-8601=seconds
hostname
ip address
ip route
curl -4 -v --connect-timeout 10 https://<verified-oci-service-endpoint>/
curl -4 -v --connect-timeout 10 https://<verified-public-internet-endpoint>/
terraform -chdir=terraform/oci state show oci_core_route_table.private
terraform -chdir=terraform/oci state show oci_core_nat_gateway.main
terraform -chdir=terraform/oci state show oci_core_service_gateway.service_gateway
terraform -chdir=terraform/oci plan
```

The files must identify which request used the OCI service path and which used the public Internet path. Do not record the designed outcome as observed until both commands have been executed.
