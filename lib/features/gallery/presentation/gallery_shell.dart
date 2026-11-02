import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/frame_theme.dart';

class GalleryShell extends StatelessWidget {
  const GalleryShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.92),
                border: Border.all(color: palette.line),
                borderRadius: BorderRadius.circular(28),
              ),
              child: SizedBox(
                height: 68,
                child: Row(
                  children: [
                    _Destination(
                      label: 'Photos',
                      icon: Icons.grid_view_rounded,
                      selected: navigationShell.currentIndex == 0,
                      onTap: () => navigationShell.goBranch(
                        0,
                        initialLocation: navigationShell.currentIndex == 0,
                      ),
                    ),
                    _Destination(
                      label: 'Albums',
                      icon: Icons.photo_album_outlined,
                      selected: navigationShell.currentIndex == 1,
                      onTap: () => navigationShell.goBranch(
                        1,
                        initialLocation: navigationShell.currentIndex == 1,
                      ),
                    ),
                    _Destination(
                      label: 'Saved',
                      icon: Icons.favorite_border,
                      selected: navigationShell.currentIndex == 2,
                      onTap: () => navigationShell.goBranch(
                        2,
                        initialLocation: navigationShell.currentIndex == 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.accent : palette.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? palette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
