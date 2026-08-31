import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';

/// A single digit input box used by the OTP entry row.
///
/// Animates its border/fill on focus and once a digit is entered, and advertises
/// [AutofillHints.oneTimeCode] so the OS can offer the SMS code.
class OtpBox extends StatefulWidget {
  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus != _focused) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;
    final Color borderColor;
    double borderWidth = 1.5;
    if (_focused) {
      borderColor = AppColors.primary;
      borderWidth = 2;
    } else if (filled) {
      borderColor = AppColors.primary.withValues(alpha: 0.5);
    } else {
      borderColor = Colors.transparent;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 44,
      height: 52,
      decoration: BoxDecoration(
        color: _focused
            ? AppColors.primaryFixed.withValues(alpha: 0.4)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        maxLength: 1,
        obscureText: true,
        obscuringCharacter: '•',
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.titleLg.copyWith(color: AppColors.onSurface),
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (v) {
          setState(() {}); // refresh filled state
          widget.onChanged(v);
        },
      ),
    );
  }
}
