import 'package:flutter_test/flutter_test.dart';
import 'package:frame/features/gallery/domain/date_query.dart';
import 'package:frame/features/gallery/domain/day_group.dart';
import 'package:frame/features/gallery/domain/models.dart';

void main() {
  test('groups photos into newest days first', () {
    final now = DateTime(2026, 11, 1, 18);
    final assets = [
      _asset('older', now.subtract(const Duration(days: 1))),
      _asset('newer', now),
    ];

    final groups = groupAssetsByDay(assets, newestFirst: true);

    expect(groups.map((group) => group.day), [
      DateTime(2026, 11, 1),
      DateTime(2026, 10, 31),
    ]);
    expect(dayLabel(groups.first.day, now: now), 'Today');
    expect(dayLabel(groups.last.day, now: now), 'Yesterday');
  });

  test('reads day, month, and year searches', () {
    final now = DateTime(2026, 11, 1, 15, 30);

    expect(parseDateQuery('  ', now: now), isNull);
    expect(parseDateQuery('vacation', now: now), isNull);

    final today = parseDateQuery('Today', now: now)!;
    expect(today.start, DateTime(2026, 11, 1));
    expect(today.end, DateTime(2026, 11, 2));

    final october = parseDateQuery('October 2025', now: now)!;
    expect(october.start, DateTime(2025, 10, 1));
    expect(october.end, DateTime(2025, 11, 1));

    final year = parseDateQuery('2024', now: now)!;
    expect(year.start, DateTime(2024));
    expect(year.end, DateTime(2025));
  });
}

MediaAsset _asset(String id, DateTime createdAt) {
  return MediaAsset(
    id: id,
    kind: MediaKind.image,
    width: 10,
    height: 10,
    duration: Duration.zero,
    createdAt: createdAt,
    isFavorite: false,
  );
}
