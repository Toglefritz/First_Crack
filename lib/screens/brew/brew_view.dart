/// View widget for the brew monitoring screen that handles UI presentation.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/brew/models/brew_stage.dart';
import '../../theme/insets.dart';
import '../../theme/theme.dart';
import 'brew_controller.dart';

part 'components/circular_tick_marks_painter.dart';

part 'components/brew_info_card.dart';

/// View widget for the brew monitoring screen that handles UI presentation.
///
/// This StatelessWidget receives the controller as a parameter and uses it to access state and trigger actions. The
/// view contains no business logic and is purely declarative.
class BrewView extends StatelessWidget {
  /// Creates the brew view with the required controller.
  const BrewView(this.state, {super.key});

  /// Controller instance that manages state and business logic.
  final BrewController state;

  @override
  Widget build(BuildContext context) {
    // The size of the brew progress indicator widget.
    const double brewProgressSize = 400.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.appTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: state.brewStage == BrewStage.complete
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.colorScheme.inverseSurface,
                ),
                onPressed: state.cancelBrew,
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_gradient.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Brew information row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.medium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BrewInfoCard(
                          label: context.l10n.dose,
                          value: '${state.brewService.profile.doseGrams.toInt()}g',
                          icon: Icons.coffee,
                        ),
                        _BrewInfoCard(
                          label: context.l10n.ratio,
                          value: state.brewService.profile.brewRatio.formatted,
                          icon: Icons.balance,
                        ),
                        _BrewInfoCard(
                          label: context.l10n.yield,
                          value: '${state.brewService.profile.yieldGrams.toInt()}g',
                          icon: Icons.local_cafe,
                        ),
                        _BrewInfoCard(
                          label: context.l10n.temperature,
                          value: '${state.brewService.profile.waterTemperatureF.toInt()}°F',
                          icon: Icons.thermostat,
                        ),
                      ],
                    ),
                  ),

                  // Brew stage indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Insets.large),
                    child: Text(
                      state.brewStage.label(context),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.inverseSurface,
                          ),
                    ),
                  ),

                  // Circular progress indicator
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.large),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background image
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Image.asset(
                              key: ValueKey(state.brewStage),
                              state.brewStage.image(),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Tick marks
                        SizedBox(
                          width: brewProgressSize,
                          height: brewProgressSize,
                          child: CustomPaint(
                            painter: _CircularTickMarksPainter(
                              tickCount: 5,
                              tickColor: context.colorScheme.inverseSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),

                        // Progress circle
                        SizedBox(
                          width: brewProgressSize,
                          height: brewProgressSize,
                          child: CircularProgressIndicator(
                            value: state.brewService.brewProgress,
                            strokeWidth: 24,
                            strokeCap: StrokeCap.round,
                            backgroundColor: context.colorScheme.surface.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colorScheme.inversePrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),

                        // Time remaining in center
                        if (state.brewStage != BrewStage.complete)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${state.timeRemaining.toInt()}s',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.colorScheme.inverseSurface,
                                    ),
                              ),
                              Text(
                                context.l10n.remaining,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: context.colorScheme.inverseSurface,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lower-right cancel button
          if (state.brewStage != BrewStage.complete)
            Positioned(
              bottom: Insets.small,
              right: Insets.xSmall,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.errorContainer,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  padding: const EdgeInsets.all(Insets.medium),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: state.cancelBrew,
                child: Icon(
                  Icons.close,
                  size: 24,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
