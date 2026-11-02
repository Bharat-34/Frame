# Frame

Frame is a gallery for the photos and videos already on the phone. It reads the device library, shows it in a day timeline, and does not upload anything.

Package name: `com.frame.gallery`. Current version: `0.1.0+4`.

## What the app does today

- Asks for photos and videos with the Android system permission dialog.
- Shows a day-grouped photo grid, with Photos and Videos filters.
- Opens albums that already exist on the phone, such as Camera, Screenshots, and Downloads.
- Keeps favorites through the system gallery, on a Saved tab.
- Opens a viewer with swipe, pinch zoom, and video playback.
- Shares, shows details, and deletes with the system confirm dialog.
- Uses the icon in `assets/branding/app_icon.png` as the Android launcher icon.

A release or debug install stays on the phone after the USB cable is unplugged. A `flutter run` session does not. Quitting that session can close the app.

## First launch

On a new install, Frame requests Android’s photo and video permission. The choices are Allow all, Allow limited access, and Don’t allow. If the person has already chosen Don’t allow, Android will not ask again, and Frame can only open system settings.

## How the code is organized

The library feature is split so screens never depend on the photo-library plugin.

| Layer | Where | Responsibility |
| --- | --- | --- |
| App | `lib/app/` | Theme, router, permission gate |
| Domain | `lib/features/gallery/domain/` | Models, queries, repository interfaces |
| Data | `lib/features/gallery/data/` | The only place that talks to PhotoManager |
| Application | `lib/features/gallery/application/` | Riverpod notifiers, paging, selection |
| Presentation | `lib/features/gallery/presentation/` | Screens and widgets |

`LibraryQuery` is the key for a photo list: album, photo or video, favorites, sort, and date window. Lists page from the device. After a favorite or delete, open lists refresh without jumping back to the top.

Navigation today is Photos, Albums, and Saved, plus a full-screen viewer.

## Run it

```bash
flutter pub get
flutter run -d <device-id>
```

Gradle must use the machine cache, or the wrapper tries to download a distribution it already has:

```bash
GRADLE_USER_HOME="$HOME/.gradle" flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Tests:

```bash
flutter test test/media_browser_test.dart test/gallery_logic_test.dart
```

## Related

The next screens are described in [design-plan.md](design-plan.md). The wireframe they follow is `reference docs/Next Gen Gallery App Wireframes.png`.
