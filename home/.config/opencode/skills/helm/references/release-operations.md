# Release operations

## Repositories and dependencies

```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami/postgresql --versions
helm dependency update chart/
helm dependency build chart/
```

- Use a pinned dependency version or lockfile for reproducibility.
- For OCI charts, use `oci://registry.example.com/charts` and `helm registry login`.
- Do not use `--devel` or pre-release versions unless intended.

## Render before install

```sh
helm template release chart/ -f values-dev.yaml --namespace app
helm template release chart/ -f values-dev.yaml --namespace app --include-crds --debug
helm template release chart/ --set image.tag=1.2.3 --api-versions policy/v1
```

- `--debug` prints the rendered manifests and notes.
- `--namespace` affects `Release.Namespace` and namespaced lookups.
- `--api-versions` simulates cluster capabilities for offline rendering.
- `--kube-version` simulates the target Kubernetes version.
- Pipe rendered output to schema/policy tools before applying.

## Install and upgrade

```sh
helm upgrade --install release chart/ \
  --namespace app \
  --create-namespace \
  --values values-dev.yaml \
  --atomic \
  --wait \
  --timeout 5m
```

- `--install` makes the command idempotent for first-time installs.
- `--atomic` rolls back automatically if the upgrade fails.
- `--wait` waits for resources to become ready; pair with a realistic timeout.
- `--create-namespace` creates the namespace if missing.
- `--version` selects a chart version.
- `--dry-run=client` renders without contacting the cluster;
  `--dry-run=server` validates against the cluster.
- `--set` is convenient for CI but has type pitfalls. Prefer values files; use
  `--set-string` for strings that look numeric, and `--set-json` for structured values.
- `--force` replaces resources and can cause downtime. Avoid unless required.
- `--take-ownership` adopts existing resources; verify ownership first.

## Inspect releases

```sh
helm list -n app
helm status release -n app
helm history release -n app
helm get values release -n app
helm get manifest release -n app
helm get all release -n app
```

- `get values` shows user-supplied values, not the full computed set unless `--all`.
- `get manifest` shows what Helm applied.
- `history` is essential before rollback.
- Helm stores release state in Secrets by default; `HELM_DRIVER=configmap` or `sql` changes
  that.

## Rollback and uninstall

```sh
helm rollback release 3 -n app
helm rollback release 0 -n app     # roll back to the previous revision
helm uninstall release -n app
helm uninstall release -n app --keep-history
```

- Rollback creates a new revision; it is not a time machine for external state.
- Verify the rollback with `helm status` and workload checks.
- `uninstall` deletes release-owned resources. Confirm the context and namespace.
- CRDs in `crds/` are not removed by `helm uninstall`.
- PVCs and external resources may persist depending on annotations and ownership.

## Diff plugin

```sh
helm plugin install https://github.com/databus23/helm-diff
helm diff upgrade release chart/ -f values-dev.yaml -n app
helm diff revision release 2 3 -n app
```

`helm diff` compares the live release with the proposed render. It is one of the most
valuable safety checks before an upgrade.

## Hooks

```yaml
metadata:
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-5"
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
```

- Hooks run at defined lifecycle points; weights order them.
- Hook resources are not part of the release manifest.
- Make hooks idempotent and safe to retry.
- Avoid hooks that mutate data irreversibly without a backup.
- Use `hook-failed` policies deliberately; a failed hook can block the release.

## Tests

```sh
helm test release -n app
helm test release -n app --logs
```

Test pods should check real connectivity or readiness, not just `sleep`. Clean up test
resources with hook delete policies.

## Packaging and registries

```sh
helm lint chart/
helm package chart/ --destination dist/
helm push dist/api-1.2.3.tgz oci://registry.example.com/charts
helm registry login registry.example.com
```

- Chart version must be bumped before packaging.
- Sign packages with `--sign --key <key> --keyring <ring>` when provenance is required.
- Verify with `helm verify`.
- Use immutable versions in registries; do not overwrite released chart versions.
- For GitOps, commit rendered manifests or let the controller render the chart; do not
  mix manual upgrades with automated sync.
