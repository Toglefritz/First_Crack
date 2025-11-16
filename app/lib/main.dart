import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

/// Application entry point that initializes and runs the Flutter app.
///
/// This function is called when the application starts and creates an instance of the main application widget. All
/// application configuration and setup is handled by the FirstCrack widget in app.dart.
Future<void> main() async {
  // Ensure widget bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase resources
  await Firebase.initializeApp();

  runApp(
    const FirstCrack(),
  );
}
