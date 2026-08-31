import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';

/// Step 2 of registration — collects the user's payout details
/// (UPI / Google Pay number or bank account). All fields are optional.
///
/// Prefills from the persisted [RegistrationDraft] and saves back to it on
/// every successful "Next".
class AccountDetailsController extends GetxController {
  AccountDetailsController(this._draftStore, this._analytics);

  final RegistrationDraftStore _draftStore;
  final AppAnalytics _analytics;

  final formKey = GlobalKey<FormState>();
  final upiController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscController = TextEditingController();

  /// Whether the user has opted in to entering bank details. The bank fields
  /// stay hidden until this is toggled on, so we capture intent explicitly.
  final showBankDetails = false.obs;

  RegistrationDraft _draft = const RegistrationDraft();

  @override
  void onInit() {
    super.onInit();
    _prefill();
  }

  Future<void> _prefill() async {
    _draft = await _draftStore.read();
    upiController.text = _draft.upi;
    accountNumberController.text = _draft.accountNumber;
    ifscController.text = _draft.ifsc;
    // Re-open the bank section if the user had already entered details.
    if (_draft.accountNumber.isNotEmpty || _draft.ifsc.isNotEmpty) {
      showBankDetails.value = true;
    }
  }

  void revealBankDetails() {
    showBankDetails.value = true;
    _analytics.bankDetailsRevealed();
  }

  @override
  void onClose() {
    upiController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    super.onClose();
  }

  Future<void> onNext() async {
    if (!formKey.currentState!.validate()) return;

    _draft = _draft.copyWith(
      upi: upiController.text.trim(),
      accountNumber: showBankDetails.value
          ? accountNumberController.text.trim()
          : '',
      ifsc: showBankDetails.value ? ifscController.text.trim() : '',
    );
    await _draftStore.save(_draft);

    // Records only which *kind* of payout was configured — never the UPI id,
    // account number or IFSC code.
    _analytics.setPayoutMethod(
      hasUpi: _draft.upi.isNotEmpty,
      hasBank: _draft.accountNumber.isNotEmpty,
    );
    _analytics.registrationStepCompleted(RegistrationStep.accountDetails);
    Get.toNamed(AppRoutes.registerKyc);
  }
}
