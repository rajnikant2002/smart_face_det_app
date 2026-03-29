import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Fills the parent without stretching the preview (fixes tall/squashed faces).
class CameraAspectPreview extends StatelessWidget {
  const CameraAspectPreview({
    super.key,
    required this.controller,
  });

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(controller);
    }

    final previewAspectRatio = previewSize.height / previewSize.width;
    final screenAspectRatio = screenSize.width / screenSize.height;
    final scale = previewAspectRatio / screenAspectRatio;

    return Transform.scale(
      scale: scale < 1 ? 1 / scale : scale,
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }
}
