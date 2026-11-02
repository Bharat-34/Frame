import 'models.dart';

/// Photos and videos taken on the same local calendar day.
class DayGroup {
  const DayGroup({required this.day, required this.assets});

  final DateTime day;
  final List<MediaAsset> assets;
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Groups [assets] by local day, keeping the order they arrived in.
List<DayGroup> groupAssetsByDay(
  List<MediaAsset> assets, {
  bool newestFirst = true,
}) {
  final grouped = <DateTime, List<MediaAsset>>{};
  for (final asset in assets) {
    final local = asset.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    grouped.putIfAbsent(day, () => []).add(asset);
  }
  final days = grouped.keys.toList()
    ..sort((a, b) => newestFirst ? b.compareTo(a) : a.compareTo(b));
  return [for (final day in days) DayGroup(day: day, assets: grouped[day]!)];
}

String dayLabel(DateTime day, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final target = DateTime(day.year, day.month, day.day);
  if (target == today) return 'Today';
  if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
  final month = _months[target.month - 1];
  if (target.year == today.year) return '$month ${target.day}';
  return '$month ${target.day}, ${target.year}';
}
