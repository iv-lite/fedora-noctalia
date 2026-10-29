# Dockerfile design

## Base images

- Pin a version tag, not `latest`. For reproducible production builds, pin a digest:

  ```dockerfile
  FROM node:22.14.0-bookworm-slim@sha256:...
  ```

- Prefer slim/distroless/alpine variants only after checking libc, shell, and native
  dependency compatibility.
- Keep build and runtime stages on compatible base images.
- Document why a non-standard base is required.

## Layer and cache order

```dockerfile
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
USER node
CMD ["node", "dist/server.js"]
```

- Copy dependency manifests and install dependencies before copying the full source.
- Combine related `RUN` steps and clean package-manager caches in the same layer.
- Use `COPY --link` with BuildKit when it improves cache reuse and the target supports it.
- Avoid `ADD` unless extracting a local archive or fetching a URL is explicitly intended.

## Multi-stage builds

- Name stages for readability.
- Copy only required artifacts into the runtime stage.
- Do not copy the entire build stage or source tree into production.
- Use `--from` to select the stage.
- For compiled languages, build static binaries where possible and use a minimal runtime
  image.
- Keep debug symbols in a separate stage if they are needed for troubleshooting.

## Runtime configuration

- Set `WORKDIR` before `COPY`/`RUN`.
- Use `ENV` for non-secret defaults; do not put credentials in `ENV` or `ARG`.
- Prefer exec-form `ENTRYPOINT`/`CMD`:

  ```dockerfile
  ENTRYPOINT ["/app/server"]
  CMD ["--port", "8080"]
  ```

- Ensure PID 1 handles signals or use an init (`--init`, `tini`, `dumb-init`).
- Expose documentation-only ports with `EXPOSE`; it does not publish them.
- Add a `HEALTHCHECK` only when the orchestrator does not provide one; avoid expensive
  checks.
- Use `STOPSIGNAL` when the app expects a signal other than `SIGTERM`.

## Security

- Create or use an unprivileged user and switch with `USER`.
- Set restrictive file permissions for copied artifacts.
- Avoid `sudo`, package managers, and shells in the final image when possible.
- Do not install unnecessary tools.
- Keep the image free of build secrets, `.git`, test fixtures, and local config.
- Use BuildKit secret mounts:

  ```dockerfile
  RUN --mount=type=secret,id=npmrc \
      npm config set //registry.npmjs.org/:_authToken="$(cat /run/secrets/npmrc)"
  ```

- Scan the final image, not only the build stage.

## Build context

`.dockerignore` should exclude:

```text
.git
node_modules
dist
coverage
.env*
*.log
tmp
```

Keep files required by the build. An overly broad ignore causes confusing missing-file
errors; an overly narrow one sends secrets and large directories to the daemon.

## Reproducibility

- Commit lockfiles and use frozen/ci install commands.
- Set `SOURCE_DATE_EPOCH` when the toolchain supports reproducible timestamps.
- Avoid `apt-get upgrade` in application images; rebuild from an updated base instead.
- Pin external downloads by version and checksum.
