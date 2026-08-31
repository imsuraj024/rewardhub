import 'package:rewardhub/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:rewardhub/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rewardhub/features/auth/data/models/login_response_model.dart';
import 'package:rewardhub/features/auth/data/models/otp_response_model.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<LoginResponseModel> login(String phone) => _remote.login(phone);

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
  }) => _remote.register(
    name: name,
    phone: phone,
    referralCode: referralCode,
    bankName: bankName,
    accountNumber: accountNumber,
    ifscCode: ifscCode,
    bankAddress: bankAddress,
    upiId: upiId,
    selfiePhotoPath: selfiePhotoPath,
    aadharPhotoPath: aadharPhotoPath,
  );

  @override
  Future<OtpResponseModel> verifyOtp({
    required String token,
    required String otp,
  }) => _remote.verifyOtp(token: token, otp: otp);

  @override
  Future<void> saveSession(String token) => _local.saveSession(token);

  @override
  Future<void> clearSession() => _local.clearSession();

  @override
  Future<String?> restoreSession() async {
    final isLoggedIn = await _local.readIsLoggedIn();
    if (!isLoggedIn) return null;
    final token = await _local.readToken();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  @override
  Future<void> deleteAccount(String token) async {
    await _remote.deleteAccount(token);
    await _local.clearSession();
  }
}
