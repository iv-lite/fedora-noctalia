# Verification

## Fast checks

```sh
node --check path/to/file.js
node --check path/to/file.mjs
```

`--check` parses the file but does not execute it or resolve imports. For ESM with
top-level await, ensure the file is actually treated as a module.

## Project checks

Prefer the repository's scripts:

```sh
npm test
npm run lint
npm run typecheck
npm run build
```

Use `pnpm`, `yarn`, or `bun` equivalents when that is the repository's package manager.
Run the narrowest test file first, then the full suite if the change is broad.

## Built-in test runner

```sh
node --test
node --test path/to/file.test.js
node --test --watch
```

Check the minimum Node version before relying on newer test-runner flags.

## Bundles and browser code

- Run the production build, not only the dev server.
- Check for Node built-in imports leaking into browser bundles.
- Verify the supported browser targets and polyfill strategy.
- Test both development and production modes when behavior differs.
- If the project uses SSR, verify server and client entrypoints separately.

## Package validation

For a library:

```sh
npm pack --dry-run
```

Check that:

- `files` includes the built output and required metadata.
- `exports`, `main`, `module`, and `types` point at files that exist.
- Both `import` and `require` consumers can load the package if both are advertised.
- No source, test, or secret files are published unintentionally.

If the package is already packed, install it into a temporary project and test the
public entrypoints rather than importing from the source tree.

## Runtime-specific checks

- **Node:** verify the declared `engines.node` range; test on the lowest supported major
  when feasible.
- **Bun:** verify Bun-specific APIs are guarded or the package declares Bun support.
- **Deno:** check permissions and import specifiers; Deno does not use `node_modules` by
  default.
- **Browser:** check console errors, network failures, and hydration warnings.
- **Serverless/edge:** confirm no unsupported filesystem, native module, or long-lived
  connection assumptions.

## Before finishing

- Syntax check passes.
- Relevant tests pass.
- Lint/format pass or are not configured.
- Production build succeeds for build-based projects.
- No new runtime compatibility violations were introduced.
