import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/repositories/profile_repository.dart';

/// Fetches the latest profile from the network (and refreshes the cache).
class GetProfileUseCase implements UseCase<ProfileModel, String> {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileModel> call(String token) =>
      _repository.fetchProfile(token: token);
}
