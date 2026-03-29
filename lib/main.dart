import 'package:flutter/material.dart';

import 'package:smart_face_det_app/ui/home_screen.dart';

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
      home: HomeScreen(),
    );
  }
}
