# Mesh

Offline, peer-to-peer messaging **plus** contact-card sharing for the people you meet.
No account, no server — messages hop phone-to-phone over Bluetooth / Wi-Fi Direct.

## Features
- **Nearby** – automatically finds and connects to other phones running the app (~100 m).
- **Chats** – 1:1 and "everyone nearby" broadcast. Messages are store-and-forward
  flooded through connected peers (up to 6 hops) with delivery ticks.
- **Contacts** – a digital business card is exchanged on connect; save it, add a
  private note, call / email / open website.
- **QR card** – show or scan a profile QR when the mesh isn't available
  (e.g. cross-platform or crowded rooms).
- **Me** – edit your card, toggle discoverability, see stats.

## Run it (Android)
```bash
flutter create . --platforms android
cp platform_overrides/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
flutter pub get
flutter run
```
Requirements: Flutter 3.22+, Android `minSdkVersion 23`
(edit `android/app/build.gradle` → `minSdk = 23`), two physical Android phones
with Bluetooth + Location on. Emulators cannot use Nearby Connections.

iOS: `nearby_connections` is Android-only. The UI, contacts and QR sharing run on
iOS; swap `MeshService` for a MultipeerConnectivity plugin to add iOS mesh.

## Structure
```
lib/
  main.dart                 app + AppScope (service locator)
  models/models.dart        Profile, Contact, Message, Packet, Peer
  services/store.dart       local persistence (shared_preferences)
  services/mesh_service.dart Nearby Connections mesh + flooding/relay
  screens/                  onboarding, home tabs, chat, contacts, QR, profile edit
  widgets/common.dart       Avatar, EmptyState, ProfileCard
```
