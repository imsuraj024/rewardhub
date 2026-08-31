import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
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
        AppToast.success('Maintenance completed! Welcome back.');
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().restoreSession();
        }
      } else {
        AppToast.info(
          'We are still working on scheduled updates. Please check back shortly.',
          title: 'Under Maintenance',
        );
      }
    } catch (_) {
      AppToast.error(
        'Could not verify status. Please check your internet connection.',
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    AppToast.success('$label copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = Get.isRegistered<RemoteConfigService>()
        ? Get.find<RemoteConfigService>()
        : null;

    final message =
        remoteConfig?.maintenanceMessage ??
        'Kitox Hardware is temporarily unavailable. We are making improvements to serve you better.';
    final phone = remoteConfig?.supportPhone ?? '+91 98765 43210';
    final email = remoteConfig?.supportEmail ?? 'support@kitoxhardware.com';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Ambient maintenance badge
                Container(
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
                ),
                const SizedBox(height: 32),

                // Headline
                Text(
                  'Under Maintenance',
                  style: AppTextStyles.headlineMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle message from Remote Config
                Text(
                  message,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Support contact section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
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
                        'Need urgent assistance?',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ContactRow(
                        icon: Icons.phone_outlined,
                        label: 'Support Phone',
                        value: phone,
                        onTap: () => _copyToClipboard(phone, 'Phone number'),
                      ),
                      const Divider(
                        height: 20,
                        thickness: 0.5,
                        color: AppColors.outlineVariant,
                      ),
                      _ContactRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Support Email',
                        value: email,
                        onTap: () => _copyToClipboard(email, 'Email address'),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Action button: Check Status
                AppButton(
                  label: 'Check Status',
                  isFullWidth: true,
                  isLoading: _isChecking,
                  leadingIcon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: _checkStatus,
                ),
                const SizedBox(height: 16),

                // Brand text
                Text(
                  AppStrings.productNameUpper,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.titleSm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.copy_rounded,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
