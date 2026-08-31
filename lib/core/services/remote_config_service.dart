import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/models/banner_model.dart';
import 'package:rewardhub/core/utils/logger.dart';

/// Keys used in Firebase Remote Config.
abstract final class RemoteConfigKeys {
  static const String maintenanceMode = 'maintenance_mode';
  static const String maintenanceMessage = 'maintenance_message';
  static const String supportPhone = 'support_phone';
  static const String supportEmail = 'support_email';
  static const String latestVersion = 'latest_version';
  static const String catalogueUrl = 'catalogue_url';
  static const String releaseNotes = 'release_notes';
  static const String promotionalBanner = 'promotional_banner';
}

/// Default values for Firebase Remote Config when offline or before initial fetch.
abstract final class RemoteConfigDefaults {
  static const Map<String, dynamic> defaults = {
    RemoteConfigKeys.maintenanceMode: false,
    RemoteConfigKeys.maintenanceMessage:
        'RewardHub is undergoing scheduled maintenance. Please check back shortly.',
    RemoteConfigKeys.supportPhone: '+91 98765 43210',
    RemoteConfigKeys.supportEmail: 'support@kitoxhardware.com',
    RemoteConfigKeys.latestVersion: '',
    RemoteConfigKeys.catalogueUrl:
        'https://raw.githubusercontent.com/mozilla/pdf.js/master/web/compressed.tracemonkey-pldi-09.pdf',
    RemoteConfigKeys.releaseNotes: '',
    RemoteConfigKeys.promotionalBanner: '',
  };
}

/// Service wrapping Firebase Remote Config for type-safe parameter access,
/// default values, and real-time updates.
class RemoteConfigService extends GetxService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  StreamSubscription<RemoteConfigUpdate>? _updateSubscription;

  /// Initializes Remote Config settings, sets in-app defaults, and fetches latest values.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults(RemoteConfigDefaults.defaults);

      final activated = await _remoteConfig.fetchAndActivate();
      log(
        'Remote Config initialized (fetchAndActivate: $activated)',
        name: 'rewardhub.remote_config',
      );

      _listenToRealtimeUpdates();
    } catch (e, st) {
      log(
        'Remote Config initialization failed, using defaults',
        name: 'rewardhub.remote_config',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _listenToRealtimeUpdates() {
    try {
      _updateSubscription = _remoteConfig.onConfigUpdated.listen((
        RemoteConfigUpdate update,
      ) async {
        log(
          'Remote Config updated keys: ${update.updatedKeys}',
          name: 'rewardhub.remote_config',
        );
        try {
          await _remoteConfig.activate();
        } catch (e, st) {
          log(
            'Failed to activate updated remote config keys',
            name: 'rewardhub.remote_config',
            error: e,
            stackTrace: st,
          );
        }
      });
    } catch (e, st) {
      log(
        'Realtime Remote Config subscription failed',
        name: 'rewardhub.remote_config',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Manually forces a fetch & activation of latest Remote Config values.
  Future<bool> fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e, st) {
      log(
        'Manual Remote Config fetchAndActivate failed',
        name: 'rewardhub.remote_config',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  // ── Generic typed accessors ──────────────────────────────────────────────

  String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      return (RemoteConfigDefaults.defaults[key] as String?) ?? '';
    }
  }

  bool getBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      return (RemoteConfigDefaults.defaults[key] as bool?) ?? false;
    }
  }

  int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      return (RemoteConfigDefaults.defaults[key] as int?) ?? 0;
    }
  }

  double getDouble(String key) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      return (RemoteConfigDefaults.defaults[key] as double?) ?? 0.0;
    }
  }

  // ── Typed Convenience Getters ────────────────────────────────────────────

  bool get isMaintenanceMode => getBool(RemoteConfigKeys.maintenanceMode);

  String get maintenanceMessage =>
      getString(RemoteConfigKeys.maintenanceMessage);

  String get supportPhone => getString(RemoteConfigKeys.supportPhone);

  String get supportEmail => getString(RemoteConfigKeys.supportEmail);

  String get latestVersion => getString(RemoteConfigKeys.latestVersion);

  String get catalogueUrl => getString(RemoteConfigKeys.catalogueUrl);

  String? get releaseNotes {
    final val = getString(RemoteConfigKeys.releaseNotes);
    return (val.trim().isEmpty || val.trim() == 'null') ? null : val;
  }

  String? get promotionalBanner {
    final val = getString(RemoteConfigKeys.promotionalBanner);
    return (val.trim().isEmpty || val.trim() == 'null') ? null : val;
  }

  /// Parses [promotionalBanner] JSON into a list of [BannerModel]s.
  ///
  /// Supports both a JSON array of banners (`[{...}, {...}]`) or a single banner
  /// JSON object (`{...}`). Returns an empty list if not configured, invalid,
  /// or all banners are inactive.
  List<BannerModel> get promotionalBanners {
    final raw = promotionalBanner;
    if (raw == null || raw.trim().isEmpty || raw.trim() == 'null') {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (item) => BannerModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((banner) => banner.isActive)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      } else if (decoded is Map) {
        final banner = BannerModel.fromJson(Map<String, dynamic>.from(decoded));
        return banner.isActive ? [banner] : const [];
      }
    } catch (e, st) {
      log(
        'Failed to parse promotional_banner from Remote Config',
        name: 'rewardhub.remote_config',
        error: e,
        stackTrace: st,
      );
    }
    return const [];
  }

  @override
  void onClose() {
    _updateSubscription?.cancel();
    super.onClose();
  }
}
