# Smart Face Detection App

AI-powered Flutter app that uses the front camera to detect face state, lighting conditions, usage patterns, and give real-time wellness suggestions with basic gamification.

## Features

- Front camera live preview (full screen, aspect-ratio safe)
- Real-time face detection with ML Kit
- State detection:
  - Tired (both eyes mostly closed)
  - Stressed (high blink rate, basic logic)
  - Happy (high smile probability)
  - Neutral (default)
- Lighting detection:
  - Too Dim
  - Too Bright
  - Good Lighting
- Suggestion engine:
  - Context-aware suggestions from state, lighting, and usage time
  - 30-minute light reminder
  - 2-hour strong break suggestion
- Gamification:
  - Points and streak rewards for healthy usage behavior

## Project Structure

```text
lib/
├── features/
│   ├── camera/
│   │   └── camera_aspect_preview.dart
│   ├── face_detection/
│   │   ├── blink_tracker.dart
│   │   ├── camera_image_bytes.dart
│   │   ├── face_labels.dart
│   │   ├── input_image_builder.dart
│   │   └── mlkit_face_detector.dart
│   ├── suggestion/
│   │   └── suggestion_engine.dart
│   ├── tracking/
│   │   └── usage_tracker.dart
│   └── gamification/
│       └── gamification.dart
├── ui/
│   └── home_screen.dart
└── main.dart
```

## Dependencies

- `camera: ^0.10.5`
- `google_mlkit_face_detection: ^0.10.0`
- `permission_handler: ^11.0.0`

## Run Locally

1. Install Flutter SDK and device/emulator setup.
2. Get packages:
   - `flutter pub get`
3. Run app:
   - `flutter run`

## Current UI Layout

- Camera preview with face overlay area
- Status and lighting info row
- Suggestion card
- Streak and points row

## Notes

- Uses front camera by default.
- Face and lighting logic are intentionally simple and can be tuned per device.
- Permission handling package is added and ready for explicit camera permission flow.
