import 'package:flutter/material.dart';

import '../../../../app/theme/frame_theme.dart';
import '../../../../core/formatters.dart';
import '../../domain/day_group.dart';

class DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  DayHeaderDelegate({required this.day, required this.count});

  final DateTime day;
  final int count;

  @override
  double get minExtent => 42;

  @override
  double get maxExtent => 42;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final palette = context.palette;
    return SizedBox(
      height: maxExtent,
      child: ColoredBox(
        color: palette.paper,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                dayLabel(day),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                formatCount(count),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(DayHeaderDelegate oldDelegate) {
    return oldDelegate.day != day || oldDelegate.count != count;
  }
}
