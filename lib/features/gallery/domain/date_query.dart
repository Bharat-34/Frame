/// Inclusive [start] and exclusive [end] for a date search.
class DateWindow {
  const DateWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

const _months = <String, int>{
  'january': 1,
  'jan': 1,
  'february': 2,
  'feb': 2,
  'march': 3,
  'mar': 3,
  'april': 4,
  'apr': 4,
  'may': 5,
  'june': 6,
  'jun': 6,
  'july': 7,
  'jul': 7,
  'august': 8,
  'aug': 8,
  'september': 9,
  'sep': 9,
  'sept': 9,
  'october': 10,
  'oct': 10,
  'november': 11,
  'nov': 11,
  'december': 12,
  'dec': 12,
};

/// Reads a gallery search such as "Today", "October", or "2024".
///
/// Returns null when [raw] is empty or not a date Frame understands.
DateWindow? parseDateQuery(String raw, {required DateTime now}) {
  final text = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[,]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return null;

  if (text == 'today') {
    final start = DateTime(now.year, now.month, now.day);
    return DateWindow(start: start, end: start.add(const Duration(days: 1)));
  }
  if (text == 'yesterday') {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 1));
    return DateWindow(start: start, end: today);
  }

  final yearOnly = RegExp(r'^(19|20)\d{2}$');
  if (yearOnly.hasMatch(text)) {
    final year = int.parse(text);
    return DateWindow(start: DateTime(year), end: DateTime(year + 1));
  }

  final parts = text.split(' ');
  if (parts.length == 1) {
    final month = _months[parts[0]];
    if (month == null) return null;
    return DateWindow(
      start: DateTime(now.year, month),
      end: DateTime(now.year, month + 1),
    );
  }
  if (parts.length != 2) return null;

  final leadingMonth = _months[parts[0]];
  final trailingYear = int.tryParse(parts[1]);
  if (leadingMonth != null && _isYear(trailingYear)) {
    return DateWindow(
      start: DateTime(trailingYear!, leadingMonth),
      end: DateTime(trailingYear, leadingMonth + 1),
    );
  }

  final leadingYear = int.tryParse(parts[0]);
  final trailingMonth = _months[parts[1]];
  if (trailingMonth != null && _isYear(leadingYear)) {
    return DateWindow(
      start: DateTime(leadingYear!, trailingMonth),
      end: DateTime(leadingYear, trailingMonth + 1),
    );
  }
  return null;
}

bool _isYear(int? year) => year != null && year >= 1900 && year <= 2100;
