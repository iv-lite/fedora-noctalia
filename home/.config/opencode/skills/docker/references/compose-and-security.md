# Compose, security, and registries

## Compose

- Use the current Compose specification; do not add the legacy `version:` key.
- Keep service names stable; they become DNS names on the Compose network.
- Use `healthcheck` plus `depends_on: condition: service_healthy` for real readiness
  ordering. Plain `depends_on` only waits for container start.
- Mount source code with bind mounts for development and named volumes for persistent
  data.
- Do not mount the Docker socket unless absolutely required; it grants host-level
  control.
- Use `profiles` to keep optional services out of the default stack.
- Set `restart` policies deliberately; `always` can hide crash loops in development.
- Use `env_file` for non-secret local defaults and explicit environment for secrets.
- Avoid publishing ports on `0.0.0.0` unless remote access is intended.

Example:

```yaml
services:
  api:
    build:
      context: .
      target: runtime
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      DATABASE_URL: postgres://app:app@db:5432/app
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:8080/healthz"]
      interval: 10s
      timeout: 3s
      retries: 5
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      timeout: 3s
      retries: 10
volumes:
  db-data:
```

## Secrets

- Never commit `.env` files containing real credentials.
- Do not pass secrets as build args; they persist in image history.
- Prefer BuildKit secret mounts for builds.
- At runtime, use the platform's secret mechanism: Compose `secrets`, Kubernetes Secrets,
  a vault, or environment injection from a secret manager.
- Avoid `docker inspect` output in logs when environment variables contain secrets.
- Rotate any secret that was accidentally committed or baked into an image.

## Resource limits

- Set CPU and memory limits in production orchestrators, not only locally.
- In Compose, `deploy.resources` is honored by Swarm and partially by Compose; verify the
  target runtime.
- Leave headroom for the runtime and sidecars.
- Test under the same limits as production; a container that OOMs at 512 MiB locally will
  also OOM in the cluster.

## Image security

- Scan the final image with Trivy, Grype, Docker Scout, or the registry's scanner.
- Generate an SBOM where the supply chain requires it.
- Rebuild regularly to pick up base-image security updates.
- Minimize packages and remove package-manager caches.
- Verify image signatures or provenance if the registry supports it.
- Use a private registry with authentication for internal images.
- Never pull untrusted images with `--privileged`.

## Registries

```sh
docker login registry.example.com
docker tag app:dev registry.example.com/team/app:1.2.3
docker push registry.example.com/team/app:1.2.3
```

- Tag immutably for releases; avoid overwriting production tags.
- Use `docker buildx build --platform linux/amd64,linux/arm64 --push` for multi-arch.
- Prefer OCI images and standard media types.
- Configure credential helpers rather than storing plaintext credentials.
- Clean up local images and build cache intentionally; do not prune shared machines
  without confirmation.
