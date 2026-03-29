import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

Uint8List concatenateCameraPlanes(List<Plane> planes) {
  final allBytes = WriteBuffer();
  for (final plane in planes) {
    allBytes.putUint8List(plane.bytes);
  }
  return allBytes.done().buffer.asUint8List();
}
