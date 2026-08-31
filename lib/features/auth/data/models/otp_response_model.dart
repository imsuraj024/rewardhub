class OtpResponseModel {
  final bool success;
  final String? message;

  OtpResponseModel({required this.success, this.message});

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      success: json['Success'] as bool? ?? json['success'] as bool? ?? false,
      message: json['Message'] as String? ?? json['message'] as String?,
    );
  }
}
