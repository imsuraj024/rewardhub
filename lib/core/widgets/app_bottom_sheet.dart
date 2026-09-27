import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';

/// The app's modal bottom sheet: handle, optional header, a scrolling body
/// and actions pinned at the bottom, clear of the keyboard and home indicator.
///
/// Show it with [AppBottomSheet.show] (never `showModalBottomSheet` directly)
/// so every sheet shares the shape, colour and height cap:
///
/// ```dart
/// AppBottomSheet.show<void>(
///   context: context,
///   builder: (sheetContext) => AppBottomSheet(title: 'Add photo', child: …),
/// );
/// ```
///
/// For a yes/no question use [AppBottomSheet.confirm].
class AppBottomSheet extends StatelessWidget {
  /// Content sheet: optional header (icon, title, message), scrolling body,
  /// actions pinned at the bottom.
  const AppBottomSheet({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.child,
    this.actions = const <Widget>[],
    this.centerHeader = false,
    this.canDismiss = true,
  })  : itemCount = null,
        itemBuilder = null;

  /// List sheet: title pinned, lazily built rows scroll (e.g. All transactions).
  const AppBottomSheet.list({
    super.key,
    this.title,
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.actions = const <Widget>[],
    this.canDismiss = true,
  })  : icon = null,
        message = null,
        child = null,
        centerHeader = false;

  /// Usually `AppIconBadge(size: AppIconBadgeSize.lg)`.
  final Widget? icon;

  /// Shown in [AppTextStyles.sheetTitle] and announced as a header.
  final String? title;

  /// Supporting text under the title.
  final String? message;
  final Widget? child;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;

  /// Full width, stacked, [AppSpacing.md] apart.
  final List<Widget> actions;

  /// Centre icon/title/message (confirmation style).
  final bool centerHeader;

  /// false → back and scrim taps are ignored (PopScope). Drag-to-dismiss
  /// calls Navigator.pop directly and IGNORES PopScope, so any sheet that
  /// ever sets canDismiss: false must be shown with enableDrag: false.
  final bool canDismiss;

  /// Shows a modal sheet whose [builder] returns an [AppBottomSheet]. Wrap the
  /// sheet in `Obx` or `StatefulBuilder` to change [canDismiss] while open.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: false,
      backgroundColor: AppColors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
    );
  }

  /// Asks a yes/no question. Resolves `true` on [confirmLabel] and `false` on
  /// [cancelLabel], back or a scrim tap.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    String? message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    IconData? icon,
    bool destructive = false,
  }) async {
    final result = await show<bool>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        centerHeader: true,
        icon: icon == null
            ? null
            : AppIconBadge(
                icon: icon,
                size: AppIconBadgeSize.lg,
                tone: destructive
                    ? AppIconBadgeTone.error
                    : AppIconBadgeTone.primary,
              ),
        title: title,
        message: message,
        actions: [
          AppButton(
            label: confirmLabel,
            variant: destructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            size: AppButtonSize.lg,
            isFullWidth: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.lg,
            isFullWidth: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  bool get _isList => itemBuilder != null;

  Widget _centered(Widget child) => centerHeader ? Center(child: child) : child;

  Widget _title() => Semantics(
        header: true,
        child: Text(
          title!,
          style: AppTextStyles.sheetTitle,
          textAlign: centerHeader ? TextAlign.center : null,
        ),
      );

  List<Widget> _header() {
    return [
      if (icon != null) _centered(icon!),
      if (icon != null && (title != null || message != null))
        const SizedBox(height: AppSpacing.lg),
      if (title != null) _centered(_title()),
      if (title != null && message != null)
        const SizedBox(height: AppSpacing.sm),
      if (message != null)
        _centered(
          Text(
            message!,
            textAlign: centerHeader ? TextAlign.center : null,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
    ];
  }

  Widget _body() {
    final header = _header();
    return Flexible(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sheetPadding,
          AppSpacing.sm,
          AppSpacing.sheetPadding,
          actions.isEmpty ? AppSpacing.xxl : AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...header,
            if (child != null) ...[
              if (header.isNotEmpty) const SizedBox(height: AppSpacing.xl),
              child!,
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _list() {
    return [
      if (title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sheetPadding,
            AppSpacing.sm,
            AppSpacing.sheetPadding,
            AppSpacing.lg,
          ),
          child: _title(),
        ),
      Flexible(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sheetPadding,
            0,
            AppSpacing.sheetPadding,
            AppSpacing.xxl,
          ),
          itemCount: itemCount!,
          itemBuilder: itemBuilder!,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canDismiss,
      child: Padding(
        // Keeps focused fields above the keyboard.
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              // Decorative: the sheet can always be closed another way.
              ExcludeSemantics(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_isList) ..._list() else _body(),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sheetPadding,
                    0,
                    AppSpacing.sheetPadding,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        actions[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
