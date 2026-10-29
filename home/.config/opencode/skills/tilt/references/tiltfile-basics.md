# Tiltfile basics

## Execution model

- Tiltfiles are written in Starlark, a Python-like language.
- The file executes once at startup. Functions such as `k8s_yaml` and `docker_build`
  register configuration; the final configuration is used after execution.
- Relative paths are relative to the Tiltfile's directory.
- Tilt records file access. If a read file changes, the Tiltfile re-executes.
- Only the Tiltfile re-executes on config changes; source changes trigger resource
  builds/updates.

## Deploy YAML

```python
# One or more static files
k8s_yaml('deploy/app.yaml')
k8s_yaml(['deploy/api.yaml', 'deploy/worker.yaml'])

# Kustomize
k8s_yaml(kustomize('config/default'))

# Helm chart rendering
k8s_yaml(helm('./charts/api', values=['values-dev.yaml']))

# A command that prints YAML
yaml = local('./scripts/render.sh')
k8s_yaml(blob(yaml))
```

- `k8s_yaml` accepts paths, `Blob`s, or raw YAML wrapped in `blob()`.
- `helm()` renders the chart locally; it does not create a Helm release. Use a Helm-aware
  extension or `k8s_custom_deploy` if release lifecycle behavior is required.
- `kustomize()` renders the overlay locally.
- When using `local()` to generate YAML, record every input file the script reads:

  ```python
  read_file('config/base.yaml')
  read_file('config/versions.txt')
  k8s_yaml(local('./scripts/render.sh'))
  ```

- `read_file` returns a `Blob`; `read_yaml` parses YAML; `read_json` parses JSON.

## Build images

```python
docker_build(
    'registry.example.com/team/api',
    context='.',
    dockerfile='Dockerfile',
    build_args={'TARGET': 'dev'},
    live_update=[...],
)

custom_build(
    'registry.example.com/team/api',
    command='./scripts/build-image.sh',
    deps=['src', 'package.json'],
    tag='dev',
    live_update=[...],
)
```

- `docker_build` wraps `docker build` and watches the context.
- `custom_build` runs an arbitrary command that must produce the image reference.
- Use `ignore=`/`only=` or `.dockerignore` to control what triggers rebuilds.
- For pre-built images, use `k8s_custom_deploy` or a `custom_build` that pulls/tags.
- `default_registry('registry.example.com')` rewrites image names for a registry.
- Tilt injects image references into the Kubernetes YAML it deploys.

## Local resources

```python
local_resource(
    'generate',
    cmd='./scripts/generate.sh',
    deps=['schemas', 'scripts/generate.sh'],
    trigger_mode=TRIGGER_MODE_MANUAL,
)

local_resource(
    'web',
    cmd='npm run build',
    serve_cmd='npm run dev',
    deps=['web/src', 'web/package.json'],
    resource_deps=['generate'],
)
```

- `cmd` is the one-shot update command; `serve_cmd` is a long-running process.
- `serve_cmd` is terminated when Tilt exits.
- Use `auto_init=False` to avoid running on startup.
- `allow_parallel=True` lets resources update concurrently when safe.

## Docker Compose

```python
docker_compose('./docker-compose.yml')

dc_resource('api', new_name='api', port_forwards=['8080:8080'])
```

- Tilt manages Compose services as resources.
- Use `dc_resource` to add port forwards, dependencies, labels, and trigger modes.
- Compose resources support `restart_container()` but not all Live Update features.

## Per-user configuration

```python
config.define_string('cluster', 'Kubernetes context to use')
config.define_bool('enable_worker', 'Enable the worker service', False)
config.define_string_list('services', 'Services to start')
cfg = config.parse()

if cfg.get('cluster'):
    allow_k8s_contexts(cfg['cluster'])

if not cfg.get('enable_worker', False):
    disable('worker')
```

- Access values via `cfg['name']` or `cfg.get('name', default)`.
- `config.parse()` changes how command-line args are interpreted; with it, args are
  parsed as `--name=value` instead of a service list.
- Use environment variables (`os.getenv`) only for machine-level settings; prefer config
  definitions for team-facing options.

## Includes and extensions

```python
include('./Tiltfile.shared')
load('ext://restart_process', 'docker_build_with_restart')
load('ext://helm_resource', 'helm_resource')
```

- `include` executes another Tiltfile in the same global scope.
- `load` imports symbols from a local file or an extension.
- Pin or document extension versions where the project requires reproducibility.
- Do not load arbitrary remote extensions without reviewing them.

## Helper functions

- `local(cmd)` runs a command and returns stdout as a `Blob`.
- `watch_file(path)` records a dependency without reading contents.
- `listdir(path)` lists a directory and records access.
- `shlex.quote(s)` safely quotes a string for shell use.
- `blob(s)` marks a string as data rather than a file path.
- `os.path.*` helpers are available for path manipulation.
- `fail(msg)` aborts Tiltfile execution with an actionable error.
