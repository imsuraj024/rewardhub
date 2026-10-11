import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen view presented when an app update is required, redirecting
/// users to the Google Play Store or Apple App Store with remote release notes.
///
/// When the store can't be opened, it says so and offers the link to copy.
class AppUpdateView extends StatefulWidget {
  const AppUpdateView({super.key});

  @override
  State<AppUpdateView> createState() => _AppUpdateViewState();
}

class _AppUpdateViewState extends State<AppUpdateView> {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.loyalty.rewardhub';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/rewardhub/id6740000000';

  bool _isOpening = false;
  bool _openFailed = false;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  String get _storeUrl => _isIos ? _appStoreUrl : _playStoreUrl;

  RemoteConfigService? get _remoteConfig =>
      Get.isRegistered<RemoteConfigService>()
      ? Get.find<RemoteConfigService>()
      : null;

  Future<void> _openStore() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    final uri = Uri.parse(_storeUrl);
    var opened = await ExternalLinks.open(uri); // externalApplication
    if (!opened) {
      opened = await ExternalLinks.open(uri, mode: LaunchMode.platformDefault);
    }
    if (!mounted) return;
    setState(() {
      _isOpening = false;
      _openFailed = !opened;
    });
    if (!opened) {
      AppToast.error(
        _isIos
            ? "Couldn't open the App Store. Copy the link below and open it in your browser."
            : "Couldn't open the Play Store. Copy the link below and open it in your browser.",
      );
    }
  }

  List<String> _getReleaseNotesList() {
    final rawNotes = _remoteConfig?.releaseNotes;
    if (rawNotes == null ||
        rawNotes.trim().isEmpty ||
        rawNotes.trim() == 'null') {
      return const [];
    }

    try {
      final decoded = jsonDecode(rawNotes);
      if (decoded is List) {
        return decoded
            .map((item) {
              if (item is String) return item.trim();
              if (item is Map && item['text'] != null) {
                return item['text'].toString().trim();
              }
              return item.toString().trim();
            })
            .where((line) => line.isNotEmpty)
            .toList();
      } else if (decoded is Map && decoded['notes'] is List) {
        return (decoded['notes'] as List)
            .map((item) => item.toString().trim())
            .where((line) => line.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Fallback: If formatted as raw multiline string
      return rawNotes
          .split('\n')
          .map((line) => line.trim().replaceFirst(RegExp(r'^[•\-\*]\s*'), ''))
          .where((line) => line.isNotEmpty)
          .toList();
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final releaseNotes = _getReleaseNotesList();
    final isIos = _isIos;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.authGutter,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 2 * AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          // Hero badge
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.rocket_launch_rounded,
                                size: 48,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          Text(
                            'Update required',
                            style: AppTextStyles.headlineMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),

                          // Subtitle
                          Text(
                            'This version of ${AppStrings.productName} no longer works. Update the app to keep scanning and redeeming points.',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Release Notes Container (Hidden if empty or null)
                          if (releaseNotes.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                AppSpacing.cardPadding,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
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
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "What's new",
                                        style: AppTextStyles.labelLg.copyWith(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  for (
                                    int i = 0;
                                    i < releaseNotes.length;
                                    i++
                                  ) ...[
                                    _ReleaseNoteRow(text: releaseNotes[i]),
                                    if (i < releaseNotes.length - 1)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),

                      // Action Buttons & Version
                      Column(
                        children: [
                          AppButton(
                            label: isIos
                                ? 'Update on App Store'
                                : 'Update on Play Store',
                            isFullWidth: true,
                            isLoading: _isOpening,
                            leadingIcon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            onPressed: _openStore,
                          ),
                          if (_openFailed) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: 'Copy store link',
                              variant: AppButtonVariant.outline,
                              size: AppButtonSize.lg,
                              isFullWidth: true,
                              leadingIcon: const Icon(Icons.link_rounded),
                              onPressed: () => ExternalLinks.copy(
                                _storeUrl,
                                message:
                                    'Link copied. Paste it in your browser.',
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          const _AppVersionLabel(),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReleaseNoteRow extends StatelessWidget {
  const _ReleaseNoteRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppVersionLabel extends StatelessWidget {
  const _AppVersionLabel();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version;
        return Text(
          version != null
              ? 'Version $version  •  ${AppStrings.productName}'
              : AppStrings.productName,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
