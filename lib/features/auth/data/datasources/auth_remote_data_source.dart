import 'package:dio/dio.dart';

import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/data/models/login_response_model.dart';
import 'package:rewardhub/features/auth/data/models/otp_response_model.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';

/// Remote data source for authentication endpoints.
///
/// Talks to the network via [ApiClient] and maps raw JSON into models. Throws
/// [ApiException] for business-level failures.
abstract interface class AuthRemoteDataSource {
  Future<LoginResponseModel> login(String phone);
  Future<RegisterResponseModel> register({
    required String name,
    required String phone,
    String? referralCode,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? bankAddress,
    String? upiId,
    String? selfiePhotoPath,
    String? aadharPhotoPath,
  });
  Future<OtpResponseModel> verifyOtp({
    required String token,
    required String otp,
  });
  Future<void> deleteAccount(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<LoginResponseModel> login(String phone) async {
    final data = await _apiClient.post(
      ApiEndpoints.login,
      data: {'Mobile': phone},
    );
    final response = LoginResponseModel.fromJson(data as Map<String, dynamic>);
    // success=false with no isNewUser flag is a business-level error
    if (!response.success && !response.isNewUser && response.token == null) {
      throw ApiException(
        response.message ??
            "Couldn't log you in. Check your number and try again.",
      );
    }
    return response;
  }

  @override
  Future<RegisterResponseModel> register({
    required String name,
    required String phone,
    String? referralCode,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? bankAddress,
    String? upiId,
    String? selfiePhotoPath,
    String? aadharPhotoPath,
  }) async {
    // The register-new endpoint expects multipart/form-data. Empty optional
    // fields are sent as 'NA' to match the backend's expected placeholder.
    String orNa(String? value) =>
        (value == null || value.trim().isEmpty) ? 'NA' : value.trim();

    final formMap = <String, dynamic>{
      'Name': name,
      'Mobile': phone,
      'ReferralCode': orNa(referralCode),
      'BankName': orNa(bankName),
      'AccountNumber': orNa(accountNumber),
      'IFSCCode': orNa(ifscCode),
      'BankAddress': orNa(bankAddress),
      'UPId': orNa(upiId),
    };

    if (selfiePhotoPath != null && selfiePhotoPath.trim().isNotEmpty) {
      formMap['SelfiePhoto'] = await MultipartFile.fromFile(
        selfiePhotoPath.trim(),
      );
    }
    if (aadharPhotoPath != null && aadharPhotoPath.trim().isNotEmpty) {
      formMap['AadharPhoto'] = await MultipartFile.fromFile(
        aadharPhotoPath.trim(),
      );
    }

    final data = await _apiClient.post(
      ApiEndpoints.register,
      data: FormData.fromMap(formMap),
    );
    final response = RegisterResponseModel.fromJson(
      data as Map<String, dynamic>,
    );
    if (!response.success) {
      throw ApiException(
        response.message ?? "Couldn't send your registration. Please try again.",
      );
    }
    return response;
  }

  @override
  Future<OtpResponseModel> verifyOtp({
    required String token,
    required String otp,
  }) async {
    final data = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {'Token': token, 'Otp': otp},
    );
    final response = OtpResponseModel.fromJson(data as Map<String, dynamic>);
    if (!response.success) {
      throw ApiException(
        response.message ?? "That code didn't work. Check it and try again.",
      );
    }
    return response;
  }

  @override
  Future<void> deleteAccount(String token) async {
    final data = await _apiClient.post(
      ApiEndpoints.deleteAccount,
      data: {'token': token},
    );
    if (data is Map<String, dynamic> && data['success'] == false) {
      throw ApiException(
        data['message']?.toString() ??
            "Couldn't delete your account. Check your internet and try again.",
      );
    }
  }
}
