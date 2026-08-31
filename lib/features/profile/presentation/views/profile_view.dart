import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Profile'),
      body: SafeArea(
        top: false,
        child: Obx(() => _buildBody(controller.state)),
      ),
    );
  }

  Widget _buildBody(ViewState<ProfileModel> state) {
    // Only take over the whole screen while the first load is in flight and we
    // have nothing to show yet. On error we still render the page below so the
    // API-independent sections (settings, logout, version) stay usable.
    if (state is ViewStateLoading) {
      return const _ProfileSkeleton();
    }

    final profile = (state is ViewStateSuccess<ProfileModel>)
        ? state.data
        : null;
    final hasError = state is ViewStateError<ProfileModel>;

    return Column(
      children: [
        // Scrollable content fills the available space above the pinned footer.
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 24),
              _ProfileHeader(profile: profile),
              const SizedBox(height: 24),
              // Hide the API-dependent stats when the request fails; the rest of
              // the page (settings, logout, version) stays visible.
              if (!hasError) ...[
                _StatsRow(profile: profile),
                const SizedBox(height: 24),
                _BankDetailsSection(profile: profile),
                const SizedBox(height: 24),
              ],
              Text('Account Settings', style: AppTextStyles.titleMd),
              const SizedBox(height: 12),
              _SettingsList(profile: profile),
              const SizedBox(height: 24),
            ],
          ),
        ),
        // Logout stays pinned to the bottom regardless of content length.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: const [
              _LogoutButton(),
              SizedBox(height: 8),
              _VersionFooter(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmering placeholder shown while the profile loads for the first time.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          const SkeletonBox(width: double.infinity, height: 108, radius: 20),
          const SizedBox(height: 24),
          Center(child: SkeletonBox(width: 160, height: 22, radius: 8)),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 72, radius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 72, radius: 16)),
            ],
          ),
          const SizedBox(height: 28),
          const SkeletonBox(width: 140, height: 16),
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 72, radius: 16),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.profile});
  final ProfileModel? profile;

  /// First-letter initial used as an avatar fallback.
  String get _initial {
    final name = profile?.name.trim() ?? '';
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Gradient hero banner with soft decorative glows.
            Container(
              width: double.infinity,
              height: 108,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(top: -24, right: -10, child: _glow(110, 0.12)),
                  Positioned(bottom: -40, left: 24, child: _glow(80, 0.08)),
                ],
              ),
            ),
            // Avatar overlapping the bottom edge of the banner.
            Positioned(
              bottom: -44,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(
                    color: AppColors.surfaceContainerLowest,
                    width: 4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryFixed,
                  child: Text(
                    _initial,
                    style: AppTextStyles.headlineSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 56),
        Text(profile?.name ?? 'User', style: AppTextStyles.headlineSm),
      ],
    );
  }

  Widget _glow(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({this.profile});
  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final referralCode = Get.find<ProfileController>().generateReferralCode(
      profile?.id,
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: referralCode,
            label: 'Referral Code',
            valueColor: AppColors.primary,
            icon: Icons.card_giftcard_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: profile?.mobile ?? '—',
            label: 'Mobile Number',
            valueColor: AppColors.primary,
            icon: Icons.smartphone_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    this.icon,
  });

  final String value;
  final String label;
  final Color valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
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
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 12, color: AppColors.primary),
              ),
              Text(label, style: AppTextStyles.labelSm),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.titleMd.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankDetailsSection extends StatelessWidget {
  const _BankDetailsSection({this.profile});

  final ProfileModel? profile;

  bool _isValid(String? val) {
    if (val == null) return false;
    final trimmed = val.trim();
    return trimmed.isNotEmpty && trimmed.toUpperCase() != 'NA';
  }

  @override
  Widget build(BuildContext context) {
    final upi = profile?.upiId;
    final bankName = profile?.bankName;
    final accNo = profile?.accountNumber;
    final ifsc = profile?.ifscCode;
    final bankAddr = profile?.bankAddress;

    final hasUpi = _isValid(upi);
    final hasBank = _isValid(bankName) || _isValid(accNo) || _isValid(ifsc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank & Payment Details', style: AppTextStyles.titleMd),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
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
              // UPI ID Entry
              _BankDetailItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'UPI ID / UPI Number',
                value: hasUpi ? upi! : 'Not Provided',
                isAvailable: hasUpi,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.outlineVariant,
                ),
              ),
              // Bank Account Entries
              if (hasBank) ...[
                if (_isValid(bankName)) ...[
                  _BankDetailItem(
                    icon: Icons.account_balance_rounded,
                    label: 'Bank Name',
                    value: bankName!,
                  ),
                  if (_isValid(accNo) || _isValid(ifsc) || _isValid(bankAddr))
                    const SizedBox(height: 10),
                ],
                if (_isValid(accNo)) ...[
                  _BankDetailItem(
                    icon: Icons.credit_card_rounded,
                    label: 'Account Number',
                    value: accNo!,
                  ),
                  if (_isValid(ifsc) || _isValid(bankAddr))
                    const SizedBox(height: 10),
                ],
                if (_isValid(ifsc)) ...[
                  _BankDetailItem(
                    icon: Icons.tag_rounded,
                    label: 'IFSC Code',
                    value: ifsc!,
                  ),
                  if (_isValid(bankAddr)) const SizedBox(height: 10),
                ],
                if (_isValid(bankAddr))
                  _BankDetailItem(
                    icon: Icons.location_on_rounded,
                    label: 'Bank Address',
                    value: bankAddr!,
                  ),
              ] else
                const _BankDetailItem(
                  icon: Icons.account_balance_rounded,
                  label: 'Bank Account',
                  value: 'Not Provided',
                  isAvailable: false,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BankDetailItem extends StatelessWidget {
  const _BankDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isAvailable = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
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
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.titleSm.copyWith(
                  color: isAvailable ? AppColors.onSurface : AppColors.outline,
                  fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({this.profile});

  final ProfileModel? profile;

  static List<String> _getReleaseNotes() {
    if (!Get.isRegistered<RemoteConfigService>()) return const [];
    final rawNotes = Get.find<RemoteConfigService>().releaseNotes;
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
      return rawNotes
          .split('\n')
          .map((line) => line.trim().replaceFirst(RegExp(r'^[•\-\*]\s*'), ''))
          .where((line) => line.isNotEmpty)
          .toList();
    }
    return const [];
  }

  void _showWhatsNewBottomSheet(BuildContext context, List<String> notes) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WhatsNewBottomSheetContent(notes: notes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final releaseNotes = _getReleaseNotes();

    final items =
        <({IconData icon, String title, String subtitle, VoidCallback? onTap})>[
          if (releaseNotes.isNotEmpty)
            (
              icon: Icons.auto_awesome_rounded,
              title: "What's New",
              subtitle: 'Latest features and improvements',
              onTap: () {
                if (Get.isRegistered<AppAnalytics>()) {
                  Get.find<AppAnalytics>().settingsItemTapped('whats_new');
                }
                _showWhatsNewBottomSheet(context, releaseNotes);
              },
            ),
          (
            icon: Icons.card_giftcard_rounded,
            title: 'Invite Friends & Share',
            subtitle: 'Earn bonus points for referring friends',
            onTap: () {
              if (Get.isRegistered<AppAnalytics>()) {
                Get.find<AppAnalytics>().settingsItemTapped('invite_friends');
              }
              _showReferralBottomSheet(context, profile);
            },
          ),
          (
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQs and contact support',
            onTap: () {
              if (Get.isRegistered<AppAnalytics>()) {
                Get.find<AppAnalytics>().settingsItemTapped('help_and_support');
              }
              Get.toNamed(AppRoutes.faq);
            },
          ),
          (
            icon: Icons.shield_outlined,
            title: 'Account Security & Deletion',
            subtitle: 'Manage account security & deletion options',
            onTap: () {
              if (Get.isRegistered<AppAnalytics>()) {
                Get.find<AppAnalytics>().settingsItemTapped('account_security');
              }
              _showDeleteAccountBottomSheet(context);
            },
          ),
        ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              _SettingsRow(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 64,
                  color: AppColors.outlineVariant,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _WhatsNewBottomSheetContent extends StatelessWidget {
  const _WhatsNewBottomSheetContent({required this.notes});

  final List<String> notes;

  List<({IconData icon, String title, String subtitle})> _buildFeatureItems() {
    if (notes.isEmpty) {
      return const [
        (
          icon: Icons.check_circle_rounded,
          title: 'Faster QR Scanning',
          subtitle: 'Scan and earn points quicker than ever.',
        ),
        (
          icon: Icons.check_circle_rounded,
          title: 'More Secure',
          subtitle: 'Improved login and account protection.',
        ),
        (
          icon: Icons.check_circle_rounded,
          title: 'Smoother Experience',
          subtitle: 'Refined UI and bug fixes for a better experience.',
        ),
      ];
    }

    return notes.map((note) {
      String title = note;
      String subtitle = 'Latest updates & performance improvements.';
      if (note.contains(':')) {
        final parts = note.split(':');
        title = parts[0].trim();
        subtitle = parts.sublist(1).join(':').trim();
      }

      return (
        icon: Icons.check_circle_rounded,
        title: title,
        subtitle: subtitle,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final featureItems = _buildFeatureItems();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Indicator Handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Top Rocket Icon Badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F0FE), Color(0xFFD2E3FC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              "What's New",
              style: AppTextStyles.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Subtitle & Version Label
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.1.0';
                return Text(
                  'Version $version  •  Recent updates & improvements',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 20),

            // Features Card List Container
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                children: List.generate(featureItems.length, (index) {
                  final item = featureItems[index];
                  final isLast = index == featureItems.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTextStyles.titleSm.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 54,
                          endIndent: 16,
                          color: AppColors.outlineVariant,
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Got it Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Got it',
                  style: AppTextStyles.titleSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showReferralBottomSheet(BuildContext context, ProfileModel? profile) {
  final referralCode = Get.find<ProfileController>().generateReferralCode(
    profile?.id,
  );

  final inviteMessage =
      'Join me on ${AppStrings.productName} to scan receipts & earn rewards! '
      'Use my referral code: $referralCode when registering. Download now: https://kitoxhardware.com';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Invite Friends & Share',
              style: AppTextStyles.titleLg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share your code with friends. When they register using your code, both of you start earning reward points!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR REFERRAL CODE',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.outline,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          referralCode,
                          style: AppTextStyles.titleLg.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: referralCode),
                        );
                        AppToast.success(
                          'Referral code copied to clipboard!',
                          title: 'Copied',
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: AppTextStyles.titleSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: inviteMessage));
                    AppToast.success(
                      'Invite link & message copied! Share with friends.',
                      title: 'Ready to Share',
                    );
                  },
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.share_rounded,
                          color: AppColors.onPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Share Invite Link',
                          style: AppTextStyles.titleSm.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Points will be credited automatically once your referred friend completes registration.',
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSm),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySm),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LogoutBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showLogoutBottomSheet(context),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Logout Account',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LogoutStep { confirm, loggingOut, success }

class _LogoutBottomSheet extends StatefulWidget {
  const _LogoutBottomSheet();

  @override
  State<_LogoutBottomSheet> createState() => _LogoutBottomSheetState();
}

class _LogoutBottomSheetState extends State<_LogoutBottomSheet> {
  _LogoutStep _step = _LogoutStep.confirm;

  Future<void> _processLogout() async {
    setState(() {
      _step = _LogoutStep.loggingOut;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _step = _LogoutStep.success;
      });
    }
  }

  void _onOkPressed() {
    Navigator.of(context).pop();
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().logout();
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Drag Handle Indicator
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            if (_step == _LogoutStep.confirm) ...[
              // Confirm Logout State
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEBEE),
                ),
                child: const Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: 36,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Log out?',
                style: AppTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "You'll need to sign in again with your mobile number to access your rewards.",
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        foregroundColor: AppColors.onSurface,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.titleSm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _processLogout,
                      child: Text(
                        'Log out',
                        style: AppTextStyles.titleSm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_step == _LogoutStep.loggingOut) ...[
              // Logging Out Progress State
              const SizedBox(height: 16),
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Logging out...',
                style: AppTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we securely sign you out.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ] else if (_step == _LogoutStep.success) ...[
              // Logout Success State
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F5E9),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logged out successfully',
                style: AppTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You have been signed out of ${AppStrings.productName}.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onOkPressed,
                  child: Text(
                    'OK',
                    style: AppTextStyles.titleSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Footer showing the running build's version.
///
/// The version is read from the platform package metadata rather than written
/// as a literal, so it tracks `pubspec.yaml` instead of silently going stale
/// after a release bump.
class _VersionFooter extends StatefulWidget {
  const _VersionFooter();

  @override
  State<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<_VersionFooter> {
  /// Resolved once per process: the value cannot change while the app is
  /// running, so there is no reason to hit the platform channel on every
  /// rebuild of the profile screen.
  static Future<PackageInfo>? _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo ??= PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final version = snapshot.data?.version;
          final patchNumber = Get.isRegistered<ShorebirdUpdateService>()
              ? Get.find<ShorebirdUpdateService>().currentPatchNumber
              : null;
          final versionText = version != null
              ? (patchNumber != null
                    ? 'VERSION $version (PATCH #$patchNumber)'
                    : 'VERSION $version')
              : null;

          return Text(
            versionText == null
                ? AppStrings.productNameUpper
                : '$versionText  •  ${AppStrings.productNameUpper}',
            style: AppTextStyles.labelSm.copyWith(letterSpacing: 1.1),
          );
        },
      ),
    );
  }
}

void _showDeleteAccountBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _DeleteAccountBottomSheet(),
  );
}

class _DeleteAccountBottomSheet extends StatefulWidget {
  const _DeleteAccountBottomSheet();

  @override
  State<_DeleteAccountBottomSheet> createState() =>
      _DeleteAccountBottomSheetState();
}

class _DeleteAccountBottomSheetState
    extends State<_DeleteAccountBottomSheet> {
  final _confirmationController = TextEditingController();
  bool _understandConsequences = false;
  bool _isDeleting = false;
  String? _errorMessage;

  static const String _requiredPhrase = 'DELETE MY ACCOUNT';

  bool get _canDelete =>
      _understandConsequences &&
      _confirmationController.text.trim() == _requiredPhrase &&
      !_isDeleting;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!_canDelete) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    final authController = Get.find<AuthController>();
    final success = await authController.deleteAccount();

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        AppToast.success(
          'Your account has been permanently deleted.',
          title: 'Account Deleted',
        );
      } else {
        setState(() {
          _isDeleting = false;
          _errorMessage =
              authController.errorMessage ??
              'Account deletion failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: AppTextStyles.titleLg.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Permanent & Irreversible Action',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deleting your account will result in the following:',
                    style: AppTextStyles.titleSm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _WarningBullet(
                    text: 'All earned reward points & wallet balance will be wiped.',
                  ),
                  const SizedBox(height: 4),
                  const _WarningBullet(
                    text: 'Pending withdrawal/cash-out requests will be voided.',
                  ),
                  const SizedBox(height: 4),
                  const _WarningBullet(
                    text: 'Transaction logs, KYC status, and referral codes will be erased.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _understandConsequences,
              onChanged: (val) {
                setState(() {
                  _understandConsequences = val ?? false;
                });
              },
              title: Text(
                'I understand that all my reward points & account data will be permanently lost.',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'To confirm, type "$_requiredPhrase" in UPPERCASE:',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmationController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _requiredPhrase,
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.titleSm.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.onError,
                      disabledBackgroundColor:
                          AppColors.error.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _canDelete ? _handleDelete : null,
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onError,
                            ),
                          )
                        : Text(
                            'Delete Account',
                            style: AppTextStyles.titleSm.copyWith(
                              color: _canDelete
                                  ? AppColors.onError
                                  : AppColors.onError.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBullet extends StatelessWidget {
  const _WarningBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurface,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
