/// 40 kg, not 40.0 kg — but 42.5 keeps its half plate.
String formatGymWeightKg(double weightKg) {
  return weightKg == weightKg.roundToDouble()
      ? weightKg.toStringAsFixed(0)
      : weightKg.toStringAsFixed(1);
}
