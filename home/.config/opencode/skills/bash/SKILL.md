---
name: Bash
description: Use when writing, reviewing, or debugging Bash and POSIX shell scripts, automation, CI steps, Makefile recipes, or command-line workflows.
---

# Bash

## Scope

Use this skill for `.sh`, `.bash`, `.zsh`, `.ksh` scripts, shebang-based executables,
CI shell steps, and shell snippets in Makefiles or documentation. Prefer POSIX `sh` when
the script must be portable; use Bash features only when the shebang and target
environment guarantee Bash.

## First steps

1. Read the shebang and determine whether the script targets `sh`, `bash`, `zsh`, or a
   specific Bash version.
2. Identify the calling environment: local shell, CI, container, cron, or another script.
3. Check for existing helpers, `set` options, lint config, and formatting conventions.
4. Look for destructive commands (`rm`, `mv`, `chmod`, `dd`, `kubectl delete`, cloud CLI)
   and confirm their scope before changing them.
5. If LSP diagnostics are available, use them, then run the project's shell checks.

## Working rules

- Quote expansions unless word splitting is explicitly required: `"$var"`, `"$@"`,
  `"${array[@]}"`.
- Prefer `[[ ... ]]` in Bash and `[ ... ]` only in POSIX `sh`.
- Use `set -Eeuo pipefail` carefully. `-e` has exceptions, so check exit codes and use
  explicit error handling where behavior matters.
- Use `local` inside functions when the shell supports it; POSIX `sh` does not.
- Avoid parsing `ls`. Use globs, `find -print0`, or `while IFS= read -r`.
- Write to a temporary file and move it into place for atomic updates.
- Clean up with `trap` on `EXIT`, `INT`, and `TERM`.
- Never embed secrets in scripts or logs. Read them from the environment or a secret
  store and avoid `set -x` around sensitive values.
- Prefer idempotent operations for automation.

## Verification

```sh
bash -n script.sh
sh -n script.sh
```

If available:

```sh
shellcheck script.sh
shfmt -d script.sh
```

Run the script's tests (Bats or the project harness) and exercise both the success and
failure paths. See `references/verification.md` for details.

## References

- `references/portable-shell.md` — POSIX vs Bash, quoting, arrays, expansions, globbing.
- `references/scripting-patterns.md` — arguments, traps, temp files, pipelines, logging.
- `references/verification.md` — static checks, debugging, tests, CI safety.
