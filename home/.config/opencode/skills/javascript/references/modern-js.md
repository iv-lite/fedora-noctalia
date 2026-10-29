# Modern JavaScript

## Modules

### ESM

- `import`/`export` are statically analyzed and hoisted. Imports are read-only bindings.
- Relative imports in Node ESM require the file extension: `import "./util.js"`.
- Top-level `await` is available in ESM modules.
- `import.meta.url` is the portable way to locate the current module; convert with
  `fileURLToPath` when working with filesystem paths.
- Dynamic `import()` returns a promise and works in both ESM and CJS.

### CommonJS

- `require` is synchronous and can appear anywhere.
- `module.exports` and `exports` are not the same binding after reassignment.
- CJS can `require()` ESM only in newer Node versions with restrictions; prefer dynamic
  `import()` for ESM-only dependencies.
- Do not use top-level `await` in CJS.

### Package boundary

`package.json` controls resolution:

```json
{
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    },
    "./package.json": "./package.json"
  }
}
```

- `exports` blocks deep imports that are not listed. Add subpath exports deliberately.
- Keep `main`, `module`, `types`, and `exports` consistent.
- Test both `import` and `require` entrypoints if the package advertises both.
- `imports` provides internal aliases beginning with `#`.

## Async

- Prefer `async`/`await` over long `.then()` chains, but return promises from functions
  that do not need to await.
- Use `Promise.all` for independent work; `Promise.allSettled` when partial failure is
  acceptable; `Promise.race`/`Promise.any` only when the semantics are intended.
- Avoid `await` inside loops when operations are independent.
- `await` in a `forEach` callback does not pause the loop. Use `for...of` or
  `Promise.all(items.map(...))`.
- Wrap timers, I/O, and fetch calls with `AbortController` when cancellation matters.
- Always handle `unhandledRejection` at process boundaries; do not rely on it for normal
  control flow.

## Language features worth using

- Optional chaining `?.` and nullish coalescing `??`; do not confuse `??` with `||`
  when `0`, `""`, or `false` are valid values.
- `structuredClone` for deep copies of supported values; it does not clone functions or
  class instances.
- `Object.hasOwn(obj, key)` instead of `obj.hasOwnProperty(key)`.
- `Array.prototype.at`, `findLast`, `toSorted`, `toReversed`, `toSpliced`, `with` when
  targets allow; otherwise use the established helper library.
- Private class fields `#field` for true encapsulation.
- `Intl` for dates, numbers, relative time, lists, and collation.
- `AbortSignal.timeout(ms)` for simple timeouts where supported.

## Iteration and data

- `for...of` works with iterables; `for...in` enumerates keys and should not be used for
  arrays.
- Generators are useful for lazy sequences and custom iteration.
- Prefer `Map`/`Set` for frequent membership checks and non-string keys.
- Be explicit about whether an operation mutates or returns a copy. Follow the local
  convention rather than mixing styles.

## Errors

- Throw `Error` objects, not strings.
- Add `cause` when wrapping: `new Error("failed to load config", { cause: error })`.
- Do not swallow errors with empty `catch` blocks. Log, translate, or rethrow.
- Distinguish expected validation failures from programming errors.
