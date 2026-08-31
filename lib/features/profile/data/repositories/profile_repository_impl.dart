import 'package:rewardhub/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final ProfileRemoteDataSource _remote;

  @override
  Future<ProfileModel> fetchProfile({required String token}) =>
      _remote.fetchProfile(token: token);
}
