import 'dart:math';

import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/utils/error_message.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';

/// Holds the user profile state for the home and profile screens.
class ProfileController extends GetxController {
  ProfileController({
    required AuthController authController,
    required GetProfileUseCase getProfile,
    required AppAnalytics analytics,
  }) : _auth = authController,
       _getProfile = getProfile,
       _analytics = analytics;

  final AuthController _auth;
  final GetProfileUseCase _getProfile;
  final AppAnalytics _analytics;

  final _state = Rx<ViewState<ProfileModel>>(const ViewStateInitial());
  bool _inFlight = false;

  ViewState<ProfileModel> get state => _state.value;

  ProfileModel? get profile => _state.value is ViewStateSuccess<ProfileModel>
      ? (_state.value as ViewStateSuccess<ProfileModel>).data
      : null;

  @override
  void onInit() {
    super.onInit();
    // Load now if a session already exists, and again whenever the token
    // becomes available — this is race-free regardless of whether the session
    // was restored before or after this controller was created.
    ever<String?>(_auth.tokenListenable, (token) {
      if (token != null && token.isNotEmpty) loadProfile();
    });
    loadProfile();
  }

  /// Optimistically adds [pointsEarned] to the profile and fetches the latest from the server.
  Future<void> addPoints(int pointsEarned) async {
    final current = profile;
    if (current != null) {
      _state.value = ViewStateSuccess(
        current.copyWith(points: current.points + pointsEarned),
      );
      _state.refresh();
    }
    await loadProfile(force: true);
  }

  /// Optimistically deducts [pointsDeducted] from the profile and fetches the latest from the server.
  Future<void> deductPoints(int pointsDeducted) async {
    final current = profile;
    if (current != null) {
      final newPoints = (current.points - pointsDeducted).clamp(0, 99999999);
      _state.value = ViewStateSuccess(current.copyWith(points: newPoints));
      _state.refresh();
    }
    await loadProfile(force: true);
  }

  /// Generate obfuscated Referral Code
  /// Takes the profile ID and returns a random 8-character code
  /// Starts with KX and has 4 random characters
  /// Format: KX-XXXX-XXXX
  String generateReferralCode(String? profileId) {
    if (profileId == null || profileId.toString().trim().isEmpty) {
      return '—';
    }
    final numericId =
        (int.tryParse(profileId.toString()) ??
        profileId.toString().hashCode.abs());
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random(numericId);

    // Obfuscate the profile ID
    final obfuscatedId = numericId ^ 0x5A3C7F;

    // Convert to base36 and take a portion
    final encodedId = obfuscatedId.toRadixString(36).toUpperCase();

    // Add random characters
    final randomPart = List.generate(
      4,
      (_) => chars[random.nextInt(chars.length)],
    ).join();

    return 'KX-${encodedId.padLeft(4, '0')}-$randomPart';
  }

  /// Fetches the latest profile from the network.
  ///
  /// Does nothing without an active session. Existing data stays on screen
  /// while the request is in flight — the loading spinner only shows when there
  /// is nothing to display yet. Concurrent calls are coalesced unless [force] is true.
  Future<void> loadProfile({bool force = false}) async {
    if (_inFlight && !force) return;
    final token = _auth.token;
    if (token == null) return;

    _inFlight = true;
    if (_state.value is! ViewStateSuccess) {
      _state.value = const ViewStateLoading();
    }
    try {
      final result = await _getProfile(token);
      // The server's opaque profile id — deliberately not the mobile number,
      // which is the only other identifier available and is personal data.
      _analytics.identify(result.id);
      _state.value = ViewStateSuccess(result);
    } catch (e, st) {
      log(
        'loadProfile failed',
        name: 'rewardhub.profile',
        error: e,
        stackTrace: st,
      );
      if (_state.value is! ViewStateSuccess) {
        _state.value = ViewStateError(resolveErrorMessage(e));
      }
    } finally {
      _inFlight = false;
    }
  }
}
