import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Tracks blink rate from sequential face classifications (simple heuristic).
class BlinkTracker {
  bool _blinkInProgress = false;
  final List<DateTime> _blinkTimestamps = [];

  double blinkRatePerMinute = 0;

  void update(Face? face) {
    if (face == null) {
      _blinkInProgress = false;
      _blinkTimestamps.clear();
      blinkRatePerMinute = 0;
      return;
    }

    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    if (left == null || right == null) {
      _blinkInProgress = false;
      _blinkTimestamps.clear();
      blinkRatePerMinute = 0;
      return;
    }

    final eyesClosed = left < 0.3 && right < 0.3;
    if (!_blinkInProgress && eyesClosed) {
      _blinkInProgress = true;
    } else if (_blinkInProgress && !eyesClosed) {
      _blinkInProgress = false;
      _blinkTimestamps.add(DateTime.now());
    }

    const windowSeconds = 10;
    final cutoff = DateTime.now().subtract(const Duration(seconds: windowSeconds));
    _blinkTimestamps.removeWhere((t) => t.isBefore(cutoff));

    blinkRatePerMinute = _blinkTimestamps.length * (60 / windowSeconds);
  }
}
