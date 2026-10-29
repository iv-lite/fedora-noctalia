# Verification

## 1. Lint

```sh
helm lint chart/
helm lint chart/ -f values-dev.yaml
helm lint chart/ --strict
```

Lint catches template syntax, missing values, and basic chart issues. `--strict` treats
warnings as errors.

## 2. Render

```sh
helm template release chart/ -f values-dev.yaml -n app --debug > /tmp/rendered.yaml
helm template release chart/ --include-crds > /tmp/rendered-with-crds.yaml
```

Check:

- Output is valid YAML and contains no `{{` leftovers.
- Resource names, namespaces, labels, and selectors are correct.
- Image tags and pull policies are intended.
- Resources, probes, and security contexts are present.
- ConfigMaps/Secrets and volume mounts line up.
- No plaintext secrets or environment-specific values leaked into the chart defaults.
- Repeated renders are identical.

## 3. Schema validation

```sh
kubeconform -strict -summary /tmp/rendered.yaml
kube-linter lint /tmp/rendered.yaml
```

For CRDs not known to kubeconform, provide the CRD schema or exclude those resources
explicitly. Do not silently ignore unknown kinds.

## 4. Cluster validation

```sh
helm upgrade --install release chart/ -n app -f values-dev.yaml --dry-run=server
kubectl apply --dry-run=server -f /tmp/rendered.yaml
```

`--dry-run=server` contacts the API server and runs admission, but it does not persist
the release. If the chart uses `lookup`, server dry run behaves differently from offline
rendering.

## 5. Diff

```sh
helm diff upgrade release chart/ -n app -f values-dev.yaml
```

Review every changed resource. Pay special attention to:

- Deletions and replacements (immutable fields such as selectors or PVC settings).
- Changes to Services, Ingress, RBAC, CRDs, and storage.
- Image tag changes.
- Resource limit reductions.
- Secret/config changes that trigger restarts.

## 6. Apply and confirm

```sh
helm upgrade --install release chart/ -n app -f values-dev.yaml --atomic --wait --timeout 5m
helm status release -n app
kubectl rollout status deployment/release-chart -n app --timeout=120s
```

- Confirm the release revision advanced.
- Confirm pods are Ready and the service responds.
- Check logs and events for errors introduced by the change.
- Run `helm test` if the chart defines tests.
- Record the previous revision for rollback.

## 7. Rollback check

Before declaring success, know:

- The previous revision number (`helm history`).
- Whether rollback is safe for CRDs, PVCs, and external state.
- The expected rollback command and the person authorized to run it.

```sh
helm rollback release <revision> -n app
```

## Chart change checklist

- `Chart.yaml` version bumped when the chart changes.
- `appVersion` updated when the application version changes.
- `Chart.lock` consistent with dependencies.
- `values.schema.json` updated for new or changed values.
- README or values comments updated.
- Templates are deterministic and pass lint.
- Rendered manifests pass schema/policy checks.
- No secrets or local-only values committed.
- Upgrade and rollback paths both considered.
