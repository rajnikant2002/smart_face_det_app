import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Raw state keys used by [getSuggestion] and gamification.
String deriveFaceStateKey(Face? face, double blinkRatePerMinute) {
  if (face == null) return 'Neutral';

  final left = face.leftEyeOpenProbability;
  final right = face.rightEyeOpenProbability;
  if (left != null && right != null && left < 0.3 && right < 0.3) {
    return 'Tired';
  }

  final smile = face.smilingProbability;
  if (smile != null && smile > 0.7) {
    return 'Happy';
  }

  const stressBlinkThresholdPerMinute = 20.0;
  if (blinkRatePerMinute > stressBlinkThresholdPerMinute) {
    return 'Stressed';
  }

  return 'Neutral';
}

String formatStateLabel(String state) {
  switch (state) {
    case 'Tired':
      return 'Tired 😴';
    case 'Stressed':
      return 'Stressed 😵';
    case 'Happy':
      return 'Happy 😊';
    default:
      return 'Neutral 🙂';
  }
}

double calculateFrameBrightness(CameraImage image) {
  if (image.planes.isEmpty) return 0;
  final bytes = image.planes.first.bytes;
  if (bytes.isEmpty) return 0;

  const step = 10;
  var sum = 0;
  var count = 0;
  for (var i = 0; i < bytes.length; i += step) {
    sum += bytes[i];
    count++;
  }
  return count == 0 ? 0 : sum / count;
}

/// Keys: Dark | Too Bright | Good
String deriveLightingKey(double brightness) {
  if (brightness < 50) return 'Dark';
  if (brightness > 200) return 'Too Bright';
  return 'Good';
}

String formatLightingLabel(String lighting) {
  switch (lighting) {
    case 'Dark':
      return 'Too Dim 🌙';
    case 'Too Bright':
      return 'Too Bright ☀️';
    default:
      return 'Good Lighting 💡';
  }
}
