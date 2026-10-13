/// Date/time helpers for the data layer (pure Dart, no Flutter imports).
///
/// Business dates are stored in SQLite as INTEGER milliseconds-since-epoch.
/// This keeps date columns index-friendly and sortable.
library;

/// Converts a [DateTime] to epoch millis for DB storage.
int toEpochMillis(DateTime dt) => dt.millisecondsSinceEpoch;

/// Converts epoch millis from the DB back to a [DateTime].
DateTime fromEpochMillis(int millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis);

/// Start of the calendar day (local) for [d], as epoch millis.
int startOfDayMillis(DateTime d) =>
    DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

/// Exclusive end of the calendar day (local) for [d], as epoch millis.
int endOfDayMillis(DateTime d) =>
    DateTime(d.year, d.month, d.day + 1).millisecondsSinceEpoch;

/// Inclusive start / exclusive end of a month, as epoch millis.
({int start, int end}) monthRangeMillis(int year, int month) {
  final start = DateTime(year, month, 1).millisecondsSinceEpoch;
  final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
  return (start: start, end: end);
}

/// Current time as epoch millis.
int nowMillis() => DateTime.now().millisecondsSinceEpoch;
