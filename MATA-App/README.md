# MATA Flutter Application – Getting Started

## Prerequisites

1. **Flutter SDK** – already installed (you mentioned it’s working). Verify with:
   ```bash
   flutter doctor
   ```
   Make sure there are no red warnings for Android toolchain.
2. **Android Studio** (or Android command‑line tools) with:
   - Android SDK
   - Android SDK Platform‑Tools
   - Android Emulator
3. **Java Development Kit (JDK)** – JDK 11+ is recommended.
4. **Device/Emulator** – an Android Virtual Device (AVD) that matches the app’s `minSdkVersion` (check `android/app/build.gradle`).
5. **Backend URL** – ensure the backend server (FastAPI) is running and reachable from the emulator. If you use `localhost`, replace it with your machine’s IP address (e.g., `http://10.0.2.2:8000`).

## Step‑by‑Step Guide

### 1. Verify Flutter installation
```bash
flutter doctor -v
```
All checks should show a green check. If Android toolchain shows issues, install the missing components via Android Studio or the SDK manager.

### 2. Create an Android Virtual Device (AVD)
| Option | How‑to |
|--------|--------|
| **Android Studio UI** | Open **Android Studio → Tools → AVD Manager → Create Virtual Device**. Choose a device (e.g., Pixel 5), select a system image (Android 13 API 33 recommended), and finish. |
| **Command line** | ```bash
flutter emulators --create --name mata_emulator --device-id pixel_5
flutter emulators --launch mata_emulator
``` |

### 3. Launch the emulator
- **From Android Studio**: Click the **Play** button next to your AVD.
- **From terminal**: `flutter emulators --launch <emulator-id>` (you can list IDs with `flutter emulators`).

Make sure the emulator boots completely (you should see the home screen).

### 4. Run the Flutter app
Navigate to the project root (`e:\MARK\MATA-App`) in a terminal and execute:
```bash
cd e:\MARK\MATA-App
flutter pub get   # fetch dependencies
flutter run       # builds & deploys to the running emulator
```
Flutter will compile the Dart code, install the APK on the emulator, and launch the app.

### 5. Hot‑reload & development workflow
- While the app is running, any saved changes in `lib/` trigger a **hot‑reload** (`r` in the terminal) which instantly updates the UI.
- To perform a full restart, press `R`.

### 6. Connect to the backend
If the backend runs on your host machine, Android emulators cannot reach `localhost` directly. Use the special alias `10.0.2.2`:
```dart
const String backendBaseUrl = 'http://10.0.2.2:8000';
```
Update any hard‑coded URLs in the Flutter code (e.g., in `services/api_service.dart`).

### 7. Debugging tips
- **Log output**: `flutter logs` shows device logs.
- **Inspect widgets**: Use **Flutter DevTools** (`dart devtools`) for UI inspection and performance profiling.
- **Common errors**:
  - *“Missing Android SDK”*: reinstall Android Studio or set `ANDROID_SDK_ROOT`.
  - *“Failed to install APK”*: ensure the emulator has enough storage and is not in a locked state.

## Optional – Using VS Code
1. Install the **Flutter** and **Dart** extensions.
2. Open the folder `e:\MARK\MATA-App`.
3. Press **F5** or click **Run → Start Debugging**. VS Code will launch the emulator (if configured) and start the app.
h
---

You’re now ready to develop and test the MATA app on an Android emulator. Happy coding!
