# Type safety

## Prefer precise types over assertions

- Use `unknown` for untrusted input, then narrow it. `any` disables checking and spreads
  through the codebase.
- Replace `as Foo` with a type guard, a parser/schema, or a corrected type definition.
- Avoid `!` unless the invariant is guaranteed by construction and documented. Prefer
  explicit checks that produce a useful error.
- Avoid `@ts-ignore`. If a third-party type is wrong, use a narrowly scoped
  `@ts-expect-error` with a comment explaining why, and remove it when upstream is fixed.

## Narrowing

Use discriminated unions and exhaustive checks:

```ts
type Result =
  | { ok: true; value: string }
  | { ok: false; error: Error };

function unwrap(result: Result): string {
  if (result.ok) return result.value;
  throw result.error;
}
```

For exhaustiveness:

```ts
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${String(value)}`);
}
```

Prefer `in` checks, `typeof`, `instanceof`, and user-defined guards over casting. A guard
must return a type predicate only when the runtime check actually proves the type.

## Generics

- Constrain generics to the minimum needed: `<T extends { id: string }>`.
- Avoid unconstrained `<T>` when the function does not use `T` meaningfully.
- Use defaults for optional type parameters: `<T = unknown>`.
- Do not use generics to model a fixed set of variants; use a union instead.
- For object transformations, preserve keys with mapped types rather than widening to
  `Record<string, unknown>`.

## Object and literal types

- `satisfies` validates a value without widening it:

  ```ts
  const routes = {
    home: "/",
    user: "/users/:id",
  } satisfies Record<string, `/${string}`>;
  ```

- `as const` preserves literal types for lookup tables and tuple-like arrays.
- `readonly` communicates intent at API boundaries. Avoid deep readonly unless the
  project already uses it.
- Prefer interfaces for extendable public object shapes and type aliases for unions,
  intersections, and mapped types. Follow local convention.

## Boundaries and validation

- Validate JSON, HTTP payloads, environment variables, and database rows at the edge.
- Convert parsed data into domain types once, then keep the interior typed.
- Keep `Date`, `URL`, and other rich objects out of serialized DTOs unless the project
  has an established convention.
- Use branded types only when an ID mix-up is a realistic bug class; they add ceremony.

## Errors

- Prefer typed error unions or project error classes over throwing arbitrary strings.
- Do not widen caught errors to `any`. Use `unknown` and narrow:

  ```ts
  try {
    await run();
  } catch (error) {
    if (error instanceof Error) report(error);
    else throw error;
  }
  ```

## Declarations and modules

- Put ambient declarations in `.d.ts` files included by the relevant tsconfig.
- Use `declare module` only for untyped third-party modules; keep the shim minimal.
- Prefer `import type` for type-only imports when `verbatimModuleSyntax` or
  `importsNotUsedAsValues` is enabled.
- Do not edit generated `.d.ts` output by hand.
