# Manifest patterns

## Common structure

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: app
  labels:
    app.kubernetes.io/name: api
    app.kubernetes.io/instance: api-dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: api
    spec:
      containers:
        - name: api
          image: registry.example.com/team/api:1.2.3
          ports:
            - containerPort: 8080
```

- `selector` is immutable for many workload types; choose stable labels before creating.
- `template.metadata.labels` must match the selector.
- Set `namespace` explicitly in generated manifests or let the tooling set it
  consistently.
- Use recommended labels (`app.kubernetes.io/*`) when the repository has no convention.

## Deployments

- Set `strategy` for zero-downtime rollouts (`RollingUpdate`, `maxSurge`,
  `maxUnavailable`).
- Set `minReadySeconds` and probes so traffic reaches ready pods.
- Set `revisionHistoryLimit` to bound ReplicaSet history.
- Use `terminationGracePeriodSeconds` long enough for in-flight requests.
- Handle `SIGTERM` and stop accepting new work before exiting.
- Use `PodDisruptionBudget` for workloads that must retain capacity during drains.

## Resources

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    memory: 256Mi
```

- Requests drive scheduling; limits enforce ceilings.
- CPU limits can cause throttling. Many teams set CPU requests but no CPU limit; follow
  the platform policy.
- Memory limits that are too low cause OOM kills. Set them from measured usage.
- Use `LimitRange` and `ResourceQuota` only if the cluster requires them.

## Probes

- `readinessProbe` controls traffic. It should fail when the pod cannot serve.
- `livenessProbe` restarts unhealthy pods. It must not fail during normal startup or
  transient downstream failures.
- `startupProbe` protects slow-starting apps from premature liveness restarts.
- Prefer HTTP/TCP checks with realistic timeouts and thresholds.
- Do not make liveness depend on external services; that causes cascading restarts.

## Security context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

- Add writable `emptyDir` mounts for apps that need scratch space.
- Avoid `privileged: true` unless the workload is a documented system component.
- Set `automountServiceAccountToken: false` when the pod does not call the API.
- Use dedicated service accounts with minimal RBAC.

## Services and ingress

- `ClusterIP` is the default and is correct for internal services.
- `NodePort` and `LoadBalancer` expose the service outside the cluster; use deliberately.
- Selector labels must match pod labels exactly.
- For ingress, confirm the ingress class, TLS secret, and path rewrite behavior.
- Set `externalTrafficPolicy` only with an understanding of source IP preservation.
- Use `NetworkPolicy` to restrict traffic when the cluster CNI supports it.

## Configuration and secrets

- `ConfigMap` for non-sensitive configuration; `Secret` for credentials.
- Prefer mounting files or using `envFrom` over many individual env vars.
- Secrets are base64-encoded, not encrypted, in the API. Use encryption at rest or an
  external secret manager.
- Set `immutable: true` for config that should not change in place.
- Restart or roll pods after config changes when the app does not watch the file.

## Storage

- Use a `PersistentVolumeClaim` with the appropriate access mode and storage class.
- StatefulSets need a `volumeClaimTemplate` and a headless service for stable identity.
- Understand reclaim policy and backup before deleting PVCs.
- Do not use `hostPath` outside system components.

## RBAC

- Grant permissions to service accounts, not users, unless intentionally user-facing.
- Prefer namespaced `Role`/`RoleBinding` over `ClusterRole`/`ClusterRoleBinding`.
- Avoid wildcard verbs/resources and `cluster-admin`.
- Separate read and write permissions where possible.
- Audit `kubectl auth can-i --list` for unexpected access.
