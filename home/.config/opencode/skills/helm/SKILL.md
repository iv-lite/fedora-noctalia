---
name: Helm
description: Use when authoring, reviewing, debugging, packaging, or releasing Helm charts, chart values, templates, hooks, or Helm-managed Kubernetes deployments.
---

# Helm

## Scope

Use this skill for Helm chart structure, Go-template rendering, values design, release
operations, hooks, dependencies, OCI packaging, and chart verification. Use the
Kubernetes skill for the rendered workload conventions and the Docker skill for image
builds.

## First steps

1. Find the chart root (`Chart.yaml`), the chart version, and the Helm version used by
   the project or CI.
2. Read `values.yaml`, all environment values files, and `values.schema.json`.
3. Inspect `templates/`, `_helpers.tpl`, subcharts, and CRDs.
4. Determine how releases are installed: CI, Argo CD, Flux, a platform CLI, or manually.
5. Confirm the target cluster context and namespace before any install or upgrade.

## Safety rules

- Never run `helm upgrade`, `helm rollback`, or `helm uninstall` against production
  without explicit confirmation of the context, release, and namespace.
- Render and diff before changing a live release:

  ```sh
  helm template release chart/ -f values.yaml > /tmp/rendered.yaml
  helm diff upgrade release chart/ -f values.yaml
  ```

- Do not edit Helm-managed resources with `kubectl edit`; change values or templates and
  upgrade the release.
- `--force` and `--take-ownership` can be destructive; use only with a clear reason.
- Keep secrets out of values files. Reference existing Secrets or use an external secret
  mechanism.
- Do not change a chart's `name` or release name casually; it changes ownership and
  resource identity.

## Working rules

- Treat the chart as a library with a stable values interface. Prefer additive changes.
- Keep templates readable; use named helpers instead of duplicating blocks.
- Make values explicit and documented. Avoid hidden defaults in templates.
- Use `values.schema.json` for important charts.
- Keep resource names deterministic and within 63 characters.
- Add standard labels and selectors consistently across resources.
- Preserve backward compatibility for existing values keys; deprecate before removing.
- Do not use random functions in templates unless non-determinism is intended.

## Verification

```sh
helm lint chart/
helm template release chart/ -f values-dev.yaml --debug
helm template release chart/ --include-crds
```

If available:

```sh
helm diff upgrade release chart/ -f values-dev.yaml
kubeconform -strict rendered.yaml
kube-linter lint rendered.yaml
```

See `references/verification.md` for the full check sequence.

## References

- `references/chart-structure.md` — chart layout, metadata, values, dependencies, CRDs.
- `references/templating.md` — Go templates, Sprig, helpers, whitespace, deterministic output.
- `references/release-operations.md` — install, upgrade, rollback, hooks, tests, registries.
- `references/verification.md` — lint, render, diff, schema checks, rollout confirmation.
