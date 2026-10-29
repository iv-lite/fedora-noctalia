---
name: Docker
description: Use when writing or reviewing Dockerfiles, Compose files, container build workflows, image security, or debugging containerized applications.
---

# Docker

## Scope

Use this skill for Dockerfiles, `.dockerignore`, Compose files, container images,
multi-stage builds, local container workflows, and image security. Combine it with the
Kubernetes or Helm skills when the image is deployed to a cluster.

## First steps

1. Find the Dockerfile, Compose file, build scripts, and image references.
2. Determine the target platform(s), base image policy, and registry.
3. Identify how the app is built and started outside the container.
4. Check whether the repository uses BuildKit, Buildx, Compose, Podman, nerdctl, or a
   remote builder.
5. Read existing `.dockerignore` and security/lint configuration.

## Working rules

- Keep images minimal and reproducible. Pin base image versions; prefer digests for
  critical builds.
- Order layers from least to most frequently changing for cache efficiency.
- Use multi-stage builds to keep compilers and package managers out of the runtime image.
- Run as a non-root user unless the image has a documented reason not to.
- Never bake secrets into images or build args. Use BuildKit secrets or runtime secret
  injection.
- Use `ENTRYPOINT` for the executable and `CMD` for default arguments.
- Handle signals correctly: the main process must receive `SIGTERM`; avoid shell-form
  `CMD` when it prevents that.
- Pin dependencies in a lockfile and use deterministic install commands.
- Keep `.dockerignore` aligned with the build context.

## Verification

```sh
docker build -t app:dev .
docker run --rm app:dev
docker compose config
```

If available:

```sh
hadolint Dockerfile
docker scout quickview app:dev
trivy image app:dev
```

See `references/verification.md` for build, runtime, and cleanup checks.

## References

- `references/dockerfile.md` — layer design, multi-stage builds, runtime hardening.
- `references/compose-and-security.md` — Compose, secrets, scanning, registries.
- `references/verification.md` — build/run checks, linting, debugging, cleanup.
