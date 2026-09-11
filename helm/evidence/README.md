# Day 5 Helm verification

All commands ran from `/home/abood/cloud-netdebug/helm/oci-netdebug` on
2026-09-11. Kubernetes context: `minikube`. The installed release uses default
values. Files in this directory are excluded from Helm packaging by `.helmignore`.

## Changes

- Moved the existing resource requests and limits into `resources.requests` and
  `resources.limits`, preserving all default quantities.
- Rendered resources, readinessProbe, and livenessProbe from values in the
  Deployment container using `toYaml` and `nindent 12`.
- Added a small dev override: one replica; requests of 50m CPU and 64Mi memory;
  limits of 100m CPU and 128Mi memory.
- Preserved the immutable image digest and existing Service template.

## Commands and captured output

| Command | Exit code | Output |
| --- | --- | --- |
| `helm lint .` (initial) | 0 | [Initial lint](01-initial-lint.txt) |
| `helm template netdebug .` (initial) | 0 | [Default render](default.yaml) |
| `helm template netdebug . -f values-dev.yaml` (initial) | 0 | [Dev render](dev.yaml) |
| `kubectl config current-context` | 0 | [Context](02-cluster-context.txt) |
| `kubectl cluster-info` (sandbox attempt) | 1 | [Network access blocked](03-cluster-info.txt) |
| `kubectl cluster-info` (authorized retry) | 0 | [Cluster available](03-cluster-info-authorized.txt) |
| `diff -u evidence/default.yaml evidence/dev.yaml` | 1 (expected: files differ) | [Override diff](04-default-vs-dev.diff) |
| `kubectl get namespace netdebug -o yaml` (before install) | 1 (namespace absent) | [Namespace check](05-namespace-before-install.yaml) |
| `helm list -n netdebug` (before install) | 0 | [No previous release](06-helm-list-before-install.txt) |
| `helm upgrade --install netdebug . -n netdebug --create-namespace` | 0 | [Install](07-install.txt) |
| `helm list -n netdebug` (after install) | 0 | [Deployed release](08-helm-list.txt) |
| `kubectl rollout status deployment/netdebug-app -n netdebug --timeout=180s` | 0 | [Successful rollout](09-rollout.txt) |
| `helm lint .` (one deliberate template break) | 1 (expected) | [Error and restoration](10-controlled-break.txt) |
| `kubectl get pods -n netdebug` | 0 | [Two ready pods](11-pods.txt) |
| `kubectl get svc -n netdebug` | 0 | [Service](12-services.txt) |
| `kubectl get deployment -n netdebug` | 0 | [Deployment ready 2/2](13-deployments.txt) |
| `helm lint .` (final, after restoration) | 0 | [Final lint](14-final-lint.txt) |
| `helm template netdebug .` (final, after restoration) | 0 | [Final default render](15-final-default.yaml) |
| `helm template netdebug . -f values-dev.yaml` (final, after restoration) | 0 | [Final dev render](16-final-dev.yaml) |

The chart's icon recommendation is informational; final lint reports
`1 chart(s) linted, 0 chart(s) failed`.

## Override comparison

| Setting | Default | Dev |
| --- | --- | --- |
| replicas | 2 | 1 |
| resources.requests.cpu | 100m | 50m |
| resources.requests.memory | 128Mi | 64Mi |
| resources.limits.cpu | 250m | 100m |
| resources.limits.memory | 256Mi | 128Mi |

## Controlled break and fix

Temporarily changed the resources expression in `templates/deployment.yaml` from
`.Values.resources` to `.Values.resourcesWrong.requests`. Accessing `requests`
under the nonexistent parent reliably produces a Helm template error; rendering
only `.Values.resourcesWrong` with `toYaml` could simply emit `null`.

Lint failed with `nil pointer evaluating interface {}.requests` and exit code 1.
The original template was restored in a `finally` block. The broken template was
never installed. Final lint and both renders succeeded after the restoration.

The release remains installed for review. No commit was made.
