import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/core/widgets/app_state_message.dart';
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
    final errorMessage =
        state is ViewStateError<ProfileModel> ? state.message : null;

    return Column(
      children: [
        // Scrollable content fills the available space above the pinned footer.
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLowest,
            onRefresh: () => controller.loadProfile(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageGutter,
              ),
              children: [
                const SizedBox(height: AppSpacing.xxl),
                _ProfileHeader(profile: profile),
                const SizedBox(height: AppSpacing.xxl),
                // When the request fails, an error card with "Try again"
                // replaces the API-dependent sections; the rest of the page
                // (settings, logout, version) stays visible.
                if (errorMessage != null) ...[
                  AppStateMessage(
                    icon: Icons.cloud_off_rounded,
                    tone: AppIconBadgeTone.error,
                    title: "Couldn't load your profile",
                    message: errorMessage,
                    actionLabel: 'Try again',
                    onAction: () => controller.loadProfile(force: true),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ] else ...[
                  _StatsRow(profile: profile),
                  const SizedBox(height: AppSpacing.xxl),
                  _BankDetailsSection(profile: profile),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    'Account settings',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsList(profile: profile),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
        // Logout stays pinned to the bottom regardless of content length.
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            AppSpacing.xxl,
          ),
          child: Column(
            children: [
              _LogoutButton(),
              SizedBox(height: AppSpacing.sm),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const SkeletonBox(
            width: double.infinity,
            height: 108,
            radius: AppRadius.xl,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: SkeletonBox(width: 160, height: 22, radius: AppRadius.sm),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 72, radius: AppRadius.lg)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 72, radius: AppRadius.lg)),
            ],
          ),
          const SizedBox(height: 28),
          const SkeletonBox(width: 140, height: 16),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(
            width: double.infinity,
            height: 72,
            radius: AppRadius.lg,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.profile});
  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.trim() ?? '';

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
                borderRadius: BorderRadius.circular(AppRadius.xl),
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
                  child: name.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: AppColors.primary,
                        )
                      : Text(
                          name[0].toUpperCase(),
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
        if (name.isNotEmpty)
          Text(
            name,
            style: AppTextStyles.headlineSm,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _glow(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.onPrimary.withValues(alpha: opacity),
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
            label: 'Referral code',
            valueColor: AppColors.primary,
            icon: Icons.card_giftcard_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            value: profile?.mobile ?? '—',
            label: 'Mobile number',
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
    required this.icon,
  });

  final String value;
  final String label;
  final Color valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppIconBadge(icon: icon, size: AppIconBadgeSize.sm),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelSm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
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
        // container: keeps the header flag off the rest of the section.
        Semantics(
          header: true,
          container: true,
          child: Text('Payment details', style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
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
              // UPI ID Entry
              _BankDetailItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'UPI ID or Google Pay number',
                value: hasUpi ? upi! : 'Not added',
                isAvailable: hasUpi,
              ),
              const SizedBox(height: AppSpacing.md),
              // Bank Account Entries
              if (hasBank) ...[
                if (_isValid(bankName)) ...[
                  _BankDetailItem(
                    icon: Icons.account_balance_rounded,
                    label: 'Bank name',
                    value: bankName!,
                  ),
                  if (_isValid(accNo) || _isValid(ifsc) || _isValid(bankAddr))
                    const SizedBox(height: AppSpacing.md),
                ],
                if (_isValid(accNo)) ...[
                  _accountNumberItem(accNo!),
                  if (_isValid(ifsc) || _isValid(bankAddr))
                    const SizedBox(height: AppSpacing.md),
                ],
                if (_isValid(ifsc)) ...[
                  _BankDetailItem(
                    icon: Icons.tag_rounded,
                    label: 'IFSC code',
                    value: ifsc!,
                  ),
                  if (_isValid(bankAddr))
                    const SizedBox(height: AppSpacing.md),
                ],
                if (_isValid(bankAddr))
                  _BankDetailItem(
                    icon: Icons.location_on_rounded,
                    label: 'Bank address',
                    value: bankAddr!,
                  ),
              ] else
                const _BankDetailItem(
                  icon: Icons.account_balance_rounded,
                  label: 'Bank account',
                  value: 'Not added',
                  isAvailable: false,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('To change these, email support.', style: AppTextStyles.bodySm),
      ],
    );
  }

  /// Shows only the last 4 digits; TalkBack reads "ending in" instead of the
  /// bullets.
  Widget _accountNumberItem(String accNo) {
    final masked = _maskAccount(accNo);
    final trimmed = accNo.trim();
    final isMasked = masked != trimmed;
    return _BankDetailItem(
      icon: Icons.credit_card_rounded,
      label: 'Account number',
      value: masked,
      semanticLabel: isMasked
          ? 'Account number, ending in ${trimmed.substring(trimmed.length - 4)}'
          : null,
    );
  }

  String _maskAccount(String v) {
    final t = v.trim();
    return t.length > 4 ? '•••• ${t.substring(t.length - 4)}' : t;
  }
}

class _BankDetailItem extends StatelessWidget {
  const _BankDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isAvailable = true,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isAvailable;

  /// Replaces the merged label + value for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        AppIconBadge(icon: icon, size: AppIconBadgeSize.sm),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySm),
              const SizedBox(height: 2),
              Text(
                value,
                style: isAvailable
                    ? AppTextStyles.titleSm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      )
                    : AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
            ],
          ),
        ),
      ],
    );

    final spoken = semanticLabel;
    if (spoken != null) {
      return Semantics(
        container: true,
        label: spoken,
        excludeSemantics: true,
        child: row,
      );
    }
    return MergeSemantics(child: row);
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
    AppBottomSheet.show<void>(
      context: context,
      builder: (_) => _WhatsNewBottomSheetContent(notes: notes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final releaseNotes = _getReleaseNotes();

    final items = <({
      IconData icon,
      String title,
      String subtitle,
      AppIconBadgeTone tone,
      VoidCallback? onTap,
    })>[
          if (releaseNotes.isNotEmpty)
            (
              icon: Icons.auto_awesome_rounded,
              title: "What's new",
              subtitle: 'Latest features and improvements',
              tone: AppIconBadgeTone.primary,
              onTap: () {
                if (Get.isRegistered<AppAnalytics>()) {
                  Get.find<AppAnalytics>().settingsItemTapped('whats_new');
                }
                _showWhatsNewBottomSheet(context, releaseNotes);
              },
            ),
          (
            icon: Icons.card_giftcard_rounded,
            title: 'Invite friends',
            subtitle: 'Earn bonus points for referring friends',
            tone: AppIconBadgeTone.primary,
            onTap: () {
              if (Get.isRegistered<AppAnalytics>()) {
                Get.find<AppAnalytics>().settingsItemTapped('invite_friends');
              }
              _showReferralBottomSheet(context, profile);
            },
          ),
          (
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'FAQs and contact support',
            tone: AppIconBadgeTone.primary,
            onTap: () {
              if (Get.isRegistered<AppAnalytics>()) {
                Get.find<AppAnalytics>().settingsItemTapped('help_and_support');
              }
              Get.toNamed(AppRoutes.faq);
            },
          ),
          (
            icon: Icons.delete_outline_rounded,
            title: 'Delete account',
            subtitle: 'Permanently delete your account and data',
            tone: AppIconBadgeTone.error,
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // Clips the row ripples to the card's corners.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (final item in items)
                _SettingsRow(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  tone: item.tone,
                  onTap: item.onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolved once per process: the value can't change while the app is
/// running. Shared by the What's new sheet and the version footer.
Future<PackageInfo>? _packageInfoCache;
Future<PackageInfo> _packageInfo() =>
    _packageInfoCache ??= PackageInfo.fromPlatform();

class _WhatsNewBottomSheetContent extends StatelessWidget {
  const _WhatsNewBottomSheetContent({required this.notes});

  final List<String> notes;

  /// "Title: details" notes split into a title and a subtitle; a note without
  /// a colon is a title only.
  List<({String title, String? subtitle})> _buildFeatureItems() {
    return notes.map((note) {
      if (!note.contains(':')) return (title: note, subtitle: null);
      final parts = note.split(':');
      return (
        title: parts[0].trim(),
        subtitle: parts.sublist(1).join(':').trim(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildFeatureItems();

    return FutureBuilder<PackageInfo>(
      future: _packageInfo(),
      builder: (context, snapshot) => AppBottomSheet(
        centerHeader: true,
        icon: const AppIconBadge(
          icon: Icons.rocket_launch_rounded,
          size: AppIconBadgeSize.lg,
          circular: true,
        ),
        title: "What's new",
        message: snapshot.hasData ? 'Version ${snapshot.data!.version}' : null,
        actions: [
          AppButton(
            label: 'Got it',
            size: AppButtonSize.lg,
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final i in items) _NoteRow(item: i)],
            ),
          ),
        ),
      ),
    );
  }
}

/// One release note in the What's new sheet.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.item});

  final ({String title, String? subtitle}) item;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.subtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconBadge(
            icon: Icons.check_circle_rounded,
            size: AppIconBadgeSize.sm,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: AppTextStyles.listTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySm),
                ],
              ],
            ),
          ),
        ],
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

  // The profile id is missing on the error and initial states.
  final hasCode = referralCode != '—';

  final codeBox = Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your referral code', style: AppTextStyles.overline),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  referralCode,
                  maxLines: 1,
                  style: AppTextStyles.titleLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppButton(
          label: 'Copy',
          variant: AppButtonVariant.tonal,
          size: AppButtonSize.sm,
          leadingIcon: const Icon(Icons.copy_rounded),
          semanticLabel: 'Copy referral code',
          onPressed: hasCode
              ? () => ExternalLinks.copy(
                    referralCode,
                    message: 'Referral code copied.',
                  )
              : null,
        ),
      ],
    ),
  );

  final infoTip = Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Points will be credited automatically once your referred friend completes registration.',
            style: AppTextStyles.bodySm,
          ),
        ),
      ],
    ),
  );

  AppBottomSheet.show<void>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      centerHeader: true,
      icon: const AppIconBadge(
        icon: Icons.card_giftcard_rounded,
        size: AppIconBadgeSize.lg,
      ),
      title: 'Invite friends',
      message:
          'Share your code with friends. When they register using your code, both of you start earning reward points!',
      actions: [
        AppButton(
          label: 'Copy invite message',
          size: AppButtonSize.lg,
          isFullWidth: true,
          leadingIcon: const Icon(Icons.copy_all_rounded),
          onPressed: hasCode
              ? () => ExternalLinks.copy(
                    inviteMessage,
                    message: 'Invite copied. Paste it in WhatsApp or SMS.',
                  )
              : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          codeBox,
          const SizedBox(height: AppSpacing.lg),
          infoTip,
        ],
      ),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = AppIconBadgeTone.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppIconBadgeTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                AppIconBadge(icon: icon, tone: tone),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.listTitle),
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
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton();

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isLoggingOut = false;

  Future<void> _confirmLogout() async {
    final confirmed = await AppBottomSheet.confirm(
      context: context,
      title: 'Log out?',
      message: "You'll need your mobile number to log in again.",
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    if (!Get.isRegistered<AuthController>()) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    setState(() => _isLoggingOut = true);
    try {
      // Clears the stored session, then replaces the stack with Login.
      await Get.find<AuthController>().logout();
    } catch (e, st) {
      log(
        'logout failed',
        name: 'rewardhub.profile',
        error: e,
        stackTrace: st,
      );
      AppToast.error("Couldn't log you out. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Log out',
      variant: AppButtonVariant.outline,
      size: AppButtonSize.lg,
      isFullWidth: true,
      isLoading: _isLoggingOut,
      leadingIcon: const Icon(Icons.logout_rounded),
      onPressed: _confirmLogout,
    );
  }
}

/// Footer showing the running build's version.
///
/// The version is read from the platform package metadata rather than written
/// as a literal, so it tracks `pubspec.yaml` instead of silently going stale
/// after a release bump.
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<PackageInfo>(
        future: _packageInfo(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version;
          final patchNumber = Get.isRegistered<ShorebirdUpdateService>()
              ? Get.find<ShorebirdUpdateService>().currentPatchNumber
              : null;
          final versionText = version != null
              ? (patchNumber != null
                    ? 'Version $version ($patchNumber)'
                    : 'Version $version')
              : null;

          return Text(
            versionText == null
                ? AppStrings.productName
                : '$versionText  •  ${AppStrings.productName}',
            style: AppTextStyles.labelSm,
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }
}

void _showDeleteAccountBottomSheet(BuildContext context) {
  // Drag is off because a drag ignores PopScope, and the sheet must stay open
  // while the account is being deleted.
  AppBottomSheet.show<void>(
    context: context,
    enableDrag: false,
    builder: (_) => const _DeleteAccountBottomSheet(),
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

    if (!mounted) return;
    if (success) {
      // Replaces the whole stack, this sheet included.
      Get.offAllNamed(AppRoutes.login);
      AppToast.success('Your account is deleted.');
    } else {
      setState(() {
        _isDeleting = false;
        _errorMessage =
            authController.errorMessage ??
            "Couldn't delete your account. Check your internet and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final consequencesBox = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('If you delete your account:', style: AppTextStyles.listTitle),
          const SizedBox(height: AppSpacing.sm),
          const _WarningBullet(
            text: 'All earned reward points & wallet balance will be wiped.',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _WarningBullet(
            text: 'Pending withdrawal/cash-out requests will be voided.',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _WarningBullet(
            text: 'Transaction logs, KYC status, and referral codes will be erased.',
          ),
        ],
      ),
    );

    return AppBottomSheet(
      canDismiss: !_isDeleting,
      icon: const AppIconBadge(
        icon: Icons.warning_amber_rounded,
        tone: AppIconBadgeTone.error,
        size: AppIconBadgeSize.lg,
      ),
      title: 'Delete account',
      message: "This can't be undone.",
      actions: [
        AppButton(
          label: 'Delete account',
          variant: AppButtonVariant.destructive,
          size: AppButtonSize.lg,
          isFullWidth: true,
          isLoading: _isDeleting,
          onPressed: _canDelete ? _handleDelete : null,
        ),
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.lg,
          isFullWidth: true,
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          consequencesBox,
          const SizedBox(height: AppSpacing.lg),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _understandConsequences,
            onChanged: _isDeleting
                ? null
                : (v) => setState(() => _understandConsequences = v ?? false),
            title: Text(
              'I understand I will lose all my points and data.',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Type $_requiredPhrase to confirm',
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _confirmationController,
            enabled: !_isDeleting,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: _requiredPhrase,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                _errorMessage!,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
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
        ExcludeSemantics(
          child: Text(
            '•',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }
}
