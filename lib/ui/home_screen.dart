import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:smart_face_det_app/features/camera/camera_aspect_preview.dart';
import 'package:smart_face_det_app/features/face_detection/blink_tracker.dart';
import 'package:smart_face_det_app/features/face_detection/face_labels.dart';
import 'package:smart_face_det_app/features/face_detection/input_image_builder.dart';
import 'package:smart_face_det_app/features/face_detection/mlkit_face_detector.dart';
import 'package:smart_face_det_app/features/gamification/gamification.dart';
import 'package:smart_face_det_app/features/suggestion/suggestion_engine.dart';
import 'package:smart_face_det_app/features/tracking/usage_tracker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  final MlKitFaceDetector _faceDetector = MlKitFaceDetector();
  final BlinkTracker _blinkTracker = BlinkTracker();
  final Gamification _gamification = Gamification();
  late final UsageTracker _usageTracker;

  String? _errorMessage;
  bool _isDetecting = false;
  int _detectedFaces = 0;
  String _statusLabel = 'Neutral 🙂';
  String _lightingLabel = 'Good Lighting 💡';
  String _suggestion = 'You\'re doing great 👍';
  double _brightnessValue = 0;
  int _usageMinutes = 0;
  String _currentStateKey = 'Neutral';
  String _currentLightingKey = 'Good';

  @override
  void initState() {
    super.initState();
    _usageTracker = UsageTracker(
      onTick: (minutes) {
        if (!mounted) return;
        setState(() {
          _usageMinutes = minutes;
          if (Gamification.shouldReward(
            stateKey: _currentStateKey,
            lightingKey: _currentLightingKey,
          )) {
            _gamification.rewardUser();
          }
        });
      },
    );
    _usageTracker.start();
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

      final inputImage = buildInputImageFromCamera(
        image: image,
        controller: controller,
      );

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      final primaryFace = faces.isNotEmpty ? faces.first : null;
      _blinkTracker.update(primaryFace);
      final stateKey = deriveFaceStateKey(primaryFace, _blinkTracker.blinkRatePerMinute);
      final status = formatStateLabel(stateKey);
      final brightness = calculateFrameBrightness(image);
      final lightingKey = deriveLightingKey(brightness);
      final lightingLabel = formatLightingLabel(lightingKey);
      final suggestion = getSuggestion(stateKey, lightingKey, _usageMinutes);

      setState(() {
        _detectedFaces = faces.length;
        _currentStateKey = stateKey;
        _currentLightingKey = lightingKey;
        _statusLabel = status;
        _brightnessValue = brightness;
        _lightingLabel = lightingLabel;
        _suggestion = suggestion;
      });
    } catch (_) {
      // Ignore single frame processing errors and continue streaming.
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _usageTracker.dispose();
    final controller = _controller;
    if (controller != null && controller.value.isStreamingImages) {
      unawaited(controller.stopImageStream());
    }
    if (controller != null) {
      unawaited(controller.dispose());
    }
    unawaited(_faceDetector.close());
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
            child: CameraAspectPreview(controller: controller),
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
                  'Faces: $_detectedFaces\n'
                  'Status: $_statusLabel\n'
                  'Lighting: $_lightingLabel\n'
                  'Brightness: ${_brightnessValue.toStringAsFixed(0)}\n'
                  'Usage: $_usageMinutes mins\n'
                  '🔥 Streak: ${_gamification.streak} days\n'
                  '⭐ Points: ${_gamification.points}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '💡 Suggestion:\n$_suggestion',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
