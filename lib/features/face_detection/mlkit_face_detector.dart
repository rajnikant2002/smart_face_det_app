import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Thin wrapper so the UI layer does not construct [FaceDetector] options inline.
class MlKitFaceDetector {
  MlKitFaceDetector({
    FaceDetectorOptions? options,
  }) : _detector = FaceDetector(
          options: options ??
              FaceDetectorOptions(
                enableClassification: true,
              ),
        );

  final FaceDetector _detector;

  Future<List<Face>> processImage(InputImage input) => _detector.processImage(input);

  Future<void> close() => _detector.close();
}
