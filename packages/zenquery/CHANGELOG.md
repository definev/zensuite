## 1.0.2

- Expose `Ref` into `fetch` function

## 1.0.1

- Refactored `mutation.dart`: extracted `mutationActionFn` and `mutationActionWithParamFn` helpers to eliminate duplicated logic between auto-dispose and persist variants of `createMutation`, `createMutationPersist`, `createMutationWithParam`, and `createMutationWithParamPersist`.
- Refactored `infinity_query.dart`: extracted `infinityQueryFn` helper reused by both `createInfinityQuery` and `createInfinityQueryPersist`.
- Minor formatting cleanup in `query.dart` and `infinity_query.dart`.

## 1.0.0

- Initial release of ZenQuery.
- Added `ZenQuery` wrapper around Riverpod.
- Added `InfinityQuery` for infinite scrolling support.
- Added `Mutation` support with optimistic updates.