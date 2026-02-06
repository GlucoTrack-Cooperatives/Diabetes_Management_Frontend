import 'log_entry_dto.dart';

class ActiveInsulin {
  final double totalUnits;
  final Duration remainingTime;

  ActiveInsulin({required this.totalUnits, required this.remainingTime});
}

class IOBCalculator {
  static const int insulinDurationHours = 4; // Standard duration of action

  static ActiveInsulin calculate(List<LogEntryDTO> insulinLogs) {
    double totalActive = 0.0;
    DateTime now = DateTime.now();
    DateTime oldestRelevant = now.subtract(const Duration(hours: insulinDurationHours));

    for (var log in insulinLogs) {
      if (log.timestamp.isAfter(oldestRelevant)) {
        // Parse units from description: e.g., "5.0 U - Humalog"
        final description = log.description;
        double units = 0.0;
        
        if (description.contains(' U')) {
          try {
            // Extracts the portion before ' U'
            final unitsPart = description.split(' U')[0];
            units = double.tryParse(unitsPart) ?? 0.0;
          } catch (e) {
            print("Error parsing units from description: $description");
          }
        }

        if (units > 0) {
          final hoursSinceInjection = now.difference(log.timestamp).inMinutes / 60.0;
          final remainingFactor = 1.0 - (hoursSinceInjection / insulinDurationHours);

          if (remainingFactor > 0) {
            totalActive += units * remainingFactor;
          }
        }
      }
    }

    // Find the latest log to determine time remaining until 0 IOB
    final latestLog = insulinLogs.isEmpty ? null : insulinLogs.first;
    final timeRemaining = latestLog == null
        ? Duration.zero
        : latestLog.timestamp.add(const Duration(hours: insulinDurationHours)).difference(now);

    return ActiveInsulin(
      totalUnits: double.parse(totalActive.toStringAsFixed(1)),
      remainingTime: timeRemaining.isNegative ? Duration.zero : timeRemaining,
    );
  }
}
