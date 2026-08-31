class QrScanResponseModel {
  final bool success;
  final String? message;
  final int? pointsEarned;

  QrScanResponseModel({
    required this.success,
    this.message,
    this.pointsEarned,
  });

  factory QrScanResponseModel.fromJson(Map<String, dynamic> json) {
    return QrScanResponseModel(
      success: json['Success'] as bool? ?? json['success'] as bool? ?? false,
      message: json['Message'] as String? ?? json['message'] as String?,
      pointsEarned: json['PointsEarned'] as int? ?? json['pointsEarned'] as int?,
    );
  }
}
