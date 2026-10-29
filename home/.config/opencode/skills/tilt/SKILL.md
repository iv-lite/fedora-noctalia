---
name: Tilt
description: Use when working with Tiltfiles, Tilt-based local Kubernetes development, live_update, Tilt resources, or Tilt CI and debugging workflows.
---

# Tilt

## Scope

Use this skill for Tiltfile authoring and debugging, Tilt-managed local Kubernetes or
Docker Compose environments, Live Update configuration, resource dependencies, and Tilt
CI. Use the Docker, Kubernetes, Helm, and Kubernetes Operator skills for the underlying
artifacts.

## First steps

1. Find the `Tiltfile` and any `tilt_config.json`, includes, or extensions.
2. Determine the target cluster and context; Tilt is usually for local development but
   can target shared clusters.
3. Identify how images are built (`docker_build`, `custom_build`, pre-built images) and
   how YAML is produced (`k8s_yaml`, `helm`, `kustomize`, custom scripts).
4. Check for `config.parse` and custom Tiltfile arguments.
5. Confirm whether the task is development (`tilt up`) or CI (`tilt ci`).

## Safety rules

- `tilt up` is a long-running foreground process. Do not run it in a way that blocks the
  agent indefinitely; use a background process or `tilt ci` for validation.
- `tilt down` deletes the resources Tilt deployed. Confirm the context and namespace
  before running it.
- Never call `allow_k8s_contexts()` for production clusters.
- Do not add `--host 0.0.0.0` or expose the Tilt UI remotely without understanding the
  security implications.
- Treat `k8s_custom_deploy` commands as cluster mutations; review them before running.
- Do not commit secrets to Tiltfiles or values files. Use environment variables or a
  secret manager.

## Working rules

- Tiltfiles execute from top to bottom at startup. Registration functions collect
  configuration; they do not immediately start workloads.
- Any file read by `read_file`, `watch_file`, or a function that records access causes
  the Tiltfile to re-execute when it changes.
- `local()` does not automatically record file reads; call `read_file` or `watch_file`
  for files the command depends on.
- Keep resource names stable; they are user-facing and referenced by dependencies.
- Prefer explicit `resource_deps` over implicit ordering assumptions.
- Use `trigger_mode(TRIGGER_MODE_MANUAL)` for expensive or optional resources.
- Keep Live Update paths inside the image build context.
- Prefer project scripts over duplicating build/deploy logic in the Tiltfile.
- Use `config.define_*` for per-user or per-environment arguments instead of editing the
  Tiltfile.

## Verification

Render the Tiltfile result without starting a long-lived session:

```sh
tilt alpha tiltfile-result
```

Common checks:

```sh
tilt ci
tilt doctor
tilt version
```

For a running session:

```sh
tilt get uiresources
tilt describe <resource>
tilt logs <resource>
```

See `references/cli-and-verification.md` for the full command set.

## References

- `references/tiltfile-basics.md` — execution model, YAML, images, local resources, config.
- `references/live-update.md` — sync/run steps, restarts, triggers, fallbacks.
- `references/resources-and-cluster.md` — resources, dependencies, ports, contexts, Helm.
- `references/cli-and-verification.md` — CLI, CI, inspection, debugging, cleanup.
