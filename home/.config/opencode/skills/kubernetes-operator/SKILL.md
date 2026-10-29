---
name: Kubernetes Operator
description: Use when building, reviewing, or debugging Kubernetes operators and controllers, CRDs, reconcile loops, admission or conversion webhooks, or operator packaging and upgrades.
---

# Kubernetes Operator

## Scope

Use this skill for custom controllers and operators built with Kubebuilder, Operator SDK,
or controller-runtime. It covers CRD/API design, reconciliation, status, finalizers,
webhooks, RBAC, testing, packaging, and upgrades. Use the Kubernetes skill for general
workload manifests and the Helm skill when the operator is distributed as a chart.

## First steps

1. Identify the framework and versions: Kubebuilder, Operator SDK, controller-runtime,
   client-go, and the Kubernetes API version targeted.
2. Read `PROJECT`, `Makefile`, `config/`, `api/`, and `internal/controller/`.
3. Map each CRD to its controller and note watched resources.
4. Check how the operator is installed: Kustomize, Helm, OLM bundle, or raw YAML.
5. Identify the test strategy: envtest, fake client, kind/k3d e2e, scorecard.

## Safety rules

- Never test destructive reconciliation against a shared or production cluster.
- CRD changes are effectively API changes. Treat field removal, type changes, and
  storage-version changes as breaking.
- Do not edit generated CRDs, RBAC, or webhook manifests by hand when `make manifests`
  owns them.
- Finalizers can block deletion forever. Test deletion paths and failure handling.
- Webhooks can block all writes to a resource. Test failure policies and timeouts.
- Operators often hold broad RBAC. Keep permissions namespaced and minimal.
- Do not log entire custom resources or secrets; redact sensitive fields.

## Working rules

- Reconcile is level-triggered and must be idempotent. Compute desired state from the
  observed object every time; do not rely on event history.
- Separate spec (desired) from status (observed). Never write status into spec.
- Update status in a way that avoids fighting the main resource update.
- Handle `NotFound` as normal, and stop reconciling when the object is gone.
- Use owner references for owned resources in the same namespace.
- Add finalizers only when external cleanup is required, and remove them after cleanup
  succeeds.
- Return errors for transient failures; use `RequeueAfter` for expected delays.
- Use `observedGeneration` in status conditions.
- Keep reconcile fast; move long work to Jobs.
- Watch owned resources so changes trigger reconciliation.
- Use server-side apply or merge patches deliberately; avoid read-modify-write races.
- Log with structured key/value pairs and a stable resource identifier.

## Verification

```sh
make manifests generate
make fmt vet
make test
```

If available:

```sh
make test-e2e
operator-sdk scorecard bundle/
kubectl apply --dry-run=server -f config/crd/bases/
```

See `references/verification.md` for the full sequence.

## References

- `references/crd-design.md` — API shape, schema, status, versions, conversion.
- `references/controller-patterns.md` — reconcile, watches, finalizers, status, errors.
- `references/testing-and-release.md` — envtest, e2e, RBAC, webhooks, OLM, upgrades.
- `references/verification.md` — generation, tests, schema, RBAC, and rollout checks.
