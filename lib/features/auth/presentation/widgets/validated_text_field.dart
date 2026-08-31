import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_field_label.dart';

/// A labelled form field that validates as the user types (rather than only on
/// submit) and shows a green success tick once the value is valid.
class ValidatedTextField extends StatefulWidget {
  const ValidatedTextField({
    super.key,
    required this.label,
    required this.controller,
    this.optional = false,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool optional;
  final String? hintText;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _valid = _computeValid(widget.controller.text);
  }

  bool _computeValid(String value) {
    if (widget.validator == null) return false;
    if (value.trim().isEmpty) return false;
    return widget.validator!(value) == null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AuthFieldLabel(widget.label),
            if (widget.optional) ...[
              const Spacer(),
              Text('OPTIONAL', style: AppTextStyles.labelSm),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: widget.validator,
          onChanged: (v) {
            final valid = _computeValid(v);
            if (valid != _valid) setState(() => _valid = valid);
            widget.onChanged?.call(v);
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _valid
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
