import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/gallery_providers.dart';
import '../domain/models.dart';

class PermissionPage extends ConsumerStatefulWidget {
  const PermissionPage({required this.access, super.key});

  final LibraryAccess access;

  @override
  ConsumerState<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends ConsumerState<PermissionPage> {
  /// True until the Android permission dialog has been shown once.
  /// Android reports access as denied before that dialog exists, so the
  /// settings fallback must wait until the system request returns.
  var _askedSystem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askSystem());
  }

  Future<void> _askSystem() async {
    try {
      await ref.read(accessProvider.notifier).request();
    } on GalleryFailure {
      // The system dialog could not be shown. The settings action remains.
    }
    if (mounted) setState(() => _askedSystem = true);
  }

  @override
  Widget build(BuildContext context) {
    final blocked =
        _askedSystem &&
        (widget.access == LibraryAccess.denied ||
            widget.access == LibraryAccess.restricted);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: blocked
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Allow photos and videos',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => ref
                              .read(mediaRepositoryProvider)
                              .openSystemSettings(),
                          child: const Text('Open settings'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
