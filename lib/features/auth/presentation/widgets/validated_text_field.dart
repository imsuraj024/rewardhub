import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_field_label.dart';

/// A labelled form field that shows a green success tick once the value is
/// valid.
///
/// Validation timing: quiet while the user first types, checked when focus
/// leaves (after the user has typed), and re-checked on every keystroke once
/// an error is showing. `Form.validate()` on submit still shows every error.
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
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
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

  /// Optional; when null the field creates (and disposes) its own node.
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  FocusNode? _ownFocusNode;
  bool _valid = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _valid = _computeValid(widget.controller.text);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ValidatedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      if (widget.focusNode != null) {
        _ownFocusNode?.dispose();
        _ownFocusNode = null;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    // A node supplied by the caller is theirs to dispose.
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final field = _fieldKey.currentState;
    if (!_focusNode.hasFocus && field != null && field.hasInteractedByUser) {
      field.validate();
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: AuthFieldLabel(widget.label)),
            if (widget.optional) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Optional',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: _fieldKey,
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          autovalidateMode: AutovalidateMode.disabled,
          validator: widget.validator,
          onChanged: (v) {
            // Once an error is showing, clear it on the keystroke that fixes it.
            final field = _fieldKey.currentState;
            if (field != null && field.hasError) field.validate();
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
