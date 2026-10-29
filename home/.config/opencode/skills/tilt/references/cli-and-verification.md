# CLI and verification

## Start and stop

```sh
tilt up
tilt up --stream
tilt up --context kind-kind --namespace app
tilt up -- --flag-for-tiltfile
tilt down
```

- `tilt up` is long-running and opens the web UI on `localhost:10350` by default.
- `--stream` prints logs to the terminal instead of only the UI.
- On exit, Kubernetes and Compose resources keep running; `tilt down` deletes them.
- `serve_cmd` local resources are terminated when Tilt exits.
- Do not run `tilt up` in a foreground agent command that cannot be interrupted; use a
  background process or `tilt ci` for verification.

## CI

```sh
tilt ci
tilt ci --timeout 10m
```

- `tilt ci` starts the environment, waits for all resources to become healthy, and exits.
- It returns non-zero if a resource fails or the timeout expires.
- It is the preferred non-interactive validation for Tiltfile changes.
- CI should use a disposable cluster and deterministic image tags.

## Arguments and control

```sh
tilt args
tilt args -- --enable-worker
tilt trigger <resource>
tilt enable <resource>
tilt disable <resource>
```

- `tilt args` shows or changes the args of the running session.
- `tilt trigger` forces an update for a resource.
- `tilt enable`/`disable` toggles resources in the current session.
- With `config.parse()`, Tiltfile args use `--name=value` syntax.

## Inspect

```sh
tilt get uiresources
tilt get uiresources <name> -o yaml
tilt describe <resource>
tilt logs <resource>
tilt doctor
tilt version
```

- `tilt get uiresources` lists resource status.
- `tilt describe` shows the resource's current state and recent events.
- `tilt logs` prints resource logs.
- `tilt doctor` reports environment and cluster problems.
- `tilt dump engine` dumps the engine state for deep debugging.
- `tilt snapshot` captures a shareable snapshot of the session.

## Tiltfile-only validation

```sh
tilt alpha tiltfile-result
```

This evaluates the Tiltfile and prints the resulting configuration without starting a
full session. It is useful for catching Starlark errors, invalid resource definitions,
and dependency cycles. Check `tilt alpha --help` for the exact flags in the installed
version.

## Tiltfile LSP

```sh
tilt lsp
```

Tilt ships a language server for Tiltfile/Starlark editing. OpenCode has no built-in Tilt
LSP; if the project has `tilt` installed and wants editor diagnostics, add a custom entry:

```jsonc
"tilt": {
  "command": ["tilt", "lsp"],
  "extensions": [".tiltfile"]
}
```

This is optional and not enabled by default.

## Debugging checklist

- Tiltfile fails to evaluate: read the Starlark traceback; check `read_file` paths and
  `config.parse()` arguments.
- Resource stuck in pending: inspect `tilt describe <resource>` and the Kubernetes
  events.
- Image build loops: check `ignore`/`only`, `.dockerignore`, and generated files that
  change on every build.
- Live Update not applying: confirm the path is in the build context and matches `sync`.
- Port forward fails: check local port conflicts and the target service port.
- Cluster permission errors: verify the kubeconfig context and namespace.
- Tilt UI not loading: check `tilt doctor`, the configured host/port, and firewall rules.

## Cleanup

```sh
tilt down
tilt down --namespace app
```

- `tilt down` deletes resources deployed by the session.
- Confirm the context and namespace before running it.
- Long-running local `serve_cmd` processes are stopped by Tilt.
- Temporary namespaces and PVCs may need separate cleanup depending on the project.

## Before finishing

- Tiltfile evaluates without errors (`tilt alpha tiltfile-result` or `tilt ci`).
- Resources become healthy in a disposable environment.
- Live Update paths, fallbacks, and restart behavior are intentional.
- `tilt down` leaves no unintended resources behind.
- No production context is allowed and no secrets are committed.
