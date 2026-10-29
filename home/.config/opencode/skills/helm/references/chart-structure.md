# Chart structure

## Layout

```text
chart/
├── Chart.yaml
├── Chart.lock
├── values.yaml
├── values.schema.json
├── .helmignore
├── crds/
├── charts/
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── serviceaccount.yaml
    ├── NOTES.txt
    ├── hpa.yaml
    ├── tests/
    │   └── test-connection.yaml
    └── hooks/
        └── pre-install-job.yaml
```

## Chart.yaml

```yaml
apiVersion: v2
name: api
description: API service
type: application
version: 1.2.3
appVersion: "2.4.0"
kubeVersion: ">=1.28.0-0"
dependencies:
  - name: postgresql
    version: 15.x.x
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

- `apiVersion: v2` is required for Helm 3 charts.
- `version` is the chart version and must be SemVer; bump it for every chart change.
- `appVersion` describes the application, not the chart. Quote it if it looks numeric.
- `type: library` charts provide helpers but install no resources.
- `dependencies` are resolved into `Chart.lock` and `charts/`.
- Use `condition` and `tags` to make optional dependencies controllable.
- `kubeVersion` documents the supported cluster range; it does not replace testing.

## values.yaml

- Provide sensible defaults for a local or minimal install.
- Document each top-level key with a comment.
- Group values by concern (`image`, `service`, `ingress`, `resources`, `autoscaling`).
- Do not duplicate values that can be derived from `Chart.Name` or `Release.Name`.
- Keep environment-specific overrides out of the chart defaults; put them in separate
  values files or the deployment platform.
- Avoid values that are only used to toggle broken behavior.

Common shape:

```yaml
replicaCount: 1
image:
  repository: registry.example.com/team/api
  tag: ""
  pullPolicy: IfNotPresent
imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""
serviceAccount:
  create: true
  annotations: {}
  name: ""
podAnnotations: {}
podSecurityContext: {}
securityContext: {}
service:
  type: ClusterIP
  port: 80
resources: {}
```

An empty `tag` conventionally falls back to `Chart.AppVersion`.

## values.schema.json

Use JSON Schema to validate values before rendering:

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["image"],
  "properties": {
    "replicaCount": { "type": "integer", "minimum": 0 },
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": { "type": "string", "minLength": 1 },
        "tag": { "type": "string" }
      }
    }
  }
}
```

Helm validates values against the schema on install, upgrade, lint, and template. Use it
for required fields, enums, and numeric bounds, not for cluster-dependent checks.

## Dependencies

```sh
helm dependency list chart/
helm dependency update chart/
helm dependency build chart/
```

- Commit `Chart.lock` for reproducible dependency resolution.
- `update` re-resolves versions; `build` uses the lockfile.
- Vendored charts live in `charts/`; decide whether the repository commits them.
- Subchart values are nested under the dependency name unless `global` is used.
- Use `condition` to disable a subchart and `tags` for group toggles.
- For OCI dependencies, use `oci://registry.example.com/charts`.

## CRDs

- Files in `crds/` are installed before templates and are not templated.
- Helm does not upgrade or delete CRDs in `crds/` automatically.
- CRD upgrades require a separate process and careful compatibility planning.
- Keep CRD schemas structural; avoid `preserveUnknownFields` unless required.
- Use `--include-crds` with `helm template` when validating rendered output.

## Hooks and tests

- Hooks are annotated with `helm.sh/hook` and optional `hook-weight`,
  `hook-delete-policy`.
- Common hooks: `pre-install`, `post-install`, `pre-upgrade`, `post-upgrade`,
  `pre-delete`, `post-delete`, `test`.
- Hook resources are not tracked as part of the release; they must be idempotent.
- `helm test` runs pods annotated with `helm.sh/hook: test`.
- Do not use hooks for long-running services.

## .helmignore

Exclude local files that should not be packaged:

```text
.git
.gitignore
*.tmp
*.swp
.DS_Store
ci/
tests/
```

Do not exclude files required by templates or `values.schema.json`.
