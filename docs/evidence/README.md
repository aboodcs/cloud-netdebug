# Evidence Directory

Store sanitized runtime evidence here after a baseline or mystery is actually executed. Do not add fabricated output or empty files that imply a test was performed.

## Recorded evidence

- `baseline/2026-09-03-local-validation.md` records Terraform formatting/state observations, Terraform validation limitations, Helm lint, and client-side manifest parsing.
- `baseline/2026-09-03-kubernetes.md` records the point-in-time minikube workload, Service, EndpointSlice, service response, NetworkPolicy, CNI, and cluster addressing observations.

No AWS or OCI cloud-connectivity evidence and no completed mystery evidence are currently recorded. Each `mystery-<number>/README.md` now defines what must be captured when that mystery is run; those instructions are not runtime evidence.

Use one directory per report, for example:

```text
docs/evidence/
├── baseline/
├── mystery-01/
├── mystery-02/
└── ...
```

Useful evidence includes:

- Timestamped Terraform plan or state-inspection output.
- Provider route-table, subnet-association, gateway, and security-rule output.
- `ip address`, `ip route`, `ip route get`, and `ip neigh` output.
- `ss`, service status, and relevant logs.
- `curl`, `nc`, `ssh -vvv`, `getent`, and `dig` results.
- `kubectl get`, `describe`, logs, and EndpointSlice output.
- Helm values and rendered manifests when a Helm change is involved.
- Screenshots only when they were genuinely captured and add information not preserved as text.

Each evidence file should identify:

- Date/time and timezone.
- Provider, region, or Kubernetes context.
- Source host/Pod and destination.
- Exact command used.
- Whether the capture is before or after the fix.
- The report that references it.

Before committing, remove or redact private keys, passwords, tokens, cookies, full cloud credentials, sensitive account/tenancy identifiers, and unrelated user data. Do not redact the technical fields needed to support the conclusion, such as the relevant route target, port, selector, or sanitized resource relationship.

Prefer text output over screenshots when the command can be captured as text. Do not alter output to make a hypothesis appear correct; add an adjacent note explaining irrelevant or sanitized fields instead.
