import 'package:flutter/material.dart';
import 'home_controller.dart';

/// Route widget for the home screen.
///
/// Following MVC patterns, this route serves only as the entry point and delegates all logic to the HomeController
/// through createState().
class HomeRoute extends StatefulWidget {
  /// Creates the home route widget.
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}
