# Verification

## Generation

```sh
make manifests
make generate
git diff --exit-code
```

- `manifests` regenerates CRDs, RBAC, and webhook configuration from markers.
- `generate` regenerates deepcopy and other generated Go code.
- A clean diff after generation means checked-in artifacts are current.
- Never hand-edit generated files; change the type or marker and regenerate.

## Static checks

```sh
make fmt
make vet
go test ./... -race
```

If the project uses golangci-lint, run the repository's configured target. Do not add new
lint suppressions without a reason.

## Unit and envtest

```sh
make test
go test ./internal/controller/... -run TestReconcile -v
```

Check:

- Reconcile creates the desired resources.
- A second reconcile is a no-op.
- Status conditions and `observedGeneration` update correctly.
- Deletion cleans up owned and external resources and removes finalizers.
- Invalid input produces a useful condition or validation error.
- Transient errors are returned and retried.

## Schema validation

```sh
kubectl apply --dry-run=server -f config/crd/bases/example.com_databases.yaml
kubectl explain database.spec --recursive
```

- Apply CRDs to a disposable cluster and verify the schema is structural.
- Check that CEL rules reject invalid objects with clear messages.
- Verify defaulting and required fields.
- Use `kubeconform` with the CRD schema for sample custom resources.

## RBAC

```sh
kubectl auth can-i --list --as=system:serviceaccount:operator-system:operator-controller-manager
kubectl auth can-i create deployments --as=system:serviceaccount:operator-system:operator-controller-manager -n app
```

- Confirm the operator has exactly the permissions it needs.
- Confirm it does not have cluster-admin or wildcard access.
- Test in a namespace-scoped installation if supported.

## Webhooks

- Verify serving certificates are valid and rotated.
- Test admission with valid and invalid objects.
- Test conversion round trips between every served version.
- Confirm `failurePolicy` and timeouts match the risk tolerance.
- Ensure the webhook does not block CRD or namespace deletion unintentionally.

## E2E

```sh
make test-e2e
```

- Install into a disposable kind/k3d cluster exactly as production.
- Create a sample CR, wait for `Ready=True`.
- Update the spec and confirm reconciliation.
- Delete the CR and confirm cleanup.
- Check operator logs and Events for unexpected errors.
- Verify the operator recovers after a pod restart.

## Packaging

```sh
make bundle
operator-sdk bundle validate ./bundle
operator-sdk scorecard ./bundle
helm lint chart/
helm template release chart/ | kubeconform -strict -summary
```

- Confirm the bundle CSV version, CRDs, and RBAC match the release.
- Confirm the image reference and tag are correct.
- Confirm install and upgrade from the previous release work.

## Before finishing

- Generated artifacts are current.
- Formatting, vet, lint, and unit tests pass.
- Envtest/E2E covers the changed behavior.
- CRD schema and conversion changes are backward compatible or documented.
- RBAC remains minimal.
- Webhooks have safe failure behavior.
- Upgrade and rollback paths are known.
