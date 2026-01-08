import 'package:flutter/material.dart';
import '../models/glucose_alert_settings.dart';

/// In-app alert dialog for glucose alerts
class GlucoseAlertDialog extends StatelessWidget {
  final double glucoseValue;
  final AlertSeverity severity;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const GlucoseAlertDialog({
    super.key,
    required this.glucoseValue,
    required this.severity,
    this.onDismiss,
    this.onViewDetails,
  });

  Color _getSeverityColor() {
    switch (severity) {
      case AlertSeverity.criticalLow:
      case AlertSeverity.criticalHigh:
        return Colors.red.shade900;
      case AlertSeverity.low:
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.normal:
        return Colors.green;
    }
  }

  IconData _getSeverityIcon() {
    switch (severity) {
      case AlertSeverity.criticalLow:
      case AlertSeverity.criticalHigh:
        return Icons.warning_amber_rounded;
      case AlertSeverity.low:
        return Icons.trending_down;
      case AlertSeverity.high:
        return Icons.trending_up;
      case AlertSeverity.normal:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with severity indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSeverityIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          severity.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Glucose Alert',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Glucose value display
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    '${glucoseValue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'mg/dL',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Advice section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'What to do:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          severity.getAdvice(glucoseValue),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onViewDetails != null)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewDetails?.call();
                      },
                      child: const Text('View Details'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Understood'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the alert dialog
  static Future<void> show(
    BuildContext context, {
    required double glucoseValue,
    required AlertSeverity severity,
    VoidCallback? onDismiss,
    VoidCallback? onViewDetails,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlucoseAlertDialog(
        glucoseValue: glucoseValue,
        severity: severity,
        onDismiss: onDismiss,
        onViewDetails: onViewDetails,
      ),
    );
  }
}
