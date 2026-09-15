const gymMonthAbbreviations = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

const gymWeekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

/// 40 kg, not 40.0 kg — but 42.5 keeps its half plate.
String formatGymWeightKg(double weightKg) {
  return weightKg == weightKg.roundToDouble()
      ? weightKg.toStringAsFixed(0)
      : weightKg.toStringAsFixed(1);
}
