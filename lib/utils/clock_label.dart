/// Time of day parsed out of a routine's `startTime` label.
typedef ClockTime = ({int hour, int minute});

final _clockPattern = RegExp(
  r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
  caseSensitive: false,
);

/// Reads `07:00 AM` as 24-hour components, or returns null when the label is
/// free text rather than a time.
///
/// Routines store their times as the label the user typed, so anything that
/// schedules against them has to cope with `Anytime` or an empty string.
ClockTime? parseClockLabel(String label) {
  final match = _clockPattern.firstMatch(label.trim());
  if (match == null) {
    return null;
  }

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 12 || minute > 59) {
    return null;
  }

  // 12:30 AM is 00:30, and 12:30 PM stays 12:30.
  if (hour == 12) {
    hour = 0;
  }
  if (match.group(3)!.toUpperCase() == 'PM') {
    hour += 12;
  }
  return (hour: hour, minute: minute);
}
