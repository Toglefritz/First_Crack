import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/insets.dart';
import 'home_controller.dart';

/// View widget for the home screen that handles UI presentation.
///
/// This StatelessWidget receives the controller as a parameter and uses it to access state and trigger actions. The
/// view contains no business logic and is purely declarative.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  const HomeView(this.state, {super.key});

  /// Controller instance that manages state and business logic.
  ///
  /// Used to access the current lamp state and trigger toggle actions.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context)!.appTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Lamp icon that changes appearance based on state. When the lamp is on, it displays a bright yellow bulb
            // with glow effect. When off, it displays a dim gray bulb without glow.
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: state.isLampOn
                    ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.lightbulb,
                size: 80,
                color: state.isLampOn ? Colors.amber : Colors.grey,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Insets.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.lampOff),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.small),
                    child: Switch(
                      value: state.isLampOn,
                      onChanged: state.toggleLamp,
                      activeThumbColor: Colors.amber,
                    ),
                  ),
                  Text(AppLocalizations.of(context)!.lampOn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
