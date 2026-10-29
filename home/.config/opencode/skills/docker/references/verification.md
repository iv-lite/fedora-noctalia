# Verification

## Build

```sh
docker build -t app:dev .
docker build --target runtime -t app:dev .
docker buildx build --platform linux/amd64 -t app:dev --load .
```

- Check the final image size and layer list:

  ```sh
  docker image inspect app:dev --format '{{.Size}}'
  docker history app:dev
  ```

- Verify the runtime stage does not contain compilers, source, tests, or secrets.
- Build with the same arguments and target CI uses.

## Run

```sh
docker run --rm app:dev
docker run --rm -p 127.0.0.1:8080:8080 app:dev
docker run --rm --entrypoint sh app:dev
```

- Confirm the process starts, binds the expected port, and exits cleanly.
- Test signal handling: `docker stop` should allow a graceful shutdown.
- Check logs for startup errors and secret leakage.
- Test as the non-root user defined in the image.
- Verify healthchecks and readiness endpoints.

## Compose

```sh
docker compose config
docker compose build
docker compose up
docker compose logs -f api
docker compose down
```

- `config` catches syntax, interpolation, and merge errors without starting services.
- Test healthcheck ordering and dependency startup.
- Confirm volumes and networks are as intended.
- Use `docker compose down -v` only when deleting data is explicitly intended.

## Linting and scanning

```sh
hadolint Dockerfile
docker scout quickview app:dev
docker scout cves app:dev
trivy image --severity HIGH,CRITICAL app:dev
```

If Docker is unavailable, use the project's container tooling (Podman, nerdctl, Buildah)
or CI. Do not claim a build was verified if no container runtime was available.

## Debugging

```sh
docker ps -a
docker logs <container>
docker inspect <container>
docker exec -it <container> sh
docker stats
docker events
```

- `docker inspect` can reveal environment variables and mounts; redact secrets before
  sharing output.
- Check exit codes; `137` usually means SIGKILL/OOM, `143` means SIGTERM.
- Inspect image config with `docker image inspect`.
- Use `docker diff` to see filesystem changes in a container.
- Use `docker compose config --services` to list resolved services.

## Cleanup

```sh
docker container prune
docker image prune
docker builder prune
```

These affect the shared daemon. Confirm before pruning, especially on a developer or CI
machine with other workloads.

## Before finishing

- The image builds with the repository's standard command.
- The container starts and serves its expected endpoint.
- No secrets or build-only files are in the final image.
- Lint/scan findings are addressed or documented.
- Compose config validates if a Compose file changed.
