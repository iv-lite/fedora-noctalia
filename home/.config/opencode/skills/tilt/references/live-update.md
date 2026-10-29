# Live Update

## What it does

Live Update avoids a full image rebuild and redeploy by syncing changed files into a
running container and optionally running commands. The initial build is always a full
Docker/custom build.

## Step order

The `live_update` list must follow this order:

1. Zero or one `initial_sync()` step.
2. Zero or more `fall_back_on(...)` steps.
3. Zero or more `sync(...)` steps.
4. Zero or more `run(...)` steps.

```python
docker_build(
    'api',
    '.',
    live_update=[
        sync('./src', '/app/src'),
        sync('./package.json', '/app/package.json'),
        run('npm install', trigger='./package.json'),
        run('touch /tmp/restart'),
    ],
)
```

## sync

```python
sync(local_path, remote_path)
```

- A change matching a sync path triggers a Live Update.
- Files are copied to the remote path; deletions are propagated.
- Local paths must be inside the image build context (or `custom_build` deps).
- Changes inside the build context but outside sync paths trigger a full rebuild.
- Changes outside the context and sync paths are ignored.
- Use `initial_sync()` for pre-built images so local files are uploaded when the
  container first starts.

## run

```python
run(cmd, trigger=None)
```

- Commands run inside the container, from `/`; use absolute paths.
- Runs execute after all sync steps.
- Without a trigger, the command runs on every Live Update.
- With a trigger, it runs only when a changed file matches the trigger path.
- Trigger files must also be covered by a `sync` step to cause a Live Update.
- The container image must contain the shell and tools the command needs.

## fall_back_on

```python
fall_back_on(['./package-lock.json', './Dockerfile'])
```

- If a changed file matches, Tilt performs a full rebuild and redeploy instead of a Live
  Update.
- Use it for dependency locks, native code, generated assets, or anything that cannot be
  hot-reloaded.
- `fall_back_on` must come before `sync` steps.

## Restarting the process

Live Update copies files but does not automatically restart the main process.

Options:

1. **restart_process extension**

   ```python
   load('ext://restart_process', 'docker_build_with_restart')

   docker_build_with_restart(
       'api',
       '.',
       entrypoint='/app/server',
       live_update=[sync('./src', '/app/src')],
   )
   ```

2. **restart_container()** — restarts the container as a Live Update step. Useful for
   Compose resources.

3. **File-watching process** — run the app under `nodemon`, `watchexec`, `air`, or a
   framework dev server that reloads on file changes.

4. **Trigger file** — run a command that touches a file watched by `entr` or a custom
   wrapper.

The `restart_process` extension does not work for Docker Compose, `custom_build`, images
without a shell (scratch/distroless), or CRDs.

## Custom build caveats

- `custom_build` supports Live Update, but `restart_process` does not.
- Ensure the custom build watches every path used by `sync`.
- If the build produces an image reference dynamically, Live Update still requires the
  container to be running.

## Debugging Live Update

- Check that the changed file is inside the build context and matches a sync path.
- Check whether a `fall_back_on` path matched.
- Confirm the remote path exists and is writable by the container user.
- Confirm run commands exist in the image and use absolute paths.
- Look at the resource's build vs runtime logs in the Tilt UI or `tilt logs`.
- Use `tilt trigger <resource>` to force an update when testing.

## When not to use Live Update

- Native code or dependencies that require a full rebuild.
- Images without a shell or package manager.
- Changes to entrypoints, security context, or Kubernetes manifests.
- Anything where a full rollout is required to validate the change.

In those cases, remove the path from `sync` so a normal rebuild happens, or use
`fall_back_on`.
