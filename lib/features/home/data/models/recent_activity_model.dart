/// A single recent activity entry as returned by the `/transactions_New` endpoint.
class RecentActivityModel {
  const RecentActivityModel({
    required this.id,
    required this.type,
    required this.points,
    required this.date,
  });

  final String id;

  /// 'credit' (points earned) or 'debit' (points redeemed).
  final String type;
  final int points;
  final DateTime date;

  /// Whether this activity added points to the balance.
  bool get isCredit => type.toLowerCase() == 'credit';

  /// Whether this activity deducted points from the balance.
  bool get isDebit => type.toLowerCase() == 'debit';

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(1970),
    );
  }
}
