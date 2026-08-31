/// Outcome of a `/wallet/raise-request` submission.
class RaiseRequestResponseModel {
  const RaiseRequestResponseModel({required this.success, this.message});

  final bool success;
  final String? message;

  factory RaiseRequestResponseModel.fromJson(Map<String, dynamic> json) {
    return RaiseRequestResponseModel(
      success: json['Success'] as bool? ?? json['success'] as bool? ?? false,
      message: json['Message'] as String? ?? json['message'] as String?,
    );
  }
}
