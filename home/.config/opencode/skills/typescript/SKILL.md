---
name: TypeScript
description: Use when working in TypeScript codebases on type errors, tsconfig and module resolution, API or type design, refactors, builds, linting, or tests.
---

# TypeScript

## Scope

Use this skill for `.ts`, `.tsx`, `.mts`, and `.cts` code, plus declaration files and
TypeScript build configuration. It covers type-level design, compiler configuration,
diagnostics, and verification. It does not replace framework-specific skills; combine it
with the project's React, Node, or monorepo conventions.

## First steps

1. Identify the package manager and scripts from `package.json`, the lockfile
   (`pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `package-lock.json`), and workspace files.
2. Read the `tsconfig.json` chain. Check `extends`, project references, `strict` flags,
   `module`, `moduleResolution`, `target`, `paths`, and `noEmit`.
3. Identify the runtime and framework: Node, Bun, Deno, browser, React/Next, Vue, etc.
4. Find the existing verification commands before inventing new ones.
5. If LSP diagnostics are available, use them as an early signal, but always confirm with
   the project's own typecheck/test commands.

## Working rules

- Fix the cause of a type error instead of suppressing it. Avoid introducing `any`,
  `@ts-ignore`, or non-null assertions to make errors disappear.
- Preserve public types and runtime behavior unless the task explicitly changes them.
- Prefer narrow, local edits. Re-run the typechecker after each meaningful change.
- Respect the repository's module system. Do not mix ESM and CJS styles casually.
- Prefer `unknown` at boundaries, then narrow with user-defined type guards or schema
  validation.
- Keep generated files and declaration output out of source edits unless the project
  commits them.
- Follow existing naming, formatting, and export conventions.

## Verification

Use the package manager the repository already uses:

```sh
# npm
npx tsc --noEmit

# pnpm
pnpm exec tsc --noEmit

# yarn
yarn tsc --noEmit

# bun
bunx tsc --noEmit
```

For composite or project-reference builds, prefer:

```sh
npx tsc -b
```

Also run the narrowest relevant project checks:

```sh
npm test
npm run lint
npm run build
```

If the repository uses a wrapper, task runner, or monorepo tool (Turbo, Nx, Bazel,
moon), use its documented command instead. See `references/verification.md` for error
triage and monorepo notes.

## References

- `references/type-safety.md` — narrowing, generics, unions, `satisfies`, declarations.
- `references/tsconfig.md` — compiler options, module resolution, project references.
- `references/verification.md` — command matrix, common error codes, monorepo checks.
