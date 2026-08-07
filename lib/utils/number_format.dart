/// Groups thousands with commas: `2450` becomes `2,450`.
///
/// Hand-rolled rather than adding `intl` for one function — the app has no
/// locale switching, so a fixed comma separator is correct everywhere it is
/// used. Calorie totals are the main caller and routinely pass 1,000.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }

  return value < 0 ? '-$buffer' : buffer.toString();
}
