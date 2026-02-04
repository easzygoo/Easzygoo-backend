import 'package:flutter/material.dart';

import '../../models/kyc_model.dart';
import '../../services/kyc_controller.dart';

class KycPendingScreen extends StatelessWidget {
  const KycPendingScreen({
    super.key,
    required this.controller,
    this.onApproved,
    this.onRejected,
  });

  final KycController controller;

  /// Called when status changes to approved.
  final VoidCallback? onApproved;

  /// Called when status changes to rejected.
  final VoidCallback? onRejected;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final status = controller.status;

        // Defensive: if state changes while on this screen.
        if (status == KycStatus.approved) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onApproved?.call());
        } else if (status == KycStatus.rejected) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onRejected?.call());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('KYC Status'),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.hourglass_top,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('KYC Under Review', style: theme.textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  'Your documents are being verified. You can’t access the dashboard until KYC is approved.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.isLoading) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: controller.isLoading ? null : controller.load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh status'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
