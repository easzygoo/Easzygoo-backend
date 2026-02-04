import 'package:flutter/material.dart';

import '../../models/kyc_model.dart';
import '../../services/kyc_controller.dart';

class KycRejectedScreen extends StatelessWidget {
  const KycRejectedScreen({
    super.key,
    required this.controller,
    this.onResubmit,
    this.onApproved,
  });

  final KycController controller;

  /// Called after reset/resubmit action.
  final VoidCallback? onResubmit;

  /// Called when status changes to approved.
  final VoidCallback? onApproved;

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
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('KYC Rejected', style: theme.textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  'Please fix the issue and resubmit your documents.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Reason', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                        Text('Your documents were rejected. Please resubmit with clear photos and correct details.',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      if (controller.isLoading) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed: controller.isLoading
                            ? null
                            : () async {
                                await controller.reset();
                                if (!context.mounted) return;
                                onResubmit?.call();
                              },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Resubmit KYC'),
                        ),
                      ),
                      const SizedBox(height: 8),
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
