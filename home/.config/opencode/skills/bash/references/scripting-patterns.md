# Scripting patterns

## Strict mode

```sh
#!/usr/bin/env bash
set -Eeuo pipefail
```

- `-e` exits on an unhandled failing command, but not inside conditions, `&&`/`||` lists,
  or command substitutions in some contexts.
- `-u` errors on unset variables. Combine with `${var:-}` when optional.
- `-o pipefail` makes a pipeline fail if any stage fails.
- `-E` propagates the `ERR` trap into functions and subshells.

For scripts where `-e` is too blunt, omit it and check commands explicitly:

```sh
if ! command_that_may_fail; then
  printf 'failed\n' >&2
  exit 1
fi
```

## Arguments

```sh
usage() {
  printf 'usage: %s [-n] <input>\n' "${0##*/}" >&2
  exit 2
}

dry_run=0
while getopts ':nh' opt; do
  case "$opt" in
    n) dry_run=1 ;;
    h) usage ;;
    :) printf 'missing argument for -%s\n' "$OPTARG" >&2; usage ;;
    \?) printf 'unknown option: -%s\n' "$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND - 1))

[ "$#" -eq 1 ] || usage
input=$1
```

For long options in Bash, parse manually or use a small helper. Do not silently ignore
unknown arguments.

## Traps and cleanup

```sh
tmpdir=$(mktemp -d)
cleanup() {
  rm -rf -- "$tmpdir"
}
trap cleanup EXIT INT TERM
```

- Create temp files with `mktemp`, never a predictable name in `/tmp`.
- Quote cleanup paths and guard against empty variables: `rm -rf -- "${tmpdir:?}"`.
- Use one `EXIT` trap for all cleanup; multiple traps replace each other.
- Preserve the original exit status if cleanup can fail.

## Logging and errors

```sh
log() { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" >&2; }
die() { log "error: $*"; exit 1; }
```

- Send diagnostics to stderr, data to stdout.
- Avoid `echo -e`; use `printf`.
- Do not log secrets, tokens, full command lines containing credentials, or entire
  environment dumps.
- Include the failing command and exit code where useful.

## Pipelines

- `set -o pipefail` is essential when a pipeline's first command can fail.
- `${PIPESTATUS[@]}` (Bash) exposes each stage's status.
- Avoid `cat file | cmd`; use `cmd < file`.
- `xargs` breaks on spaces and quotes; prefer `-0` with `find -print0`, or a `while read`
  loop.
- Streaming is preferable for large data; avoid collecting everything into a variable.

## Idempotency and safety

- Check before creating: `mkdir -p`, `install -d`, `ln -sfn` only when intended.
- Use `mv` into place for atomic file replacement on the same filesystem.
- Confirm destructive commands with the target path and scope. Never interpolate an
  empty variable into `rm -rf`.
- For retries, bound attempts and use backoff; do not retry non-idempotent operations.
- Use a lock (`flock`) when concurrent runs would corrupt shared state.
- Make dry-run mode available for scripts that change infrastructure or data.

## Shell style

- Prefer functions over deep nesting.
- Use `local` in Bash functions to avoid leaking variables.
- Keep command substitutions quoted: `value=$(command)`.
- Use `$(...)` instead of backticks.
- Use `case` for string dispatch.
- Keep lines readable; long pipelines can be split after `|`.
