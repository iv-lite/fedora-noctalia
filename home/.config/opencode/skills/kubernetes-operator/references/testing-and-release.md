# Testing and release

## Project layout

A Kubebuilder project typically contains:

```text
api/v1alpha1/            # API types and webhooks
internal/controller/     # reconcilers
config/crd/bases/        # generated CRDs
config/rbac/             # generated RBAC
config/webhook/          # webhook configuration
config/default/          # kustomize entrypoint
test/e2e/                # end-to-end tests
```

Generated files are usually checked in. Regenerate them after API or marker changes:

```sh
make manifests generate
```

## Envtest

Envtest runs a real API server and etcd without a full cluster.

```go
testEnv = &envtest.Environment{
    CRDDirectoryPaths:     []string{filepath.Join("..", "..", "config", "crd", "bases")},
    ErrorIfCRDPathMissing: true,
}
```

- Point it at the generated CRDs and webhook install options.
- Start and stop the environment in `TestMain`/suite setup.
- Use a per-test namespace or unique names to avoid collisions.
- Envtest does not run the scheduler or kubelet; pods do not actually start.
- Test status updates, finalizers, conditions, and deletion.

## Unit and integration tests

- Use table-driven tests for pure helpers and desired-state builders.
- Use a fake client for simple controller tests, but remember it does not enforce CRD
  schema or admission.
- Prefer envtest for behavior that depends on API defaults, validation, or status
  subresources.
- Test conflict handling and requeue behavior, not only the happy path.
- Test deletion with and without finalizers.
- Test invalid input and expected condition messages.

## End-to-end tests

```sh
make test-e2e
```

- Run against a disposable kind/k3d cluster, never a shared cluster.
- Install CRDs, RBAC, webhooks, and the operator exactly as production does.
- Create a sample custom resource and wait for readiness.
- Exercise update, scale, and deletion.
- Verify cleanup of owned and external resources.
- Use unique names and namespaces; clean up in `AfterEach`.
- Capture controller logs on failure.

## Webhooks

- Admission webhooks need serving certificates. Common choices: cert-manager or
  `make deploy` with local certs.
- Set `failurePolicy` deliberately. `Fail` can block all writes if the webhook is down.
- Keep webhook timeouts short and handlers fast.
- Test defaulting and validation independently.
- Conversion webhooks need round-trip tests and access to all served versions.
- Do not validate against cluster state in a way that makes creation impossible during
  bootstrap.

## RBAC

- Generate RBAC from kubebuilder markers:

  ```go
  // +kubebuilder:rbac:groups=example.com,resources=databases,verbs=get;list;watch;create;update;patch;delete
  // +kubebuilder:rbac:groups=example.com,resources=databases/status,verbs=get;update;patch
  // +kubebuilder:rbac:groups=example.com,resources=databases/finalizers,verbs=update
  // +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
  ```

- Include status and finalizer subresources explicitly.
- Keep cluster-scoped permissions out unless required.
- Verify with `kubectl auth can-i --list` for the operator's service account.
- Regenerate after changing markers.

## Packaging

- **Kustomize:** `config/default` is the install entrypoint. Keep image tags and
  namespace patches in overlays.
- **Helm:** wrap generated manifests in a chart when Helm is the distribution mechanism.
  Use the Helm skill for chart rules.
- **OLM:** generate a bundle with `make bundle`; keep the CSV, CRDs, and RBAC in sync.
  Run `operator-sdk bundle validate` and `operator-sdk scorecard`.
- Keep multi-arch image builds reproducible and pin base images.

## Observability

- Expose controller-runtime metrics and scrape them.
- Add health and readiness endpoints.
- Log structured messages with reconcile IDs or resource keys.
- Emit Events for user-visible state.
- Alert on reconcile error rate, queue depth, and workqueue latency.
- Do not log sensitive custom resource fields.

## Upgrades and migrations

- Never change a stored API version in place without a conversion plan.
- Add new versions, serve both, and migrate storage before removing old versions.
- Test upgrade from the previous operator version with existing CRs.
- Make schema additions backward compatible; default new fields safely.
- Plan CRD upgrades separately from the operator Deployment.
- Document rollback limits, especially for CRD and storage changes.

## Release checklist

- `make manifests generate` produces no unexpected diff.
- `make fmt vet test` passes.
- E2E tests pass on a disposable cluster.
- RBAC is minimal and regenerated.
- Webhook certificates and failure policies are correct.
- CRD conversion and storage versions are intentional.
- Bundle/Helm/Kustomize artifacts are regenerated.
- Upgrade and rollback paths are documented.
