import 'package:flutter/material.dart';
import 'home_controller.dart';

/// The home route for the application.
///
/// This screen is the one presented when the app launches. It allows the user to start a new brew.
class HomeRoute extends StatefulWidget {
  /// Creates the home route widget.
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}
