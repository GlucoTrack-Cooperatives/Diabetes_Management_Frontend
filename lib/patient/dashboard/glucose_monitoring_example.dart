// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../services/health_api_service.dart';
// import '../../services/glucose_monitoring_service.dart';
// import '../../widgets/glucose_alert_dialog.dart';
// import '../settings/alert_settings_controller.dart';
// import '../../models/glucose_alert_settings.dart';
//
// /// Example screen showing how to integrate glucose monitoring with Health API
// class GlucoseMonitoringExample extends ConsumerStatefulWidget {
//   const GlucoseMonitoringExample({super.key});
//
//   @override
//   ConsumerState<GlucoseMonitoringExample> createState() =>
//       _GlucoseMonitoringExampleState();
// }
//
// class _GlucoseMonitoringExampleState
//     extends ConsumerState<GlucoseMonitoringExample> {
//   double? _currentGlucose;
//   bool _isMonitoring = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Load alert settings
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(alertSettingsControllerProvider).loadSettings();
//     });
//   }
//
//   Future<void> _fetchLatestGlucose() async {
//     setState(() {
//       _isMonitoring = true;
//     });
//
//     try {
//       final healthService = ref.read(healthApiServiceProvider);
//       final monitoringService = ref.read(glucoseMonitoringServiceProvider);
//
//       // Fetch last 24 hours of glucose data
//       final now = DateTime.now();
//       final yesterday = now.subtract(const Duration(hours: 24));
//
//       final glucoseData = await healthService.getBloodGlucoseData(yesterday, now);
//
//       if (glucoseData.isNotEmpty) {
//         // Get most recent reading
//         final latest = glucoseData.last;
//         setState(() {
//           _currentGlucose = latest.value;
//         });
//
//         // Check if alert should be triggered
//         final severity = monitoringService.processHealthDataPoint(latest);
//
//         if (severity != null && mounted) {
//           // Show in-app alert
//           GlucoseAlertDialog.show(
//             context,
//             glucoseValue: latest.value,
//             severity: severity,
//             onDismiss: () {
//               print('Alert dismissed');
//             },
//             onViewDetails: () {
//               // Navigate to detailed view
//               Navigator.of(context).pushNamed('/dashboard');
//             },
//           );
//
//           // TODO: Also trigger background notification here
//           // This would use flutter_local_notifications package
//           _triggerBackgroundNotification(latest.value, severity);
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('No recent glucose data found'),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error fetching glucose: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       setState(() {
//         _isMonitoring = false;
//       });
//     }
//   }
//
//   void _triggerBackgroundNotification(double glucoseValue, severity) {
//     // TODO: Implement actual background notification
//     // This would use flutter_local_notifications package
//     final monitoringService = ref.read(glucoseMonitoringServiceProvider);
//     final title = monitoringService.getNotificationTitle(severity, glucoseValue);
//     final body = monitoringService.getNotificationBody(severity);
//
//     print('Background Notification:');
//     print('Title: $title');
//     print('Body: $body');
//     print('Color: ${severity.colorHex}');
//
//     // Example implementation:
//     // await flutterLocalNotificationsPlugin.show(
//     //   0,
//     //   title,
//     //   body,
//     //   NotificationDetails(
//     //     android: AndroidNotificationDetails(
//     //       'glucose_alerts',
//     //       'Glucose Alerts',
//     //       importance: Importance.max,
//     //       priority: Priority.high,
//     //       color: Color(int.parse(severity.colorHex.substring(1), radix: 16)),
//     //       playSound: settings.soundEnabled,
//     //     ),
//     //     iOS: IOSNotificationDetails(
//     //       presentAlert: true,
//     //       presentSound: settings.soundEnabled,
//     //     ),
//     //   ),
//     // );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final settings = ref.watch(alertSettingsProvider);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Glucose Monitoring'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               Navigator.of(context).pushNamed('/alert-settings');
//             },
//             tooltip: 'Alert Settings',
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Current glucose display
//             Card(
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Current Glucose',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _currentGlucose?.toStringAsFixed(0) ?? '--',
//                       style: TextStyle(
//                         fontSize: 64,
//                         fontWeight: FontWeight.bold,
//                         color: _currentGlucose != null
//                             ? _getGlucoseColor(_currentGlucose!)
//                             : Colors.grey,
//                       ),
//                     ),
//                     const Text(
//                       'mg/dL',
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             // Fetch button
//             ElevatedButton.icon(
//               onPressed: _isMonitoring ? null : _fetchLatestGlucose,
//               icon: _isMonitoring
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.refresh),
//               label: Text(_isMonitoring ? 'Checking...' : 'Check Glucose from Health'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.all(16),
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             // Current settings display
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Alert Thresholds',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildThresholdRow(
//                       'Critical Low',
//                       settings.criticalLowThreshold,
//                       Colors.red.shade900,
//                     ),
//                     _buildThresholdRow(
//                       'Low',
//                       settings.lowThreshold,
//                       Colors.orange,
//                     ),
//                     _buildThresholdRow(
//                       'High',
//                       settings.highThreshold,
//                       Colors.orange,
//                     ),
//                     _buildThresholdRow(
//                       'Critical High',
//                       settings.criticalHighThreshold,
//                       Colors.red.shade900,
//                     ),
//                     const Divider(),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('Notifications'),
//                         Text(
//                           settings.notificationsEnabled ? 'Enabled' : 'Disabled',
//                           style: TextStyle(
//                             color: settings.notificationsEnabled
//                                 ? Colors.green
//                                 : Colors.grey,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('Sound'),
//                         Text(
//                           settings.soundEnabled ? 'Enabled' : 'Disabled',
//                           style: TextStyle(
//                             color: settings.soundEnabled
//                                 ? Colors.green
//                                 : Colors.grey,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             // Info
//             Card(
//               color: Colors.blue.shade50,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     Icon(Icons.info_outline, color: Colors.blue.shade700),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Alerts will be shown when your glucose is outside the configured range. High alerts are always enabled.',
//                         style: TextStyle(color: Colors.blue.shade700),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildThresholdRow(String label, double value, Color color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 12,
//                 height: 12,
//                 decoration: BoxDecoration(
//                   color: color,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(label),
//             ],
//           ),
//           Text(
//             '${value.toStringAsFixed(0)} mg/dL',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getGlucoseColor(double glucose) {
//     final controller = ref.read(alertSettingsControllerProvider);
//     final severity = controller.getSeverity(glucose);
//
//     switch (severity) {
//       case AlertSeverity.criticalLow:
//       case AlertSeverity.criticalHigh:
//         return Colors.red.shade900;
//       case AlertSeverity.low:
//       case AlertSeverity.high:
//         return Colors.orange;
//       case AlertSeverity.normal:
//         return Colors.green;
//     }
//   }
// }
