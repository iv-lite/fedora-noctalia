# Verification and debugging

## Static checks

```sh
bash -n script.sh
sh -n script.sh
```

`-n` parses without executing. It catches syntax errors but not missing commands or
runtime failures.

If ShellCheck is available:

```sh
shellcheck script.sh
shellcheck -s sh script.sh
shellcheck -x script.sh   # follow sourced files
```

Common ShellCheck findings:

- `SC2086` — unquoted expansion.
- `SC2046` — unquoted command substitution.
- `SC2181` — check `$?` indirectly instead of using `if`.
- `SC2317` — unreachable command.
- `SC2155` — declare and assign separately to preserve exit status.
- `SC1090`/`SC1091` — non-constant or missing sourced file.

Formatting:

```sh
shfmt -d script.sh
shfmt -w script.sh
```

Only apply `-w` when the repository uses shfmt and the diff is acceptable.

## Runtime debugging

```sh
bash -x script.sh          # trace commands
bash -u script.sh          # error on unset variables
bash -o pipefail script.sh
```

- Run with `set -x` around the suspect region, not the whole script, when secrets are
  involved.
- Use `PS4='+ ${BASH_SOURCE}:${LINENO}: '` for better trace locations.
- Add an `ERR` trap to print the failing line:

  ```sh
  trap 'printf "failed at %s:%s: %s\n" "$BASH_SOURCE" "$LINENO" "$BASH_COMMAND" >&2' ERR
  ```

- Test from a different working directory to catch relative-path assumptions.
- Test with paths containing spaces and leading dashes.

## Tests

- Bats is common for Bash; use the repository's existing harness if one exists.
- Test success, failure, missing arguments, empty input, and paths with spaces.
- Mock external commands with a temporary `PATH` shim rather than hitting real services.
- Verify cleanup leaves no temp files and preserves the expected exit code.
- For CI scripts, run the same shell and flags CI uses.

## CI and container checks

- Confirm the shell exists in the target image (`bash` vs `sh` vs BusyBox).
- Check line endings; CRLF breaks shebangs and `set -e` scripts.
- Verify executable bits if scripts are invoked directly.
- Avoid interactive prompts and pagers (`GIT_PAGER=cat`, `--no-pager`, `-y` where safe).
- Ensure the script does not depend on a developer's shell profile.
- Run with the same user and permissions as production/CI where feasible.

## Before finishing

- `bash -n` or `sh -n` passes.
- ShellCheck passes or findings are understood and documented.
- Relevant tests pass.
- Destructive paths are quoted and guarded.
- No secrets appear in logs, traces, or committed files.
