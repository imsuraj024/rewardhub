import 'package:rewardhub/features/profile/data/models/profile_model.dart';

/// Domain contract for retrieving the user profile.
abstract interface class ProfileRepository {
  /// Fetches the profile from the network.
  Future<ProfileModel> fetchProfile({required String token});
}
