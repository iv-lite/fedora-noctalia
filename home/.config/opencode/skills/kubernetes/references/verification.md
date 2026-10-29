# Verification

## Client-side validation

```sh
kubectl apply --dry-run=client -f manifest.yaml
kubectl create --dry-run=client -f manifest.yaml -o yaml
```

Client-side dry run validates basic structure and can render the object, but it does not
contact the API server and may miss schema, admission, and policy errors.

## Server-side validation

```sh
kubectl apply --dry-run=server -f manifest.yaml
kubectl diff -f manifest.yaml
```

Server-side dry run uses the target cluster's API schema, defaulting, and admission
webhooks. It is the strongest pre-apply check for a live cluster.

## Schema and policy tools

If available:

```sh
kubeconform -strict -summary manifests/
kube-linter lint manifests/
conftest test manifests/
polaris audit --audit-path manifests/
```

- `kubeconform` validates against Kubernetes JSON schemas.
- `kube-linter` checks common production-readiness issues.
- `conftest`/OPA and Kyverno/Gatekeeper policies enforce organization rules.
- Run policy checks on rendered output, not only on templates.

## Kustomize

```sh
kustomize build overlays/dev
kustomize build overlays/prod | kubectl diff -f -
```

- Check that the correct overlay, namespace, name prefixes, and image tags are rendered.
- Do not apply a base directly if overlays are the supported workflow.
- Validate that patches target existing fields.

## Helm

```sh
helm lint chart/
helm template release chart/ -f values-dev.yaml
helm template release chart/ --validate
helm diff upgrade release chart/ -f values-dev.yaml
```

`--validate` requires a reachable cluster. `helm diff` requires the diff plugin.

## Manifest review checklist

- API versions are supported by the target cluster.
- Namespace is explicit and correct.
- Labels/selectors match.
- Image tag is pinned and comes from the intended registry.
- Resource requests/limits are present.
- Probes reflect real health.
- Security context is non-root with minimal capabilities.
- Config and secrets are referenced, not inlined.
- Services select the intended pods.
- Ingress class, hosts, TLS, and paths are correct.
- PVC storage class and access mode match the cluster.
- RBAC is namespaced and minimal.
- No plaintext secrets or credentials appear in the diff.

## Runtime verification

```sh
kubectl rollout status deployment/api -n app --timeout=120s
kubectl get pods -n app -w
kubectl logs deploy/api -n app --tail=100
kubectl get events -n app --sort-by=.lastTimestamp
```

- Confirm the rollout completes and pods become Ready.
- Exercise the service through its real entrypoint (ingress, service, port-forward).
- Check logs and metrics for errors after the change.
- Verify rollback is possible and the previous revision is known.

## Cleanup

- Remove temporary debug pods, port-forwards, and test resources.
- Do not leave `kubectl port-forward` or `kubectl proxy` running in automation.
- Delete only the resources created for the test, with explicit names and namespaces.
- If a manifest apply created cluster-scoped resources, check whether they need cleanup.
