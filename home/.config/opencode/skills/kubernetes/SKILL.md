---
name: Kubernetes
description: Use when writing, reviewing, or debugging Kubernetes manifests and workloads, kubectl operations, cluster resources, or deployment troubleshooting.
---

# Kubernetes

## Scope

Use this skill for Kubernetes YAML, `kubectl` workflows, workload configuration, cluster
debugging, RBAC, networking, storage, and deployment safety. Use the Helm skill for chart
authoring and the Kubernetes Operator skill for custom controllers and CRDs.

## First steps

1. Identify the cluster context and namespace you are allowed to touch.
2. Find how manifests are produced: plain YAML, Kustomize, Helm, or a generator.
3. Read existing labels, annotations, resource conventions, and policy constraints.
4. Check the API versions supported by the target cluster; do not assume the latest.
5. Confirm whether the task is local, staging, or production. Treat production as
   high-risk and require explicit approval for mutations.

## Safety rules

- Always check `kubectl config current-context` before applying or deleting anything.
- Use `--dry-run=server` and `kubectl diff` before applying changes.
- Never run `kubectl delete` with a broad selector or namespace unless the blast radius is
  understood and approved.
- Do not edit live resources manually when the source manifests are managed elsewhere;
  fix the source and reapply.
- Do not put plaintext secrets in manifests or commit them.
- Preserve existing labels, annotations, and owner references.
- Use explicit namespaces; do not rely on the current default.

## Working rules

- Set resource requests and limits intentionally.
- Add readiness and liveness probes only when they reflect real health.
- Use `securityContext` defaults: non-root, no privilege escalation, read-only root
  filesystem where feasible.
- Set `revisionHistoryLimit`, rollout strategy, and `terminationGracePeriodSeconds`
  deliberately for production workloads.
- Pin image tags; avoid `latest` in committed manifests.
- Use `ConfigMap`/`Secret` references rather than inlining configuration.
- Keep manifests declarative and idempotent.

## Verification

```sh
kubectl diff -f manifest.yaml
kubectl apply --dry-run=server -f manifest.yaml
kubectl apply --dry-run=client -f manifest.yaml
kubectl get events --sort-by=.lastTimestamp
```

For rendered manifests:

```sh
kustomize build overlays/dev
helm template release chart
```

See `references/verification.md` for schema and policy checks.

## References

- `references/manifests.md` — workload, networking, storage, security, and RBAC patterns.
- `references/operations.md` — kubectl workflows and failure triage.
- `references/verification.md` — dry runs, diffs, schema/policy validation, cleanup.
