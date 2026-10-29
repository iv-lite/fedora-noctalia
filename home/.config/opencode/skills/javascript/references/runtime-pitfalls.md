# Runtime pitfalls

## Environment

- Browser code cannot use `fs`, `path`, `process`, or Node built-ins unless the bundler
  provides a shim. Check for accidental Node-only imports in shared modules.
- Node code may not have `window`, `document`, `localStorage`, or DOM globals.
- `fetch`, `URL`, `TextEncoder`, `AbortController`, and `structuredClone` exist in modern
  Node and browsers, but check the declared minimum versions.
- Serverless and edge runtimes often restrict filesystem, long-lived connections, and
  native modules. Confirm before adding dependencies.
- `process.env` values are strings or `undefined`. Parse numbers and booleans explicitly.
- `__dirname` and `__filename` do not exist in ESM; use `import.meta.url` plus
  `fileURLToPath`.

## Event loop and concurrency

- Promises run microtasks after the current synchronous block. `setTimeout` and I/O run
  in later phases.
- A blocked synchronous loop blocks timers, I/O, and rendering.
- `await` yields control; do not assume shared state is unchanged after an await.
- CPU-heavy work belongs in a worker, child process, or off the request path.
- Use bounded concurrency for large batches; unbounded `Promise.all` can exhaust sockets,
  file descriptors, or memory.

## Promises and async

- A floating promise is a bug unless intentionally fire-and-forget with a logged catch.
- `async` functions always return a promise, including thrown errors.
- `return await` inside `try` preserves the stack for the catch; outside `try` it is
  usually redundant.
- `Promise.all` rejects on the first rejection but does not cancel the other operations.
- `Promise.race` does not cancel the losing operations.
- `Array.prototype.forEach` ignores returned promises.
- Event emitters do not await async listeners; errors can escape or become unhandled.

## Values and equality

- `===` avoids coercion surprises; `Object.is` differs for `NaN` and `-0`.
- `NaN !== NaN`; use `Number.isNaN`.
- `typeof null === "object"`; check `value === null` explicitly.
- Falsy values include `0`, `""`, `false`, `null`, `undefined`, and `NaN`. Use explicit
  checks when those are valid.
- `JSON.parse`/`JSON.stringify` do not preserve `undefined`, functions, `BigInt`, `Date`
  identity, `Map`, `Set`, or circular references.
- Sort comparators must return a number; default sort converts to strings.
- `Array.prototype.includes` uses SameValueZero; object identity matters.
- Dates are mutable and timezone-sensitive. Prefer ISO strings or a date library for
  complex work; never rely on the host timezone for business logic.

## Objects and prototypes

- Object keys are strings or symbols. Numeric-looking keys are enumerated in numeric
  order before other string keys.
- Guard against prototype pollution when merging untrusted objects; reject `__proto__`,
  `constructor`, and `prototype` keys or use a safe merge helper.
- `Object.assign` and spread copy enumerable own properties only, shallowly.
- Class methods live on the prototype; destructuring a method loses `this`. Bind it or
  use an arrow function field when a callback is expected.

## Resources

- Close files, streams, database clients, and servers in `finally` or with
  `using`/`await using` if the runtime supports explicit resource management.
- Respect stream backpressure; prefer `pipeline()` over manual `data` handlers.
- Remove event listeners and abort in-flight requests when a component or request ends.
- Long-lived caches need bounds and eviction; otherwise they become memory leaks.
