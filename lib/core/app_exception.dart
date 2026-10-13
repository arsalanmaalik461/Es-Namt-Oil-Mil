/// Application-wide exception model (pure Dart, no Flutter imports).
///
/// [messageKey] is a localisation key (e.g. `'error.insufficientStock'`),
/// never a human-readable sentence, so the UI layer can translate it.
/// Optional [params] carry interpolation values for the localised string.
///
/// UI rule: catch [AppException] at the screen level and show the translated
/// message. Never show `exception.toString()` to the user.
class AppException implements Exception {
  /// Localisation key for the error message.
  final String messageKey;

  /// Interpolation values for the localised message.
  final Map<String, Object?> params;

  const AppException(this.messageKey, [Map<String, Object?>? params])
      : params = params ?? const {};

  @override
  String toString() => 'AppException($messageKey, params: $params)';
}

/// Thrown when a database operation fails.
///
/// Failed DB operations always throw — they never silently report success.
/// The optional [cause] holds the original low-level error for diagnostics
/// (logs only, never shown to the user).
class DatabaseException extends AppException {
  final Object? cause;

  const DatabaseException(super.messageKey, [super.params, this.cause]);

  @override
  String toString() =>
      'DatabaseException($messageKey, params: $params, cause: $cause)';
}

/// Thrown when a business rule is violated (insufficient stock, over-payment,
/// deleting a record that is still referenced, double posting, ...).
///
/// These are *expected* failures the UI should present as validation messages,
/// not crashes.
class ValidationException extends AppException {
  const ValidationException(super.messageKey, [super.params]);

  @override
  String toString() => 'ValidationException($messageKey, params: $params)';
}
