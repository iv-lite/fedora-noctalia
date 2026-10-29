# Verification and error triage

## Command matrix

| Tool | Command |
| --- | --- |
| npm | `npx tsc --noEmit` |
| pnpm | `pnpm exec tsc --noEmit` |
| yarn | `yarn tsc --noEmit` |
| bun | `bunx tsc --noEmit` |
| project references | `npx tsc -b` |
| specific config | `npx tsc --noEmit -p path/to/tsconfig.json` |
| inspect config | `npx tsc --showConfig` |

Run the repository's own `test`, `lint`, and `build` scripts after the typecheck. If a
script fans out across a monorepo, prefer the scoped version for the package being
changed, then run the fan-out before declaring completion.

## Triage workflow

1. Read the first error in each file, not just the count. Later errors are often
   consequences of the first.
2. Jump to the reported location and inspect the actual inferred types. If needed, use a
   temporary type assertion to `never` or a hover in the editor to reveal the type.
3. Decide whether the type definition or the implementation is wrong. Fix the source of
   truth rather than casting at the use site.
4. Re-run the typecheck after each fix to avoid chasing cascading errors.
5. Run tests to catch behavior changes the type system cannot see.

## Common error codes

| Code | Meaning | Typical fix |
| --- | --- | --- |
| `TS2322` | Type not assignable | Correct the value or the target type |
| `TS2345` | Argument type mismatch | Fix the argument, overload, or generic |
| `TS2339` | Property does not exist | Fix the type, narrow, or correct the property name |
| `TS2307` | Cannot find module | Fix path, dependency, `paths`, or resolution mode |
| `TS18048` | Possibly undefined | Add a guard or default |
| `TS2532` | Object possibly undefined | Narrow before access |
| `TS2769` | No overload matches | Inspect overloads and argument shapes |
| `TS7006` | Implicit any parameter | Annotate or type the callback |
| `TS7031` | Binding element implicit any | Type the destructured source |
| `TS1479` | CJS/ESM import mismatch | Align `module`, package `type`, and file extension |
| `TS1259` | Module can only be default-imported with esModuleInterop | Fix import style or config |
| `TS7016` | Missing declaration file | Install `@types/*` or add a minimal shim |

## Monorepos

- Typecheck the changed package first, then its dependents.
- Use the workspace tool's filter syntax, e.g. `pnpm --filter <pkg> typecheck`,
  `turbo run typecheck --filter=<pkg>`, or `nx run <pkg>:typecheck`.
- Shared config changes require a full `tsc -b` or repository-wide typecheck.
- Do not "fix" cross-package errors by adding path aliases that bypass package exports.

## Before finishing

- Typecheck passes.
- Relevant tests pass.
- Lint/format pass or the repository has no such checks.
- No new `any`, `@ts-ignore`, or unexplained assertions were introduced.
- Generated files were not edited manually.
