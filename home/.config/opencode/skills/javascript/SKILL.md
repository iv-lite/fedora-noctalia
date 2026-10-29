---
name: JavaScript
description: Use when working in JavaScript codebases on modules, async behavior, runtime compatibility, refactors, package configuration, builds, or tests.
---

# JavaScript

## Scope

Use this skill for `.js`, `.jsx`, `.mjs`, and `.cjs` code, including Node, Bun, Deno,
browser, and bundler-based projects. Use the TypeScript skill when the project uses
TypeScript or `checkJs`; the runtime guidance here still applies.

## First steps

1. Identify the package manager, Node/runtime version, and module format from
   `package.json` (`type`, `exports`, `engines`) and lockfiles.
2. Determine the target environment: Node, Bun, Deno, browser, Electron, serverless, or
   a bundler.
3. Find the test, lint, build, and start commands.
4. Check for existing framework conventions (React, Vue, Svelte, Express, Fastify, etc.).
5. Use LSP diagnostics when available, then confirm with project commands.

## Working rules

- Keep the existing module system. Do not accidentally mix `require` and `import` in the
  same file or package without understanding the interop.
- Handle promises deliberately. Every rejected promise should be awaited, returned, or
  explicitly caught.
- Preserve runtime compatibility. Do not use newer syntax or globals than the declared
  `engines`, browser targets, or bundler config allow.
- Prefer immutable updates and pure helpers when they match the codebase.
- Do not add dependencies for small tasks without checking the existing dependency set.
- Keep CommonJS packages compatible when the project still supports them.
- Follow the repository's formatting and lint rules.

## Verification

Run the project's own scripts first:

```sh
npm test
npm run lint
npm run build
```

Use the equivalent `pnpm`, `yarn`, or `bun` commands when that is the repository's
package manager. For a quick syntax check:

```sh
node --check path/to/file.js
```

For Node's built-in test runner:

```sh
node --test
```

See `references/verification.md` for package validation and runtime-specific checks.

## References

- `references/modern-js.md` — ESM/CJS, package exports, async patterns, language features.
- `references/runtime-pitfalls.md` — Node vs browser behavior, event loop, promises, data.
- `references/verification.md` — syntax, tests, bundles, package exports, validation.
