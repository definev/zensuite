import 'package:riverpod/riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';

/// Encapsulate a mutation's state and actions.
class MutationAction<T> {
  MutationAction(this.mutation, this.run, this.reset);

  /// The underlying [Mutation] object holding the state.
  final Mutation<T> mutation;

  /// Function to execute the mutation.
  final Future<T> Function() run;

  /// Function to reset the mutation state.
  final void Function() reset;
}

/// Encapsulate a mutation's state and actions, expecting a parameter.
class MutationActionWithParam<T, TParam> {
  MutationActionWithParam(this.mutation, this.run, this.reset);

  /// The underlying [Mutation] object holding the state, keyed by the parameter.
  final Mutation<T> Function(TParam payload) mutation;

  /// Function to execute the mutation with the given parameter.
  final Future<T> Function(TParam payload) run;

  /// Function to reset the mutation state for the given parameter.
  final void Function(TParam payload) reset;
}

MutationAction<T> Function(Ref ref) mutationActionFn<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => (ref) {
  final state = Mutation<T>();
  return MutationAction(
    state,
    () => state.run(ref, (tsx) => action(tsx)),
    () => state.reset(ref),
  );
};

/// Creates a [Provider] for a [MutationAction] that automatically disposes when unused.
///
/// [action] is the function to execute when the mutation is triggered.
Provider<MutationAction<T>> createMutation<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => Provider.autoDispose<MutationAction<T>>(mutationActionFn<T>(action));

/// Creates a [Provider] for a [MutationAction] that persists its state.
///
/// [action] is the function to execute when the mutation is triggered.
Provider<MutationAction<T>> createMutationPersist<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => Provider<MutationAction<T>>(mutationActionFn<T>(action));

MutationActionWithParam<T, TParam> Function(Ref ref) mutationActionWithParamFn<
  T,
  TParam
>(Future<T> Function(MutationTransaction tsx, TParam payload) action) => (ref) {
  final state = Mutation<T>();
  final mutationMap = <TParam, Mutation<T>>{};
  ref.onDispose(() => mutationMap.clear());
  return MutationActionWithParam(
    (param) => mutationMap.putIfAbsent(param, () => state(param)),
    (param) => mutationMap
        .putIfAbsent(param, () => state(param))
        .run(ref, (tsx) => action(tsx, param)),
    (param) => mutationMap.putIfAbsent(param, () => state(param)).reset(ref),
  );
};

/// Creates a [Provider] for a [MutationActionWithParam] that automatically disposes when unused.
///
/// This mutation accepts a parameter when executed.
///
/// [action] is the function to execute.
Provider<MutationActionWithParam<T, TParam>> createMutationWithParam<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) => Provider.autoDispose<MutationActionWithParam<T, TParam>>(
  mutationActionWithParamFn<T, TParam>(action),
);

/// Creates a [Provider] for a [MutationActionWithParam] that persists its state.
///
/// This mutation accepts a parameter when executed.
///
/// [action] is the function to execute.
Provider<MutationActionWithParam<T, TParam>> createMutationWithParamPersist<
  T,
  TParam
>(Future<T> Function(MutationTransaction tsx, TParam payload) action) =>
    Provider<MutationActionWithParam<T, TParam>>(
      mutationActionWithParamFn<T, TParam>(action),
    );
