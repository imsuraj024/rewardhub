import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';

/// Input for [RegisterUseCase].
class RegisterParams {
  const RegisterParams({
    required this.name,
    required this.phone,
    this.referralCode,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.bankAddress,
    this.upiId,
    this.selfiePhotoPath,
    this.aadharPhotoPath,
  });

  final String name;
  final String phone;
  final String? referralCode;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankAddress;
  final String? upiId;
  final String? selfiePhotoPath;
  final String? aadharPhotoPath;
}

/// Registers a new user and returns the issued session token.
class RegisterUseCase
    implements UseCase<RegisterResponseModel, RegisterParams> {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<RegisterResponseModel> call(RegisterParams params) {
    return _repository.register(
      name: params.name,
      phone: params.phone,
      referralCode: params.referralCode,
      bankName: params.bankName,
      accountNumber: params.accountNumber,
      ifscCode: params.ifscCode,
      bankAddress: params.bankAddress,
      upiId: params.upiId,
      selfiePhotoPath: params.selfiePhotoPath,
      aadharPhotoPath: params.aadharPhotoPath,
    );
  }
}
