import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/models/banner_model.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_format.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_banner.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/core/widgets/points_balance_card.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:rewardhub/features/wallet/presentation/widgets/redeem_confirmation.dart';

/// True when the text is too large for three-up step layouts.
bool _isLargeText(BuildContext c) =>
    MediaQuery.textScalerOf(c).scale(14) / 14 > 1.3;

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final walletController = Get.find<WalletController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => Future.wait([
            profileController.loadProfile(),
            controller.loadActivities(),
          ]),
          child: Obx(() {
            final profileState = profileController.state;
            final profile = profileState is ViewStateSuccess<ProfileModel>
                ? profileState.data
                : null;
            // Initial counts as loading so the first frame never shows an error.
            final profileLoading = profileState is ViewStateLoading ||
                profileState is ViewStateInitial;
            final activitiesState = controller.state;
            final week =
                activitiesState is ViewStateSuccess<List<RecentActivityModel>>
                    ? _Last7Days.from(
                        activitiesState.data ?? const <RecentActivityModel>[],
                      )
                    : null;
            final isWalletSubmitting = walletController.isSubmitting.value;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageGutter,
              ),
              children: [
                const SizedBox(height: AppSpacing.sm),
                _HomeHeader(name: profile?.name, isLoading: profileLoading),
                const SizedBox(height: AppSpacing.lg),
                const _HomePromoBannerSection(),
                const SizedBox(height: AppSpacing.lg),
                PointsBalanceCard(
                  label: 'Your points',
                  points: profile?.points,
                  isLoading: profileLoading,
                  onRetry: () => profileController.loadProfile(force: true),
                  badge: (week != null && week.total > 0)
                      ? _WeekTrendChip(total: week.total)
                      : null,
                  footer: _WeekActivity(state: activitiesState, week: week),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _ScanAndEarnCard(),
                const SizedBox(height: AppSpacing.lg),
                _QuickActions(
                  points: profile?.points,
                  isSubmitting: isWalletSubmitting,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _HowToEarnPointsCard(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Greeting and the user's name, read as one heading. Never invents a name:
/// while the profile loads a skeleton stands in, and without a name the
/// greeting alone is the heading.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.isLoading});

  final String? name;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();
    final trimmedName = name?.trim() ?? '';
    final heading = AppTextStyles.titleLg.copyWith(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w700,
    );
    final greetingLine = Text(
      '$greeting,',
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
    );

    final Widget content;
    if (trimmedName.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          greetingLine,
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  trimmedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: heading,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ExcludeSemantics(
                child: Text('👋', style: AppTextStyles.titleLg),
              ),
            ],
          ),
        ],
      );
    } else if (isLoading) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          greetingLine,
          const SizedBox(height: AppSpacing.xs),
          const Shimmer(child: SkeletonBox(width: 160, height: 24)),
        ],
      );
    } else {
      content = Text(greeting, style: heading);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: MergeSemantics(child: Semantics(header: true, child: content)),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Welcome back';
  }
}

/// Points earned per calendar day over the last 7 days, today last. The trend
/// chip and the chart both read this, so they always agree.
class _Last7Days {
  const _Last7Days._(this.start, this.totals);

  factory _Last7Days.from(List<RecentActivityModel> activities) {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateUtils.addDaysToDate(today, -6);
    final totals = List<int>.filled(7, 0); // oldest → today
    for (final a in activities) {
      if (!a.isCredit) continue;
      final day = DateUtils.dateOnly(a.date.toLocal());
      // Rounded hours, so a daylight-saving hour can't shift the day.
      final i = (day.difference(start).inHours / 24).round();
      if (i >= 0 && i < 7) totals[i] += a.points;
    }
    return _Last7Days._(start, totals);
  }

  /// The oldest day shown (today − 6).
  final DateTime start;

  /// Points earned on each day, oldest → today.
  final List<int> totals;

  int get total => totals.fold(0, (a, b) => a + b);

  int get peak => totals.fold(0, math.max);
}

/// "+{n} in 7 days" chip on the balance card. Hidden when nothing was earned.
class _WeekTrendChip extends StatelessWidget {
  const _WeekTrendChip({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${AppFormat.pointsWithUnit(total)} earned in the last 7 days',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.onPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.north_east_rounded,
              size: 14,
              color: AppColors.onPrimary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                '+${AppFormat.points(total)} in 7 days',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footer of the balance card: the 7-day chart, or why there isn't one.
class _WeekActivity extends StatelessWidget {
  const _WeekActivity({required this.state, required this.week});

  final ViewState<List<RecentActivityModel>> state;

  /// Set only when the activities loaded.
  final _Last7Days? week;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodySm.copyWith(color: AppColors.onPrimary);
    final week = this.week;

    if (week != null) {
      if (week.total == 0) {
        return Text(
          'No points in the last 7 days. Scan a QR code to earn.',
          style: style,
        );
      }
      return _WeekChart(week: week);
    }

    if (state is ViewStateError) {
      return Text(
        "Couldn't load your recent points. Pull down to try again.",
        style: style,
      );
    }

    return const ExcludeSemantics(
      child: Shimmer(
        onDark: true,
        child: SkeletonBox(height: 64, radius: AppRadius.sm, onDark: true),
      ),
    );
  }
}

/// Seven bars, one per day, scaled to the best day. The chip and the footer
/// text carry the meaning, so the chart is hidden from screen readers.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.week});

  final _Last7Days week;

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('E');

    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _bar(
                points: week.totals[i],
                label: dayFormat.format(DateUtils.addDaysToDate(week.start, i)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar({required int points, required String label}) {
    final isPeak = week.peak > 0 && points == week.peak;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          // A day with no points gets a 4 dp stub, never a fake bar.
          height: week.peak == 0 ? 4 : math.max(4.0, 44.0 * points / week.peak),
          decoration: BoxDecoration(
            color: isPeak
                ? AppColors.onPrimary
                : AppColors.onPrimary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Scan & earn" card. Opens the Scan tab; compact below 296 dp inner width.
class _ScanAndEarnCard extends StatelessWidget {
  const _ScanAndEarnCard();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);

    // The shadow sits outside the Material: ink decorations are clipped to
    // the Material's bounds, so a shadow on the Ink itself would not show.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.find<AppAnalytics>().quickActionTapped('scan_qr');
                Get.find<ShellController>().goToTab(ShellTab.qrScan.index);
              },
              borderRadius: radius,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: radius,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -40,
                        child: _ambientCircle(size: 150, alpha: 0.08),
                      ),
                      Positioned(
                        right: 45,
                        top: -30,
                        child: _ambientCircle(size: 100, alpha: 0.05),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: LayoutBuilder(
                          builder: (context, c) =>
                              _content(compact: c.maxWidth < 296),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ambientCircle({required double size, required double alpha}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.onPrimary.withValues(alpha: alpha),
      ),
    );
  }

  Widget _content({required bool compact}) {
    final badgeSize = compact ? 48.0 : 64.0;
    final arrowSize = compact ? 36.0 : 44.0;

    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(
                compact ? AppRadius.md : AppRadius.lg,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
              size: compact ? 24 : 32,
            ),
          ),
        ),
        SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan & earn',
                maxLines: 2,
                style: AppTextStyles.titleLg.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Scan a QR code to earn points.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ExcludeSemantics(
          child: Container(
            width: arrowSize,
            height: arrowSize,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: compact ? 22 : 26,
            ),
          ),
        ),
      ],
    );
  }
}

/// Redeem | Catalogue | Wallet. Three-up while "Catalogue" fits its column,
/// otherwise stacked full-width rows.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.points, required this.isSubmitting});

  /// null while the profile hasn't loaded.
  final int? points;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final wallet = Get.find<WalletController>();
    final analytics = Get.find<AppAnalytics>();
    final shell = Get.find<ShellController>();
    final points = this.points;

    Future<void> redeem() async {
      analytics.quickActionTapped('redeem');
      if (!canRedeem(points)) return;
      final confirmed = await confirmRedemption(context, points: points!);
      if (confirmed) await wallet.raiseRequest();
    }

    final radius = BorderRadius.circular(AppRadius.xl);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) {
            final itemTextWidth = c.maxWidth / 3 - 2 * AppSpacing.sm;
            // Measure the longest unbreakable title instead of estimating.
            final painter = TextPainter(
              text: TextSpan(text: 'Catalogue', style: AppTextStyles.listTitle),
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            final stacked = painter.width > itemTextWidth;
            painter.dispose();

            final items = [
              _QuickActionItem(
                icon: Icons.redeem_rounded,
                tone: AppIconBadgeTone.gold,
                title: 'Redeem',
                subtitle:
                    points == 0 ? 'No points yet' : 'Get money for points',
                onTap: canRedeem(points) ? redeem : null,
                isBusy: isSubmitting,
                stacked: stacked,
              ),
              _QuickActionItem(
                icon: Icons.menu_book_rounded,
                tone: AppIconBadgeTone.primary,
                title: 'Catalogue',
                subtitle: 'Browse products',
                onTap: () {
                  analytics.quickActionTapped('catalogue');
                  shell.goToTab(ShellTab.catalogue.index);
                },
                stacked: stacked,
              ),
              _QuickActionItem(
                icon: Icons.account_balance_wallet_rounded,
                tone: AppIconBadgeTone.primary,
                title: 'Wallet',
                subtitle: 'Points and history',
                onTap: () {
                  analytics.quickActionTapped('my_wallet');
                  shell.goToTab(ShellTab.wallet.index);
                },
                stacked: stacked,
              ),
            ];

            if (stacked) return Column(children: items);
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final item in items) Expanded(child: item)],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.stacked,
    this.isBusy = false,
  });

  final IconData icon;
  final AppIconBadgeTone tone;
  final String title;
  final String subtitle;

  /// null → disabled (neutral badge, no ripple).
  final VoidCallback? onTap;

  /// Shows a spinner in the badge and ignores taps.
  final bool isBusy;

  /// Full-width row instead of a centred column.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null && !isBusy;
    final disabled = onTap == null && !isBusy;
    final align = stacked ? TextAlign.start : TextAlign.center;

    final badge = AppIconBadge(
      icon: icon,
      tone: disabled ? AppIconBadgeTone.neutral : tone,
      isLoading: isBusy,
    );
    final titleText = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: AppTextStyles.listTitle.copyWith(
        color: disabled ? AppColors.onSurfaceVariant : AppColors.onSurface,
      ),
    );
    final subtitleText = Text(
      subtitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
    );

    final Widget content = stacked
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                badge,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      titleText,
                      const SizedBox(height: 2),
                      subtitleText,
                    ],
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                badge,
                const SizedBox(height: AppSpacing.md),
                titleText,
                const SizedBox(height: 2),
                subtitleText,
              ],
            ),
          );

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: interactive,
        child: InkWell(onTap: interactive ? onTap : null, child: content),
      ),
    );
  }
}

/// Optional promo banners section if remote config contains items.
class _HomePromoBannerSection extends StatelessWidget {
  const _HomePromoBannerSection();

  Widget _buildBannerWidget(BannerModel b) {
    if (b.variant == 'image' && b.imageUrl != null && b.imageUrl!.isNotEmpty) {
      return AppBanner.image(
        imageUrl: b.imageUrl!,
        isNetwork: b.imageUrl!.startsWith('http'),
        title: b.title.isNotEmpty ? b.title : null,
        subtitle: b.subtitle.isNotEmpty ? b.subtitle : null,
        badgeText: b.badgeText,
      );
    } else if (b.variant == 'split') {
      return AppBanner.split(
        title: b.title,
        subtitle: b.subtitle,
        badgeText: b.badgeText,
        style: b.bannerStyle,
        graphic: Icon(
          b.iconData,
          size: 38,
          color: switch (b.bannerStyle) {
            AppBannerStyle.primary => AppColors.onPrimary,
            AppBannerStyle.dark => AppColors.inversePrimary,
            AppBannerStyle.gold => AppColors.tertiaryStrong,
            AppBannerStyle.success => AppColors.success,
            AppBannerStyle.subtle => AppColors.primary,
          },
        ),
      );
    }

    return AppBanner.text(
      title: b.title,
      subtitle: b.subtitle,
      badgeText: b.badgeText,
      icon: b.iconName != null ? b.iconData : null,
      style: b.bannerStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = Get.isRegistered<RemoteConfigService>()
        ? Get.find<RemoteConfigService>()
        : null;
    final banners = remoteConfig?.promotionalBanners ?? const <BannerModel>[];
    if (banners.isEmpty) return const SizedBox.shrink();

    return AppBannerCarousel(
      autoPlay: true,
      banners: [for (final b in banners) _buildBannerWidget(b)],
    );
  }
}

/// One step of the "How to earn points" guide.
class _EarnStep {
  const _EarnStep({
    required this.number,
    required this.icon,
    required this.color,
    required this.ring,
    required this.title,
    required this.subtitle,
  });

  final int number;
  final IconData icon;

  /// Icon, number badge and shadow tint.
  final Color color;

  /// The icon circle's 2 px ring.
  final Color ring;
  final String title;
  final String subtitle;
}

/// "How to earn points" 3-step guide. Three-up at normal text sizes, a
/// vertical list at large text.
class _HowToEarnPointsCard extends StatelessWidget {
  const _HowToEarnPointsCard();

  static const _steps = <_EarnStep>[
    _EarnStep(
      number: 1,
      icon: Icons.qr_code_2_rounded,
      color: AppColors.success,
      ring: AppColors.successContainer,
      title: 'Find the QR code',
      subtitle: 'Look for a square code',
    ),
    _EarnStep(
      number: 2,
      icon: Icons.crop_free_rounded,
      color: AppColors.primary,
      ring: AppColors.primaryFixed,
      title: 'Scan it',
      subtitle: 'Tap Scan below',
    ),
    _EarnStep(
      number: 3,
      icon: Icons.stars_rounded,
      color: AppColors.tertiaryStrong,
      ring: AppColors.tertiaryFixed,
      title: 'Get points',
      subtitle: 'Added to your wallet',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.tertiarySurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        // Decorative edge only.
        border: Border.all(color: AppColors.tertiaryFixed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'How to earn points',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.tertiaryStrong,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLargeText(context))
            _stackedSteps(context)
          else
            _threeUpSteps(context),
        ],
      ),
    );
  }

  Widget _threeUpSteps(BuildContext context) {
    const chevron = Padding(
      padding: EdgeInsets.only(top: AppSpacing.lg),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.tertiaryStrong,
      ),
    );
    // Grows with the text instead of clipping; keeps the titles aligned.
    final titleMinHeight = MediaQuery.textScalerOf(context).scale(12) * 1.2 * 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0) chevron,
          Expanded(
            child: MergeSemantics(
              child: Column(
                children: [
                  _iconCircle(_steps[i], size: 52, iconSize: 26),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: titleMinHeight),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _numberBadge(context, _steps[i], stacked: false),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: _title(_steps[i], TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _subtitle(_steps[i], TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stackedSteps(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          MergeSemantics(
            child: Row(
              children: [
                _iconCircle(_steps[i], size: 40, iconSize: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _numberBadge(context, _steps[i], stacked: true),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(child: _title(_steps[i], TextAlign.start)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      _subtitle(_steps[i], TextAlign.start),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _iconCircle(
    _EarnStep step, {
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: step.ring, width: 2),
        boxShadow: [
          BoxShadow(
            color: step.color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(step.icon, size: iconSize, color: step.color),
    );
  }

  /// Filled circle with the step number: 18×18 in the three-up layout
  /// (at most 1.3× text, where the digit still fits). In the stacked
  /// large-text layout it grows with the text so the digit is never clipped.
  Widget _numberBadge(
    BuildContext context,
    _EarnStep step, {
    required bool stacked,
  }) {
    final size = stacked
        ? math.max(18.0, MediaQuery.textScalerOf(context).scale(18))
        : 18.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: step.color, shape: BoxShape.circle),
      child: Text(
        '${step.number}',
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _title(_EarnStep step, TextAlign align) {
    return Text(
      step.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: AppTextStyles.labelMd.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }

  Widget _subtitle(_EarnStep step, TextAlign align) {
    return Text(
      step.subtitle,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
    );
  }
}
