# Evidence for Mystery 06 — One Port Works, Another Fails

> Evidence status: not executed. This directory contains collection instructions only.

Related guide: [`06-one-port-works-another-fails.md`](../../mysteries/06-one-port-works-another-fails.md)

Use the same verified external destination from `target-01` for HTTP/TCP 80 and HTTPS/TCP 443. This keeps the destination and route constant while the public HTTPS egress rule is removed.

## Required captures

- Provider, region, timestamp, source host, and verified destination.
- Known-good HTTP and HTTPS results before the change.
- DNS results proving both tests use the intended destination.
- Target egress security rules before, during, and after the fault.
- HTTP and HTTPS results during the fault, including exact error types.
- Terraform plan/apply evidence for staging and rollback.
- Repeated HTTP and HTTPS tests after rollback.

## Command checklist

```bash
date --iso-8601=seconds
hostname
getent ahosts <verified-test-host>
curl -4 -v --connect-timeout 10 http://<verified-test-host>/
curl -4 -v --connect-timeout 10 https://<verified-test-host>/
terraform -chdir=terraform/<provider> plan
```

Relevant resources:

- AWS: `aws_vpc_security_group_egress_rule.target_allow_http` and `aws_vpc_security_group_egress_rule.target_allow_https`
- OCI: `oci_core_network_security_group_security_rule.target_allow_http_to_internet` and `oci_core_network_security_group_security_rule.target_allow_https_to_internet`

On OCI, capture the separate service-CIDR HTTPS rule if it affects interpretation. It does not prove general Internet HTTPS access.
