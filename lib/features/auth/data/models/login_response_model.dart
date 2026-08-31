class LoginResponseModel {
  final bool success;
  final String? message;
  final bool isNewUser;
  final String? token;

  LoginResponseModel({
    required this.success,
    this.message,
    required this.isNewUser,
    this.token,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['Success'] as bool? ?? json['success'] as bool? ?? false,
      message: json['Message'] as String? ?? json['message'] as String?,
      isNewUser:
          json['IsNewUser'] as bool? ?? json['isNewUser'] as bool? ?? false,
      token: json['Token'] as String? ?? json['token'] as String?,
    );
  }
}
