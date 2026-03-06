# Android Build Instructions

This file describes how to build Android artifacts using local `.env` define files.

## Why This File Is Not Bundled

Only files declared under `flutter.assets` in `pubspec.yaml` are packaged into the app.
This markdown file and local `env/*.env` files are not included in APK/AAB outputs.

## 1) Create Local Env Files

Copy the example files and fill in real values:

```powershell
Copy-Item env/android.debug.example.env env/android.debug.env
Copy-Item env/android.release.example.env env/android.release.env
```

Required key:

```env
ONESIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID
```

## 2) Build Commands

Run commands from the project root.

### Debug APK

```powershell
flutter build apk --debug --dart-define-from-file=env/android.debug.env
```

### Release APK

```powershell
flutter build apk --release --dart-define-from-file=env/android.release.env
```

### Debug AAB

```powershell
flutter build appbundle --debug --dart-define-from-file=env/android.debug.env
```

### Release AAB

```powershell
flutter build appbundle --release --dart-define-from-file=env/android.release.env
```

## 3) Output Paths

- APK output directory: `build/app/outputs/flutter-apk/`
- AAB output directory: `build/app/outputs/bundle/<mode>/`

## Notes

- Keep real `env/*.env` files local only. They are ignored by git.
- Keep `*.example.env` files committed as templates for the team.

## Release Smoke Checklist

Run these checks on an Android 13+ device before shipping:

1. Complete one successful generation.
2. Confirm the in-app notification soft prompt appears.
3. Tap `Enable` and confirm the native OS notification permission prompt appears.
4. Schedule each local notification type from debug settings and tap each notification:
   - Daily refill -> lands on home/conversations flow
   - Guest signup nudge -> opens signup when logged out
   - Upgrade nudge -> opens pricing when logged in and unsubscribed
5. Verify cancellation behavior:
   - Guest nudge cancels after signup/login
   - Upgrade + daily refill reminders cancel after successful subscription
