# Resources and cluster

## Resource model

A Tilt resource bundles work: an image build plus Kubernetes YAML, a local command, or a
Compose service. Tilt assembles Kubernetes workloads and affiliated objects (such as
Services) into resources automatically.

```python
k8s_resource(
    workload='api',
    new_name='api',
    port_forwards=['8080:8080'],
    resource_deps=['postgres'],
    labels=['backend'],
)
```

- `workload` identifies the Kubernetes workload, usually `name` or `name:kind`.
- `new_name` changes the displayed resource name and is needed when grouping objects into
  a new resource.
- `objects` attaches extra Kubernetes objects to a resource or creates a resource from
  non-workload objects.
- `resource_deps` enforces startup/update order.
- `labels` groups resources in the UI.
- `links` adds useful URLs to the UI.
- `trigger_mode` controls automatic, manual, or ignored updates.

## Object selectors

Tilt's selector syntax is `$NAME[:$KIND[:$NAMESPACE]]`.

Examples:

```python
k8s_resource(workload='api:deployment', new_name='api')
k8s_resource(objects=['app:namespace', 'postgres:secret'], new_name='setup')
```

The selector must uniquely identify one object. Use the kind when a name is ambiguous.

## Port forwards

```python
k8s_resource(workload='api', port_forwards=8080)
k8s_resource(workload='api', port_forwards='9000:8080')
k8s_resource(workload='api', port_forwards=[
    port_forward(9000, 8080, 'http'),
    port_forward(9001, 9090, 'metrics'),
])
```

- `local:remote` maps a local port to a container/service port.
- `port_forward(local, remote, name)` adds a UI label.
- Port forwards are established by Tilt and torn down when Tilt exits.
- Conflicts with locally bound ports appear in the UI.

## Trigger modes

```python
k8s_resource('worker', trigger_mode=TRIGGER_MODE_MANUAL)
local_resource('migrate', cmd='./migrate.sh', trigger_mode=TRIGGER_MODE_MANUAL)
```

- `TRIGGER_MODE_AUTO` — update automatically on file changes (default).
- `TRIGGER_MODE_MANUAL` — only update when triggered in the UI or with `tilt trigger`.
- `TRIGGER_MODE_IGNORE` — ignore file changes; still runnable manually.

Use manual mode for expensive, destructive, or optional resources.

## Disabling resources

```python
disable('worker')
```

- `disable(name)` prevents a resource from running unless enabled later.
- `config.set_enabled_resources([...])` or `config.clear_enabled_resources()` can manage
  the set from user arguments.
- Prefer config-driven enabling for optional services.

## Kubernetes contexts

```python
allow_k8s_contexts('kind-kind')
allow_k8s_contexts('docker-desktop')
```

- Tilt refuses to deploy to contexts not explicitly allowed.
- Never allow production or shared staging contexts in a developer Tiltfile.
- Use `--context` on `tilt up` to select a context for a session.
- `k8s_context()` returns the current context; use it only for diagnostics, not for
  silently widening permissions.

## Namespaces

- Set namespaces in the manifests or with `--namespace` on `tilt up`.
- Tilt can deploy multiple resources into the same namespace.
- `tilt down` removes resources in the session's namespace; confirm before running.
- For per-developer isolation, generate a unique namespace from an environment variable
  or config value.

## Helm and Kustomize

### Helm

```python
k8s_yaml(helm('./charts/api', values=['values-dev.yaml'], set=['image.tag=dev']))
```

- `helm()` renders the chart; Tilt deploys the rendered YAML.
- Helm hooks and release history are not managed unless the project uses a Helm-aware
  extension or custom deploy.
- If the team uses `helm_resource` from the Tilt extensions catalog, follow the
  project's established pattern.

### Kustomize

```python
k8s_yaml(kustomize('config/default'))
```

- Tilt runs `kustomize build`; changes to the overlay trigger a redeploy.
- If the project uses a different Kustomize binary or version, use `custom_build` or `local`.

## Custom deploy

```python
k8s_custom_deploy(
    'api',
    apply_cmd='./scripts/apply.sh',
    delete_cmd='./scripts/delete.sh',
    deps=['deploy'],
    live_update=[sync('./src', '/app/src')],
)
```

- `k8s_custom_deploy` runs your own apply/delete commands.
- The apply command must print the applied objects or otherwise let Tilt track them.
- Use it for tools Tilt does not natively support.
- Treat the commands as cluster-mutating and review them carefully.

## Dependencies

```python
k8s_resource('api', resource_deps=['postgres', 'migrate'])
```

- Dependencies affect startup and update ordering.
- Do not create cycles; Tilt rejects them.
- Prefer real readiness checks over sleeps.
- Use `local_resource` for migrations and one-shot setup.

## Multi-Tiltfile repos

- `include('./services/api/Tiltfile')` shares one session across services.
- `load()` imports helpers but does not register resources.
- Keep shared helpers in a small `Tiltfile.shared` or extension.
- Avoid duplicate resource names across includes.
