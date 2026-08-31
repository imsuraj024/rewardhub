/// Base contract for all domain use cases.
///
/// A use case encapsulates a single unit of business logic. It exposes a
/// [call] method so instances can be invoked like functions:
///
/// ```dart
/// final result = await loginUseCase(LoginParams(phone: phone));
/// ```
///
/// [R] is the value the use case produces and [P] is the input it needs. Use
/// [NoParams] when the use case takes no input.
abstract interface class UseCase<R, P> {
  Future<R> call(P params);
}

/// Placeholder for use cases that require no parameters.
class NoParams {
  const NoParams();
}
