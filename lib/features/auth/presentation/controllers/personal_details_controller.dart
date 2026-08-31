import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';

/// Step 1 of registration — collects the user's personal details.
///
/// Prefills from the persisted [RegistrationDraft] and saves back to it on
/// every successful "Next" so progress survives leaving the flow.
class PersonalDetailsController extends GetxController {
  PersonalDetailsController(this._draftStore, this._analytics);

  final RegistrationDraftStore _draftStore;
  final AppAnalytics _analytics;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final referralController = TextEditingController();

  final agreedToTerms = false.obs;

  RegistrationDraft _draft = const RegistrationDraft();

  @override
  void onInit() {
    super.onInit();
    _prefill();
  }

  Future<void> _prefill() async {
    _draft = await _draftStore.read();
    nameController.text = _draft.name;
    phoneController.text = _draft.phone;
    referralController.text = _draft.referral;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    referralController.dispose();
    super.onClose();
  }

  void setAgreedToTerms(bool value) {
    agreedToTerms.value = value;
  }

  Future<void> onNext() async {
    if (!formKey.currentState!.validate()) return;
    if (!agreedToTerms.value) {
      _analytics.termsNotAccepted();
      AppToast.warning('You must agree to the Terms of Service to continue.');
      return;
    }

    final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    _draft = _draft.copyWith(
      name: nameController.text.trim(),
      phone: phone,
      referral: referralController.text.trim(),
    );
    await _draftStore.save(_draft);

    _analytics.registrationStepCompleted(RegistrationStep.personalDetails);
    Get.toNamed(AppRoutes.registerAccount);
  }
}
