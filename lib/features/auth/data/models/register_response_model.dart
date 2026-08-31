class RegisterResponseModel {
  final bool success;
  final String? token;
  final String? message;

  RegisterResponseModel({required this.success, this.token, this.message});

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      success: json['Success'] as bool? ?? json['success'] as bool? ?? false,
      token: json['Token'] as String? ?? json['token'] as String?,
      message: json['Message'] as String? ?? json['message'] as String?,
    );
  }
}
