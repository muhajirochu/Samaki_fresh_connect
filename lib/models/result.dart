// Sealed Result type used by the Map feature's services.
//
// Services in this module do not throw — they return a `Result<T, F>` so the
// provider can branch on the failure kind without try/catch noise. The shape
// follows Rust's `Result` and Dart 3's sealed classes.

/// A value that is either a success ([Ok]) carrying [T] or a failure
/// ([Err]) carrying a typed [F] reason.
sealed class Result<T, F> {
  const Result();

  /// Convenience constructor for the success branch.
  const factory Result.ok(T value) = Ok<T, F>;

  /// Convenience constructor for the failure branch.
  const factory Result.err(F failure) = Err<T, F>;

  /// True when this is [Ok].
  bool get isOk => this is Ok<T, F>;

  /// True when this is [Err].
  bool get isErr => this is Err<T, F>;

  /// Pattern-match helper. Pass a function for each branch.
  R fold<R>({required R Function(T value) ok, required R Function(F failure) err}) {
    final self = this;
    if (self is Ok<T, F>) return ok(self.value);
    if (self is Err<T, F>) return err(self.failure);
    throw StateError('Unreachable: $self');
  }
}

/// Successful [Result] carrying [value].
final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T, F> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

/// Failed [Result] carrying [failure].
final class Err<T, F> extends Result<T, F> {
  const Err(this.failure);
  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T, F> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
