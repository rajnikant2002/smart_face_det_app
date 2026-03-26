import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartFaceApp());
}

class SmartFaceApp extends StatelessWidget {
  const SmartFaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraPreviewScreen(),
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _controller;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
    ),
  );

  String? _errorMessage;
  bool _isDetecting = false;
  int _detectedFaces = 0;
  String _statusLabel = 'Neutral 🙂';

  bool _blinkInProgress = false;
  final List<DateTime> _blinkTimestamps = [];
  double _blinkRatePerMinute = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(camera, ResolutionPreset.medium);
      await controller.initialize();
      await controller.startImageStream(_processCameraImage);

      if (!mounted) {
        await controller.stopImageStream();
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final controller = _controller;
      if (controller == null) return;

      final bytes = _concatenatePlanes(image.planes);
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(
                controller.description.sensorOrientation,
              ) ??
              InputImageRotation.rotation0deg,
          format: InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      final primaryFace = faces.isNotEmpty ? faces.first : null;
      final status = _deriveStatus(primaryFace);
      _updateBlinkRate(primaryFace);

      setState(() {
        _detectedFaces = faces.length;
        _statusLabel = status;
      });
    } catch (_) {
      // Ignore single frame processing errors and continue streaming.
    } finally {
      _isDetecting = false;
    }
  }

  void _updateBlinkRate(Face? face) {
    if (face == null) {
      _blinkInProgress = false;
      _blinkTimestamps.clear();
      _blinkRatePerMinute = 0;
      return;
    }

    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    if (left == null || right == null) {
      _blinkInProgress = false;
      _blinkTimestamps.clear();
      _blinkRatePerMinute = 0;
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

    _blinkRatePerMinute = _blinkTimestamps.length * (60 / windowSeconds);
  }

  String _deriveStatus(Face? face) {
    if (face == null) return 'Neutral 🙂';

    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    if (left != null && right != null && left < 0.3 && right < 0.3) {
      return 'Tired 😴';
    }

    final smile = face.smilingProbability;
    if (smile != null && smile > 0.7) {
      return 'Happy 😊';
    }

    const stressBlinkThresholdPerMinute = 20.0; // simple initial threshold
    if (_blinkRatePerMinute > stressBlinkThresholdPerMinute) {
      return 'Stressed 😵';
    }

    return 'Neutral 🙂';
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller?.dispose();
    await _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(controller),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'Faces: $_detectedFaces\nStatus: $_statusLabel',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
