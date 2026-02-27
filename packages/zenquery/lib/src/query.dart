import 'package:riverpod/riverpod.dart';
import 'package:riverpod/misc.dart';

/// Creates a [FutureProvider] that automatically disposes of its state when listener count reaches zero.
///
/// This is the standard way to create a query that fetches data asynchronously.
///
/// [query] is a function that returns the future containing the data.
FutureProvider<T> createQuery<T>(Future<T> Function(Ref ref) query) =>
    FutureProvider.autoDispose((ref) => query(ref));

/// Creates a [FutureProvider] that persists its state even when there are no listeners.
///
/// Use this if you want to cache the result of the query and keep it available even if no widget is watching it.
///
/// [query] is a function that returns the future containing the data.
FutureProvider<T> createQueryPersist<T>(Future<T> Function(Ref ref) query) =>
    FutureProvider((ref) => query(ref));

/// Creates a [FutureProviderFamily] that automatically disposes of its state when listener count reaches zero.
///
/// This allows creating a family of queries based on a parameter.
///
/// [query] is a function that returns the future, receiving the [Ref] and the parameter.
FutureProviderFamily<T, TParam> createQueryFamily<T, TParam>(
  Future<T> Function(Ref ref, TParam param) query,
) => FutureProvider.autoDispose.family((ref, param) => query(ref, param));

/// Creates a [FutureProviderFamily] that persists its state even when there are no listeners.
///
/// This allows creating a family of persistent queries based on a parameter.
///
/// [query] is a function that returns the future, receiving the [Ref] and the parameter.
FutureProviderFamily<T, TParam> createQueryFamilyPersist<T, TParam>(
  Future<T> Function(Ref ref, TParam param) query,
) => FutureProvider.family((ref, param) => query(ref, param));

/// Creates an [AsyncNotifierProvider] for a [QueryEditable].
///
/// This provides a query whose state can be manually modified (e.g., set to loading, error, or updated data).
/// It automatically disposes of its state when unused.
///
/// [query] is a function that returns the initial future data.
AsyncNotifierProvider<QueryEditable<NResult>, NResult>
createQueryEditable<NResult>(Future<NResult> Function(Ref ref) query) =>
    AsyncNotifierProvider.autoDispose<QueryEditable<NResult>, NResult>(
      () => QueryEditable(query),
    );

/// Creates an [AsyncNotifierProvider] for a [QueryEditable] that persists its state.
///
/// [query] is a function that returns the initial future data.
AsyncNotifierProvider<QueryEditable<NResult>, NResult>
createQueryEditablePersist<NResult>(Future<NResult> Function(Ref ref) query) =>
    AsyncNotifierProvider<QueryEditable<NResult>, NResult>(
      () => QueryEditable(query),
    );

/// Creates an [AsyncNotifierProviderFamily] for a [QueryEditableFamily].
///
/// This allows creating a family of editable queries based on a parameter, automatically disposing when unused.
///
/// [query] is a function that returns the initial future data, receiving the [Ref] and the parameter.
AsyncNotifierProviderFamily<
  QueryEditableFamily<NResult, NParam>,
  NResult,
  NParam
>
createQueryEditableFamily<NResult, NParam>(
  Future<NResult> Function(Ref ref, NParam param) query,
) => AsyncNotifierProvider.autoDispose
    .family<QueryEditableFamily<NResult, NParam>, NResult, NParam>(
      (param) => QueryEditableFamily(query, param),
    );

/// Creates an [AsyncNotifierProviderFamily] for a [QueryEditableFamily] that persists its state.
///
/// [query] is a function that returns the initial future data, receiving the [Ref] and the parameter.
AsyncNotifierProviderFamily<
  QueryEditableFamily<NResult, NParam>,
  NResult,
  NParam
>
createQueryEditableFamilyPersist<NResult, NParam>(
  Future<NResult> Function(Ref ref, NParam param) query,
) => AsyncNotifierProvider.family<
  QueryEditableFamily<NResult, NParam>,
  NResult,
  NParam
>((param) => QueryEditableFamily(query, param));

/// An [AsyncNotifier] that allows manual modification of its state.
///
/// This is useful for optimistic updates or scenarios where you need to manually control the query state.
class QueryEditable<NResult> extends AsyncNotifier<NResult> {
  QueryEditable(this.query);

  /// The function to fetch the initial data.
  final Future<NResult> Function(Ref ref) query;

  @override
  Future<NResult> build() async => query(ref);

  /// Manually sets the state to [AsyncValue.data] with the given [value].
  void setValue(NResult value) => state = AsyncValue.data(value);

  /// Manually sets the state to [AsyncValue.error] with the given [error] and [stackTrace].
  void setError(Object error, StackTrace stackTrace) =>
      state = AsyncValue.error(error, stackTrace);

  /// Manually sets the state to [AsyncValue.loading].
  ///
  /// Optionally accepts a [progress] value.
  void setLoading([num progress = 0]) =>
      state = AsyncValue.loading(progress: progress);
}

/// An [AsyncNotifier] for a family of editable queries.
class QueryEditableFamily<NResult, NParam> extends AsyncNotifier<NResult> {
  QueryEditableFamily(this.query, this.param);

  /// The function to fetch the initial data.
  final Future<NResult> Function(Ref ref, NParam param) query;

  /// The parameter associated with this query instance.
  final NParam param;

  @override
  Future<NResult> build() async => query(ref, param);

  /// Manually sets the state to [AsyncValue.data] with the given [value].
  void setValue(NResult value) => state = AsyncValue.data(value);

  /// Manually sets the state to [AsyncValue.error] with the given [error] and [stackTrace].
  void setError(Object error, StackTrace stackTrace) =>
      state = AsyncValue.error(error, stackTrace);

  /// Manually sets the state to [AsyncValue.loading].
  ///
  /// Optionally accepts a [progress] value.
  void setLoading([num progress = 0]) =>
      state = AsyncValue.loading(progress: progress);
}
