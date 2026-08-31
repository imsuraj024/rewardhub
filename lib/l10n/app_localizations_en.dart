// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get verifyAccess => 'Verify Access';

  @override
  String get codeSentTo => 'A 6-digit code was sent to\n';

  @override
  String get verifyIdentity => 'Verify';

  @override
  String get didNotGetCode => 'Didn\'t get the code?  ';

  @override
  String get resendCode => 'Resend Code';

  @override
  String codeValidFor(String time) {
    return 'CODE VALID FOR $time';
  }

  @override
  String get curatorSubtitle => 'Scan, earn, and redeem rewards every day.';
}
