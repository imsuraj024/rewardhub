import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

/// Full-screen view displayed when the app is placed in maintenance mode
/// via Firebase Remote Config.
class MaintenanceView extends StatefulWidget {
  const MaintenanceView({super.key});

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      if (Get.isRegistered<RemoteConfigService>()) {
        await Get.find<RemoteConfigService>().fetchAndActivate();
      }

      final isStillUnderMaintenance = Get.isRegistered<RemoteConfigService>()
          ? Get.find<RemoteConfigService>().isMaintenanceMode
          : false;

      if (!isStillUnderMaintenance) {
        AppToast.success('Maintenance is over. Welcome back.');
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().restoreSession();
        }
      } else {
        AppToast.info('Still under maintenance. Please try again later.');
      }
    } catch (_) {
      AppToast.error(
        "Couldn't check the status. Check your internet and try again.",
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = Get.isRegistered<RemoteConfigService>()
        ? Get.find<RemoteConfigService>()
        : null;

    final message = remoteConfig?.maintenanceMessage ??
        '${AppStrings.productName} is temporarily unavailable. We are making improvements to serve you better.';
    final phone = remoteConfig?.supportPhone ?? '';
    final email = remoteConfig?.supportEmail ?? 'support@kitoxhardware.com';

    // Remote Config can blank a value to hide its row.
    final showPhone = phone.trim().isNotEmpty;
    final showEmail = email.trim().isNotEmpty;
    final showContacts = showPhone || showEmail;

    final badge = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.construction_rounded,
        size: 52,
        color: AppColors.warning,
      ),
    );

    final contactCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help now?',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (showPhone)
            _ContactRow(
              icon: Icons.phone_rounded,
              label: 'Call support',
              value: phone,
              copyTooltip: 'Copy phone number',
              onTap: () => ExternalLinks.openOrCopy(
                ExternalLinks.phone(phone),
                fallbackText: phone,
                fallbackMessage:
                    "Couldn't open the phone app. Phone number copied.",
              ),
              onCopy: () =>
                  ExternalLinks.copy(phone, message: 'Phone number copied.'),
            ),
          if (showPhone && showEmail) const SizedBox(height: AppSpacing.sm),
          if (showEmail)
            _ContactRow(
              icon: Icons.mail_rounded,
              label: 'Email support',
              value: email,
              copyTooltip: 'Copy email address',
              onTap: () => ExternalLinks.openOrCopy(
                ExternalLinks.email(email),
                fallbackText: email,
                fallbackMessage:
                    "Couldn't open your email app. Email address copied.",
              ),
              onCopy: () =>
                  ExternalLinks.copy(email, message: 'Email address copied.'),
            ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          // Scrolls when the content is taller than the screen; on tall
          // screens spaceBetween keeps the button at the bottom.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.authGutter,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(
                    0.0,
                    constraints.maxHeight - 2 * AppSpacing.xl,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: AppSpacing.xxl),
                        badge,
                        const SizedBox(height: AppSpacing.xxxl),
                        Text(
                          'Under maintenance',
                          style: AppTextStyles.headlineMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Subtitle message from Remote Config
                        Text(
                          message,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        if (showContacts) contactCard,
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: AppSpacing.xxl),
                        AppButton(
                          label: 'Try again',
                          isFullWidth: true,
                          isLoading: _isChecking,
                          leadingIcon: const Icon(Icons.refresh_rounded),
                          onPressed: _checkStatus,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Brand mark
                        Text(
                          AppStrings.productNameUpper,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A support contact: tap the row to call or email, or copy the value with
/// the 48 dp button.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.copyTooltip,
    required this.onTap,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final String copyTooltip;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Semantics(
              button: true,
              label: '$label, $value',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    AppIconBadge(icon: icon, size: AppIconBadgeSize.sm),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: AppTextStyles.bodySm),
                          Text(
                            value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onCopy,
          tooltip: copyTooltip,
          icon: const Icon(
            Icons.copy_rounded,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
