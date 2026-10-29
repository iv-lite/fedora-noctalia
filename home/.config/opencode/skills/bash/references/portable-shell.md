# Portable shell

## Choose the target

- `#!/bin/sh` means POSIX shell. Do not use arrays, `[[ ]]`, `local`, `pipefail`,
  process substitution, `${var//pattern/replacement}`, or `$'...'` quoting.
- `#!/usr/bin/env bash` means Bash. Prefer `env bash` over a hard-coded `/bin/bash` path.
- `#!/usr/bin/env zsh` is not portable to Bash; zsh has different word-splitting and
  array semantics.
- If the script runs in Alpine or a minimal container, verify that Bash exists; often only
  BusyBox `sh` is available.
- macOS ships Bash 3.2. Avoid associative arrays, `mapfile`, `${var^^}`, and other Bash 4+
  features unless the script installs or requires a newer Bash.

## Quoting

```sh
name="world"
printf 'hello %s\n' "$name"

for arg in "$@"; do
  printf '%s\n' "$arg"
done
```

- Unquoted `$var` undergoes word splitting and globbing.
- `"$@"` preserves argument boundaries; `"$*"` joins them with the first IFS character.
- `"${array[@]}"` expands one argument per element.
- Use `--` before user-supplied operands: `rm -- "$file"`.
- Single quotes preserve everything; double quotes allow expansion. Never use unquoted
  variables in filenames or command arguments.

## Tests

Bash:

```sh
if [[ -f "$file" && -r "$file" ]]; then
  ...
fi
```

POSIX:

```sh
if [ -f "$file" ] && [ -r "$file" ]; then
  ...
fi
```

- `[[ ]]` supports pattern matching and does not word-split.
- Use `-n`/`-z` for string emptiness, `-eq`/`-ne` for numbers, `=`/`!=` for strings.
- `(( ))` is Bash arithmetic; POSIX uses `$(( ))`.

## Arrays (Bash)

```sh
items=(one "two words" three)
items+=("four")
printf '%s\n' "${items[@]}"
printf '%s\n' "${#items[@]}"
```

- Array indices are sparse; `${!items[@]}` lists existing indices.
- `${items[*]}` joins with IFS; usually not what you want.
- Bash 3.2 lacks associative arrays (`declare -A`).

## Parameter expansion

```sh
"${var:-default}"     # default if unset or empty
"${var:=default}"     # assign default if unset or empty
"${var:?message}"     # error if unset or empty
"${var#prefix}"       # remove shortest prefix
"${var##prefix}"      # remove longest prefix
"${var%suffix}"       # remove shortest suffix
"${var%%suffix}"      # remove longest suffix
"${var/old/new}"      # replace first (Bash)
"${var//old/new}"     # replace all (Bash)
```

Use `${var:?}` for required configuration so scripts fail loudly instead of continuing
with empty values.

## Globbing and files

- Quote globs you do not want expanded; leave them unquoted when expansion is intended.
- `nullglob` and `failglob` change behavior; set them deliberately in Bash.
- `find . -type f -print0 | while IFS= read -r -d '' file; do ...; done` is safe for
  arbitrary filenames.
- `for file in *.txt` is safe only when the glob may legitimately match nothing and the
  shell's no-match behavior is understood.
- Avoid `ls` in scripts. Use globs or `find`.

## Portability checklist

- Shebang matches the features used.
- No Bashisms in `sh` scripts.
- No GNU-only flags if BSD/macOS support is required (`sed -i`, `readlink -f`,
  `date -d`, `grep -P`, `stat -c`).
- `printf` instead of `echo -e` for portable escapes.
- `command -v` instead of `which`.
- `${TMPDIR:-/tmp}` instead of a hard-coded temp path.
