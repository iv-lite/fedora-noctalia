# Operations and troubleshooting

## Context and namespace

```sh
kubectl config current-context
kubectl config get-contexts
kubectl config set-context --current --namespace=app
kubectl get ns
```

- Confirm the context before every mutating command.
- Prefer `-n <namespace>` on each command over relying on the current namespace.
- Use `--context <name>` for one-off commands against another cluster.

## Inspect

```sh
kubectl get all -n app
kubectl get pods -n app -o wide
kubectl describe pod <pod> -n app
kubectl logs <pod> -n app --tail=200
kubectl logs <pod> -n app -c <container> --previous
kubectl get events -n app --sort-by=.lastTimestamp
```

- `describe` shows events, conditions, and container state; read it before guessing.
- `--previous` shows logs from the last crashed container.
- `kubectl get -o yaml` reveals the live spec and status.
- `kubectl explain <kind>.<field>` documents the API schema.

## Apply and diff

```sh
kubectl diff -f manifest.yaml
kubectl apply -f manifest.yaml
kubectl apply --server-side -f manifest.yaml
```

- `diff` shows what would change using server-side dry run.
- Client-side apply stores the last-applied annotation; server-side apply uses field
  ownership. Do not mix them carelessly on the same object.
- Use `--prune` only with a clearly scoped label selector and a reviewed manifest set.
- Re-run `diff` after resolving conflicts.

## Rollouts

```sh
kubectl rollout status deployment/api -n app
kubectl rollout history deployment/api -n app
kubectl rollout undo deployment/api -n app
kubectl rollout restart deployment/api -n app
```

- `rollout status` waits but may hang; use a timeout in automation.
- `undo` reverts to the previous revision unless a revision is specified.
- Restarting does not change the manifest; it triggers a new ReplicaSet.
- Check `kubectl describe deployment` for progress conditions.

## Debugging common states

### Pending

- Insufficient CPU/memory: check requests and node capacity.
- Unschedulable constraints: node selectors, affinity, taints/tolerations.
- Unbound PVC: check storage class and events.

### ImagePullBackOff / ErrImagePull

- Wrong image name/tag or registry.
- Missing `imagePullSecrets` or expired credentials.
- Network policy or registry outage.
- Check events for the exact registry error.

### CrashLoopBackOff

- Read current and previous logs.
- Check the entrypoint, config mounts, env vars, and file permissions.
- Verify the process runs as the configured user.
- Distinguish an application crash from a failed liveness probe.

### OOMKilled

- Check `kubectl describe pod` for the termination reason.
- Compare memory usage with the limit.
- Fix the leak or raise the limit based on measurement.

### Readiness failures

- Check probe path, port, scheme, and initial delay.
- Verify the service is listening on the expected address (`0.0.0.0`, not only `127.0.0.1`).
- Check dependency availability and startup time.

## Exec and port forwarding

```sh
kubectl exec -it <pod> -n app -- sh
kubectl port-forward svc/api 8080:80 -n app
kubectl cp app/<pod>:/tmp/file ./file
```

- Prefer ephemeral debug containers when the image has no shell.
- Port-forward binds locally; it does not expose the service externally.
- `kubectl cp` requires `tar` in the container and can be slow for large trees.

## Helm and Kustomize

```sh
helm list -n app
helm status <release> -n app
helm get values <release> -n app
helm rollback <release> <revision> -n app
kustomize build overlays/dev | kubectl diff -f -
```

Use the Helm skill for chart changes. Do not patch Helm-managed resources manually;
change values or templates and upgrade.

## Destructive operations

- `kubectl delete` removes live resources. Confirm the context, namespace, name, and
  selector.
- `kubectl drain` evicts pods; ensure PodDisruptionBudgets and replacement capacity.
- Deleting a namespace deletes everything inside it.
- Deleting a PVC may delete the underlying volume depending on reclaim policy.
- Prefer scaling to zero or deleting a specific resource over broad cleanup commands.
