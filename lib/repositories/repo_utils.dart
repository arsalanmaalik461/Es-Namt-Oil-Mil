import '../core/app_exception.dart';
import '../utils/time.dart';

/// Shared helpers for repositories (internal use).
///
/// Every repository wraps its DB calls in [guard] so failures surface as
/// [DatabaseException] — failed operations throw, never silently succeed.
/// [AppException]s (e.g. [ValidationException]) pass through untouched.
Future<T> guard<T>(String entity, Future<T> Function() fn) async {
  try {
    return await fn();
  } on AppException {
    rethrow;
  } catch (e) {
    throw DatabaseException('error.database', {'entity': entity}, e);
  }
}

/// Builds a LIKE pattern, escaping user-supplied `%`, `_` and `\`.
String likePattern(String query) {
  final escaped = query
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return '%$escaped%';
}

/// Current time as epoch millis, for created_at/updated_at columns.
int now() => nowMillis();
