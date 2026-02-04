import 'package:flutter/material.dart';

/// Rider splash screen.
///
/// Keep this UI stable and lightweight. Boot logic should live in the app root
/// (state machine) or in a small boot controller/service.
class RiderSplashScreen extends StatelessWidget {
  const RiderSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.delivery_dining,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text('EaszyGoo Rider', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Getting things ready…', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
