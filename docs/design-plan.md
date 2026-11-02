# Design plan

This is the plan for bringing Frame in line with `reference docs/Next Gen Gallery App Wireframes.png`. The AI tab stays Coming soon. The other screens are built from the photos, dates, places, and file sizes already on the phone.

The first launch stays the Android permission dialog. The wireframe’s “Get Started” introduction is not part of this plan.

## Navigation

The bottom bar becomes Photos, Albums, Memories, AI, and More.

Favorites leave their own tab. They become a Favorites chip on Photos and a Favorites row in Albums. Storage, Hidden, and Trash live under More.

## Structure

Each area keeps the current split: domain models and repository interfaces, one data implementation for the phone library, Riverpod notifiers, then screens. Photo-library types stay inside the data layer.

| Area | Folder | Role |
| --- | --- | --- |
| Library | `lib/features/library` | Photos, albums, trash. Grows out of today’s gallery feature |
| Memories | `lib/features/memories` | Collections from dates and places |
| Places | `lib/features/places` | Photos grouped by location |
| Search | `lib/features/search` | Search over data the phone already stores |
| Privacy | `lib/features/privacy` | Hidden album and PIN |
| Storage | `lib/features/storage` | Space breakdown and cleanup |
| AI | `lib/features/ai` | Coming soon page only |

The repository interface gains albums, locations, file size, trash, and hide. Screens call that interface.

## Screens

**Photos.** Keep the day grid. Chips are All, Photos, Videos, and Favorites. Search opens from the header. One date stays at the top while scrolling, and the next date pushes it away.

**Albums.** Show Camera, Screenshots, Downloads, Videos, and Favorites, each with a count. Creating an album writes a real folder where Android allows it. Hidden opens the locked album.

**Memories.** Build stories from dates and places. Examples are this day last year, a month, and a trip when several photos share a place across a few days. Family Moments needs face grouping, so it waits with the AI tab.

**Places.** Group photos that have a location into cities. A city opens its photos. Photos with no location do not appear here.

**Search.** Match dates, album names, cities, and favorites. Suggestion chips open those real sections. Recent searches stay on the device. Searching what is inside a picture waits on the AI page.

**Viewer.** Keep swipe, zoom, video, share, and delete. Edit is crop and rotate, saved back to the library. AI Edit is visible and marked Coming soon.

**Storage.** Show photos, videos, and free space, plus the largest videos. Cleanup can remove exact duplicate files. Similar-looking photos wait on the AI page.

**Hidden album.** A PIN stored on this device. Hidden photos leave Photos, Albums, Memories, and Search until the PIN is entered. The files stay in the phone library. Frame filters them out.

**Trash.** On Android 11 and newer, delete moves items to the system trash and they can be restored. Older Android still confirms a permanent delete.

## Coming soon

The AI page lists Find photos, Remove duplicates, Blur sensitive photos, Enhance, and Magic edit, each marked Coming soon. People is the same page’s neighbor and stays Coming soon, because grouping faces needs a model. Cloud backup is not one of these screens and is not part of this plan.

## Build order

1. New bottom bar, Photos and Albums restyle, Favorites chip.
2. Search, crop and rotate, and the More page.
3. Storage and exact-duplicate cleanup.
4. Hidden album with PIN, and Trash with restore.
5. Places, then Memories from those dates and places.
6. AI and People as Coming soon only.

Each step can ship on its own.
