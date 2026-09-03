# Mystery 4 — OCI Service Works, Internet Fails

> Status: reproducible mystery defined but not executed; no runtime evidence is recorded.
>
> Provider scope: OCI-specific.

## Scenario

From `target-01`, connectivity to a supported Oracle Services Network endpoint works through the OCI Service Gateway, while normal Internet connectivity fails.

This mystery compares two distinct OCI routes. It remains OCI-specific because the AWS implementation in this repository does not define VPC endpoints, and AWS gateway/interface endpoints are service-specific rather than a direct one-for-one equivalent to an OCI Service Gateway.

## Reproducible setup

1. In OCI, record successful HTTPS access from `target-01` to a verified endpoint whose resolved destination is inside the selected Oracle Services Network service CIDR.
2. Record successful HTTP/HTTPS access from `target-01` to a general Internet endpoint.
3. In `oci_core_nat_gateway.main`, temporarily change `block_traffic = false` to `block_traffic = true`.
4. Review the Terraform plan and apply it only to the disposable OCI lab.
5. Confirm from OCI control-plane state that the Service Gateway remains available and the Service Gateway route is unchanged.
6. Give the learner only the symptom: the OCI service test works, while general Internet access fails.

This mystery must not be staged unless the working service endpoint and its service-CIDR membership were recorded first. Otherwise, “OCI service works” would be an assumption rather than a controlled signal.

### Rollback

Restore `block_traffic = false`, review and apply the Terraform plan, and repeat both the general Internet and OCI service control tests.

## Expected behavior

The OCI private route table declares both paths:

```text
target-01
   +-- destination in OCI service CIDR
   |      -> more-specific SERVICE_CIDR_BLOCK route
   |      -> oci_core_service_gateway.service_gateway
   |      -> Oracle Services Network
   |
   `-- general Internet destination
          -> 0.0.0.0/0
          -> oci_core_nat_gateway.main
          -> Internet
```

The target NSG declares stateful TCP/443 egress to the selected OCI service CIDR and TCP/80/443 egress to `0.0.0.0/0`. Both paths still depend on the actual subnet association, effective security-list rules, DNS, and destination behavior.

## Actual behavior

Populate after selecting and recording a real OCI service endpoint and a real Internet control endpoint:

| Test | Actual result | Resolved destination | Evidence |
| --- | --- | --- | --- |
| OCI service endpoint over HTTPS | _Populate_ | _Populate_ | _Populate_ |
| Internet endpoint over HTTP | _Populate_ | _Populate_ | _Populate_ |
| Internet endpoint over HTTPS | _Populate_ | _Populate_ | _Populate_ |
| DNS resolution | _Populate_ | _Populate_ | _Populate_ |

Do not assume an endpoint uses the Service Gateway merely because it is operated by Oracle. Confirm that its resolved destination belongs to the service CIDR selected by `data.oci_core_services.all_services`.

## Initial hypotheses

1. The service-CIDR route is correct but the `0.0.0.0/0` NAT route is missing or changed.
2. The private subnet references a different route table from the one being inspected.
3. The OCI NAT Gateway exists but is blocked, unavailable, or is not selected by the route.
4. General Internet egress differs from the service-CIDR NSG rule.
5. DNS or endpoint selection makes the two tests use different address families or destinations.
6. The Internet control endpoint itself is unavailable.

## Investigation

On `target-01`, record both resolved destinations and route decisions:

```bash
getent ahostsv4 <verified-oci-service-hostname>
getent ahostsv4 <verified-internet-hostname>
ip route
ip route get <resolved-oci-service-ip>
ip route get <resolved-internet-ip>
curl -4 -v --connect-timeout 5 https://<verified-oci-service-hostname>/
curl -4 -v --connect-timeout 5 https://<verified-internet-hostname>/
```

Inspect the subnet and the route table it actually references:

```bash
oci network subnet get --subnet-id <private-subnet-ocid>
oci network route-table get --rt-id <route-table-ocid-from-subnet>
oci network nat-gateway get --nat-gateway-id <nat-gateway-ocid>
oci network service-gateway get --service-gateway-id <service-gateway-ocid>
```

Inspect effective egress:

```bash
oci network nsg rules list --nsg-id <target-nsg-ocid>
oci network security-list get --security-list-id <default-security-list-ocid>
```

The existence of both gateways is not the result. Compare route destination type, destination CIDR, network entity ID, gateway state, and subnet association.

## Evidence to collect

- Chosen endpoints and their DNS answers.
- Proof that the working endpoint falls inside the selected OCI service CIDR.
- Private subnet `route-table-id`.
- Full private route rules and gateway identifiers.
- NAT `block_traffic` and lifecycle state.
- Service Gateway services and lifecycle state.
- Target NSG plus default security-list egress.
- Comparable `curl` output for the working and failing paths.

## Root cause

_Populate only after the difference between the Service Gateway and NAT paths is proven._

## Fix

_Populate with the smallest OCI configuration correction. Do not add an AWS counterpart to solve this OCI scenario._

## Validation after fix

Repeat the original Internet request and the known-working OCI service request from the same `target-01` instance. Confirm that the route table and Terraform plan match intended state.

## What makes this mystery misleading

Both tests leave the same private instance and may both use HTTPS, yet the destination prefix selects different route-table entries and different gateways. A working Service Gateway path does not validate the default NAT path.

## Provider-specific notes

This mystery is intentionally OCI-only. The repository's AWS implementation reaches public AWS service endpoints through NAT and defines no gateway or interface VPC endpoints. AWS endpoint behavior must be designed per service and must not be presented as symmetric with OCI Service Gateway.

## Evidence location

Store sanitized evidence under `docs/evidence/mystery-04/` after the scenario is run.

## Facilitator answer key

<details>
<summary>Reveal the designed fault and intended diagnosis</summary>

The designed fault is `block_traffic = true` on `oci_core_nat_gateway.main`. General Internet traffic still selects the NAT route but the NAT Gateway blocks it. The more-specific OCI service-CIDR route selects the separate Service Gateway and can continue to work.

The learner should prove that the subnet association and both route rules remain correct, then inspect the differing gateway state. The minimal fix is to restore `block_traffic = false`; no AWS resource should be introduced for this OCI-specific exercise.

</details>
