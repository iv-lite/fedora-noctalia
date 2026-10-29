# tsconfig and module resolution

## Read the whole chain

`tsconfig.json` may extend one or more base configs. Read the effective config rather
than assuming root-level values:

```sh
npx tsc --showConfig
npx tsc --showConfig -p packages/app/tsconfig.json
```

Check for workspace references:

- `references` in the root config
- `composite: true` in referenced projects
- `tsc -b` in build scripts
- path aliases duplicated in bundler or test configs

## Important options

| Option | Effect |
| --- | --- |
| `strict` | Enables the strict family; do not disable to silence errors |
| `noUncheckedIndexedAccess` | Indexed reads become `T \| undefined`; handle missing keys |
| `exactOptionalPropertyTypes` | Distinguishes missing properties from `undefined` |
| `noImplicitOverride` | Requires `override` on subclass members |
| `noFallthroughCasesInSwitch` | Catches missing `break`/`return` |
| `target` | Controls emitted syntax; align with supported runtimes |
| `lib` | Controls available global types; avoid adding DOM to Node code |
| `module` | Output module format; align with runtime and package `type` |
| `moduleResolution` | Resolution algorithm; must match the module ecosystem |
| `verbatimModuleSyntax` | Requires explicit `import type`; preserves import syntax |
| `isolatedModules` | Requires code that transpilers can process file-by-file |
| `noEmit` | Typecheck only; typical for app builds using a bundler |
| `skipLibCheck` | Speeds builds but hides dependency declaration conflicts |
| `paths` | Aliases resolved by TypeScript only; bundlers/tests need matching config |
| `rootDir` / `outDir` | Controls emitted layout; misconfiguration causes nested output |
| `incremental` | Enables `.tsbuildinfo` caching |

## Module resolution guidance

- Node ESM: `module: "NodeNext"`, `moduleResolution: "NodeNext"`, and correct
  `package.json` `type` plus explicit `.js` extensions in relative imports.
- Bundled browser apps: commonly `module: "ESNext"` with `moduleResolution: "Bundler"`.
- Legacy CJS: `module: "CommonJS"` with `moduleResolution: "Node"` or `"Node10"`.
- Do not mix `Bundler` resolution with a Node runtime that requires extensions.
- When adding path aliases, update the bundler, test runner, and lint resolver too.

## Strictness

Enable `strict` plus the project's existing extra checks. If a file newly fails under a
stricter option, fix the code rather than adding a file-level `// @ts-nocheck`.

Common strict failures and fixes:

- `TS18048` ("possibly undefined") — add a real guard or default.
- `TS2532` ("object is possibly undefined") — narrow before access.
- `TS7031` (implicit `any` parameter) — annotate or infer from a typed callback.
- `TS7006` — add the parameter type or type the surrounding function.

## Project references and monorepos

- Build dependencies before dependents: `tsc -b` follows the reference graph.
- Keep `rootDir` inside each package; avoid importing another package's `src` directly
  unless the repository explicitly supports source-level imports.
- Use workspace package names and declared exports, not relative paths across packages.
- If a change affects a shared package, run the dependents' typechecks too.
- Clear stale `.tsbuildinfo` only when diagnosing cache corruption, not as a first step.

## JS projects

`allowJs` and `checkJs` enable checking in JavaScript projects. Do not enable `checkJs`
globally unless the repository is prepared for the resulting errors; prefer targeted
`// @ts-check` at file level or a dedicated config.
