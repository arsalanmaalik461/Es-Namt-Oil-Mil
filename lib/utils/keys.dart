import 'package:uuid/uuid.dart';

/// Unique-key helpers for the data layer (pure Dart, offline-safe).
///
/// Uses UUID v4 (random) — no network, no coordination needed.

const _uuid = Uuid();

/// A new journal key grouping the ledger entries of one posting.
String newJournalKey() => _uuid.v4();

/// A new idempotency key for safe retries of post operations.
String newIdempotencyKey() => _uuid.v4();
