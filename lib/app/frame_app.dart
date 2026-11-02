import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/gallery/application/gallery_providers.dart';
import '../features/gallery/domain/models.dart';
import '../features/gallery/presentation/permission_page.dart';
import 'router.dart';
import 'theme/frame_theme.dart';

class FrameApp extends ConsumerStatefulWidget {
  const FrameApp({super.key});

  @override
  ConsumerState<FrameApp> createState() => _FrameAppState();
}

class _FrameAppState extends ConsumerState<FrameApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(accessProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessProvider);
    return MaterialApp.router(
      title: 'Frame',
      debugShowCheckedModeBanner: false,
      theme: FrameTheme.light,
      darkTheme: FrameTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: frameRouter,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: context.palette.paper,
          systemNavigationBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: access.when(
            skipLoadingOnReload: true,
            loading: () => const BootScreen(),
            error: (error, stackTrace) =>
                const PermissionPage(access: LibraryAccess.unknown),
            data: (value) {
              if (!value.hasAccess) return PermissionPage(access: value);
              return child ?? const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
