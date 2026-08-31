import 'package:shared_preferences/shared_preferences.dart';

import 'package:rewardhub/core/utils/logger.dart';

/// In-progress registration data collected across the multi-step sign-up flow.
///
/// Backed by [SharedPreferences] so the user can leave and resume without
/// losing what they already entered. Cleared once registration is submitted.
class RegistrationDraft {
  const RegistrationDraft({
    this.name = '',
    this.phone = '',
    this.referral = '',
    this.upi = '',
    this.accountNumber = '',
    this.ifsc = '',
    this.aadhaarPath = '',
    this.selfiePath = '',
  });

  // Personal details
  final String name;
  final String phone;
  final String referral;

  // Account details
  final String upi;
  final String accountNumber;
  final String ifsc;

  // KYC
  final String aadhaarPath;
  final String selfiePath;

  RegistrationDraft copyWith({
    String? name,
    String? phone,
    String? referral,
    String? upi,
    String? accountNumber,
    String? ifsc,
    String? aadhaarPath,
    String? selfiePath,
  }) {
    return RegistrationDraft(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      referral: referral ?? this.referral,
      upi: upi ?? this.upi,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      aadhaarPath: aadhaarPath ?? this.aadhaarPath,
      selfiePath: selfiePath ?? this.selfiePath,
    );
  }
}

/// Persists the [RegistrationDraft] between the registration steps.
abstract interface class RegistrationDraftStore {
  Future<RegistrationDraft> read();
  Future<void> save(RegistrationDraft draft);
  Future<void> clear();
}

class RegistrationDraftStoreImpl implements RegistrationDraftStore {
  static const _kName = 'reg_draft_name';
  static const _kPhone = 'reg_draft_phone';
  static const _kReferral = 'reg_draft_referral';
  static const _kUpi = 'reg_draft_upi';
  static const _kAccountNumber = 'reg_draft_account_number';
  static const _kIfsc = 'reg_draft_ifsc';
  static const _kAadhaarPath = 'reg_draft_aadhaar_path';
  static const _kSelfiePath = 'reg_draft_selfie_path';

  static const _keys = [
    _kName,
    _kPhone,
    _kReferral,
    _kUpi,
    _kAccountNumber,
    _kIfsc,
    _kAadhaarPath,
    _kSelfiePath,
  ];

  @override
  Future<RegistrationDraft> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return RegistrationDraft(
        name: prefs.getString(_kName) ?? '',
        phone: prefs.getString(_kPhone) ?? '',
        referral: prefs.getString(_kReferral) ?? '',
        upi: prefs.getString(_kUpi) ?? '',
        accountNumber: prefs.getString(_kAccountNumber) ?? '',
        ifsc: prefs.getString(_kIfsc) ?? '',
        aadhaarPath: prefs.getString(_kAadhaarPath) ?? '',
        selfiePath: prefs.getString(_kSelfiePath) ?? '',
      );
    } catch (e, st) {
      log(
        'read registration draft failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
      return const RegistrationDraft();
    }
  }

  @override
  Future<void> save(RegistrationDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kName, draft.name);
      await prefs.setString(_kPhone, draft.phone);
      await prefs.setString(_kReferral, draft.referral);
      await prefs.setString(_kUpi, draft.upi);
      await prefs.setString(_kAccountNumber, draft.accountNumber);
      await prefs.setString(_kIfsc, draft.ifsc);
      await prefs.setString(_kAadhaarPath, draft.aadhaarPath);
      await prefs.setString(_kSelfiePath, draft.selfiePath);
    } catch (e, st) {
      log(
        'save registration draft failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _keys) {
        await prefs.remove(key);
      }
    } catch (e, st) {
      log(
        'clear registration draft failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }
}
