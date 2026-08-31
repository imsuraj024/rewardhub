import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';

/// Severity of a toast, driving its colors and leading icon.
enum ToastType { success, error, warning, info }

/// App-wide toast/snackbar helper built on top of GetX snackbars.
///
/// Use the named helpers instead of calling [Get.snackbar] directly so every
/// toast shares the same styling, position and behaviour:
///
/// ```dart
/// AppToast.success('Profile updated');
/// AppToast.error('Something went wrong', title: 'Upload failed');
/// ```
abstract final class AppToast {
  /// Redirects toast presentation, for tests.
  ///
  /// GetX snackbars ignore `Get.testMode` and reach straight for a live
  /// overlay, so a controller test that raises a toast would otherwise throw
  /// (`Get.closeAllSnackbars` hits an uninitialised field, `Get.rawSnackbar`
  /// null-checks a missing context). Tests point this at a recorder instead;
  /// see `test/helpers/harness.dart`. `null` in production, where toasts go
  /// through GetX as normal.
  @visibleForTesting
  static void Function(ToastType type, String message, String? title)?
  presenter;

  /// Green — an action completed successfully.
  static void success(String message, {String? title}) =>
      _show(ToastType.success, message, title);

  /// Red — an action failed or produced an error.
  static void error(String message, {String? title}) =>
      _show(ToastType.error, message, title);

  /// Amber — a caution the user should be aware of.
  static void warning(String message, {String? title}) =>
      _show(ToastType.warning, message, title);

  /// Blue — neutral, informational message.
  static void info(String message, {String? title}) =>
      _show(ToastType.info, message, title);

  static void _show(ToastType type, String message, String? title) {
    final presentWith = presenter;
    if (presentWith != null) {
      presentWith(type, message, title);
      return;
    }

    // Avoid stacking duplicate toasts on rapid triggers.
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();

    final scheme = _schemeFor(type);
    Get.rawSnackbar(
      messageText: _Body(
        icon: scheme.icon,
        accent: scheme.accent,
        title: title ?? scheme.defaultTitle,
        message: message,
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: scheme.background,
      borderColor: scheme.accent.withValues(alpha: 0.4),
      borderWidth: 1,
      borderRadius: 14,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 250),
      snackStyle: SnackStyle.FLOATING,
      dismissDirection: DismissDirection.horizontal,
      boxShadows: const [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static _ToastScheme _schemeFor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const _ToastScheme(
          icon: Icons.check_circle_rounded,
          accent: AppColors.success,
          background: AppColors.successContainer,
          onContainer: AppColors.onSuccessContainer,
          defaultTitle: 'Success',
        );
      case ToastType.error:
        return const _ToastScheme(
          icon: Icons.error_rounded,
          accent: AppColors.error,
          background: AppColors.errorContainer,
          onContainer: AppColors.onErrorContainer,
          defaultTitle: 'Something went wrong',
        );
      case ToastType.warning:
        return const _ToastScheme(
          icon: Icons.warning_rounded,
          accent: AppColors.warning,
          background: AppColors.warningContainer,
          onContainer: AppColors.onWarningContainer,
          defaultTitle: 'Heads up',
        );
      case ToastType.info:
        return const _ToastScheme(
          icon: Icons.info_rounded,
          accent: AppColors.info,
          background: AppColors.infoContainer,
          onContainer: AppColors.onInfoContainer,
          defaultTitle: 'Info',
        );
    }
  }
}

class _ToastScheme {
  const _ToastScheme({
    required this.icon,
    required this.accent,
    required this.background,
    required this.onContainer,
    required this.defaultTitle,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final Color onContainer;
  final String defaultTitle;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
