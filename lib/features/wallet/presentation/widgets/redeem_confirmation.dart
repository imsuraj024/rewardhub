import 'package:flutter/material.dart';

import 'package:rewardhub/core/utils/app_format.dart';
import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';

/// Redeem is available only when the profile has loaded and the balance is
/// above zero. The Home quick action and the Wallet button both use this.
bool canRedeem(int? points) => points != null && points > 0;

/// Asks before `WalletController.raiseRequest()` runs. Resolves true only
/// when the user taps "Send request"; Cancel, back and a scrim tap give false.
Future<bool> confirmRedemption(BuildContext context, {required int points}) {
  return AppBottomSheet.confirm(
    context: context,
    icon: Icons.redeem_rounded,
    title: 'Redeem your points?',
    message: 'You have ${AppFormat.pointsWithUnit(points)}. '
        "We'll send a redemption request. "
        'The money goes to your saved payment details.',
    confirmLabel: 'Send request',
  );
}
