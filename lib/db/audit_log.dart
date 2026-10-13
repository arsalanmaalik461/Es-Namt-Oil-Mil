import 'package:sqflite/sqflite.dart';

import '../utils/time.dart';

/// Tiny audit-trail writer (pure Dart, no Flutter imports).
///
/// Repositories log every mutation (create/update/delete/post/reverse) here
/// inside the same executor/transaction as the mutation itself, so the trail
/// can never disagree with the data.
abstract final class AuditLog {
  static const String table = 'audit_log';

  static Future<void> log(
    DatabaseExecutor db, {
    required String action,
    required String entity,
    required Object? entityId,
    String? details,
  }) {
    return db.insert(table, {
      'timestamp': nowMillis(),
      'action': action,
      'entity': entity,
      'entity_id': entityId?.toString(),
      'details': details,
    });
  }

  static Future<List<Map<String, Object?>>> recent(
    DatabaseExecutor db, {
    int limit = 100,
    int offset = 0,
  }) {
    return db.query(
      table,
      orderBy: 'timestamp DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }
}
