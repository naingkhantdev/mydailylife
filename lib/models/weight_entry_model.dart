/// One body-weight reading, keyed by the day it was taken.
///
/// One document per day rather than per reading: weighing yourself twice in a
/// morning should correct the day, not add a second point to the trend.
class WeightEntryModel {
  const WeightEntryModel({
    required this.date,
    required this.weightLb,
  });

  final DateTime date;
  final double weightLb;

  static String dateIdFor(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get documentId => dateIdFor(date);

  Map<String, dynamic> toMap() {
    return {
      'date': documentId,
      'weight_lb': weightLb,
    };
  }

  factory WeightEntryModel.fromMap(DateTime date, Map<String, dynamic> map) {
    return WeightEntryModel(
      date: date,
      weightLb: (map['weight_lb'] as num?)?.toDouble() ?? 0,
    );
  }
}
