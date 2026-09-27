import 'package:intl/intl.dart';

/// App-wide number and date formatting.
///
/// Use these instead of building `NumberFormat` / `DateFormat` per screen, so
/// points use Indian digit grouping and "1 point / N points" everywhere.
abstract final class AppFormat {
  static final NumberFormat _points = NumberFormat.decimalPattern('en_IN');

  /// 100000 → '1,00,000'
  static String points(int value) => _points.format(value);

  /// 1 → '1 point'; 1500 → '1,500 points'; 0 → '0 points'
  static String pointsWithUnit(int value) =>
      value == 1 ? '1 point' : '${points(value)} points';

  /// (+) '+50 points' / (−, U+2212) '−1,000 points'
  static String signedPoints(int value, {required bool isCredit}) =>
      '${isCredit ? '+' : '−'}${pointsWithUnit(value)}';

  /// local time → '27 Sep, 3:15 PM'
  static String dateTime(DateTime value) =>
      DateFormat('d MMM, h:mm a').format(value.toLocal());
}
