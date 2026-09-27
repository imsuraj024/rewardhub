import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_text_styles.dart';

/// Sentence-case field label used above auth form inputs.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.fieldLabel);
  }
}
