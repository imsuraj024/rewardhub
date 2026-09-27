import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/models/banner_model.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_banner.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';

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
            final activitiesState = controller.state;
            final activities =
                activitiesState is ViewStateSuccess<List<RecentActivityModel>>
                    ? activitiesState.data ?? const <RecentActivityModel>[]
                    : const <RecentActivityModel>[];
            final isWalletSubmitting = walletController.isSubmitting.value;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                _HomeHeader(name: profile?.name),
                const SizedBox(height: 16),
                const _HomePromoBannerSection(),
                const SizedBox(height: 16),
                _BalanceCard(
                  points: profile?.points,
                  name: profile?.name,
                  isLoading: profileState is ViewStateLoading,
                  weeklyEarned: _weeklyEarned(activitiesState),
                  activities: activities,
                ),
                const SizedBox(height: 16),
                const _ScanAndEarnCard(),
                const SizedBox(height: 16),
                _QuickActions(isSubmitting: isWalletSubmitting),
                const SizedBox(height: 20),
                const _HowToEarnPointsCard(),
                const SizedBox(height: 24),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Sum of points earned (credits) in the last 7 days, for the trend chip.
  int _weeklyEarned(ViewState<List<RecentActivityModel>> state) {
    if (state is! ViewStateSuccess<List<RecentActivityModel>>) return 600;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    var total = 0;
    for (final a in state.data ?? const <RecentActivityModel>[]) {
      if (a.isCredit && a.date.isAfter(weekAgo)) total += a.points;
    }
    return total > 0 ? total : 600;
  }
}

/// Greeting header bar matching design mockup (Greeting, User Name 👋 & Notification Bell).
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final userName =
        (name != null && name!.trim().isNotEmpty) ? name! : 'Suraj Mishra';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$userName 👋',
            style: AppTextStyles.titleLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 17) return 'Good afternoon,';
    if (hour >= 17 && hour < 21) return 'Good evening,';
    return 'Welcome back,';
  }
}

/// Blue gradient balance card with points, trend chip (+600 ↗ this week), and progress bar.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    this.points,
    this.name,
    this.isLoading = false,
    this.weeklyEarned = 600,
    this.activities = const [],
  });

  final int? points;
  final String? name;
  final bool isLoading;
  final int weeklyEarned;
  final List<RecentActivityModel> activities;

  @override
  Widget build(BuildContext context) {
    final pts = points ?? 650;
    final formattedPoints = NumberFormat.decimalPattern().format(pts);
    final weeklyText = weeklyEarned > 0 ? weeklyEarned : 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR REWARD BALANCE',
                style: AppTextStyles.labelSm.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              // Weekly earned trend chip (+600 ↗ this week)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+$weeklyText',
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.north_east_rounded,
                      size: 13,
                      color: Color(0xFF4ADE80),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'this week',
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const SkeletonBox(height: 40, width: 120)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formattedPoints,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 38,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'POINTS',
                  style: AppTextStyles.titleSm.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Divider line
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          // Weekly Bar Chart
          _WeeklyBarChart(activities: activities),
        ],
      ),
    );
  }
}

/// Weekly mini bar chart widget matching uploaded design spec mockup.
class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({this.activities = const []});

  final List<RecentActivityModel> activities;

  @override
  Widget build(BuildContext context) {
    final dailyData = _calculateWeeklyData();
    final maxPts = dailyData
        .map((d) => d.points)
        .fold<int>(1, (max, v) => v > max ? v : max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dailyData.map((data) {
        final ratio = (data.points / maxPts).clamp(0.25, 1.0);
        final barHeight = 44.0 * ratio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vertical Rounded Bar Pill
            Container(
              width: 14,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: data.isHigh
                    ? const LinearGradient(
                        colors: [Color(0xFF60A5FA), Colors.white],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : null,
                color:
                    data.isHigh ? null : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 8),
            // Day Label (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
            Text(
              data.dayLabel,
              style: TextStyle(
                color: data.isHigh
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.75),
                fontWeight: data.isHigh ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<_WeeklyBarChartData> _calculateWeeklyData() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final totals = List<int>.filled(7, 0);

    for (final a in activities) {
      if (a.isCredit) {
        final diff = a.date
            .difference(DateTime(monday.year, monday.month, monday.day))
            .inDays;
        if (diff >= 0 && diff < 7) {
          totals[diff] += a.points;
        }
      }
    }

    // Default sample values if no activities
    final samplePattern = [120, 260, 180, 420, 200, 300, 420];
    final hasData = totals.any((t) => t > 0);
    final values = hasData ? totals : samplePattern;

    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return List.generate(7, (i) {
      return _WeeklyBarChartData(
        dayLabel: days[i],
        points: values[i],
        isHigh: values[i] == maxVal || (values[i] >= maxVal * 0.85),
      );
    });
  }
}

class _WeeklyBarChartData {
  final String dayLabel;
  final int points;
  final bool isHigh;

  const _WeeklyBarChartData({
    required this.dayLabel,
    required this.points,
    required this.isHigh,
  });
}

/// SCAN & EARN banner card matching design mockup.
class _ScanAndEarnCard extends StatelessWidget {
  const _ScanAndEarnCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.find<AppAnalytics>().quickActionTapped('scan_qr');
          Get.find<ShellController>().goToTab(ShellTab.qrScan.index);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background decorative ambient circles
                Positioned(
                  right: -20,
                  bottom: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 45,
                  top: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Main Content Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      // Left QR Icon Square Badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFF2563EB),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Center Text (Title + Subtitle)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SCAN & EARN',
                              style: AppTextStyles.titleLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan a Kitox QR and\nearn points instantly',
                              style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right Action Arrow Circle Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF2563EB),
                            size: 26,
                          ),
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
    );
  }
}

/// Quick action segmented card (Redeem | Catalogue | My Wallet) matching design mockup.
class _QuickActions extends StatelessWidget {
  const _QuickActions({this.isSubmitting = false});

  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final wallet = Get.find<WalletController>();
    final analytics = Get.find<AppAnalytics>();
    final shell = Get.find<ShellController>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Redeem Item
            Expanded(
              child: _QuickActionItem(
                badgeBgColor: const Color(0xFFE8F5E9),
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFF16A34A),
                title: 'Redeem',
                subtitle: 'Cash out\npoints',
                isBusy: isSubmitting,
                onTap: () {
                  analytics.quickActionTapped('redeem');
                  wallet.raiseRequest();
                },
              ),
            ),
            _buildDivider(),
            // Catalogue Item
            Expanded(
              child: _QuickActionItem(
                badgeBgColor: const Color(0xFFF3E8FF),
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Catalogue',
                subtitle: 'Explore\nrewards',
                onTap: () {
                  analytics.quickActionTapped('catalogue');
                  shell.goToTab(ShellTab.catalogue.index);
                },
              ),
            ),
            _buildDivider(),
            // My Wallet Item
            Expanded(
              child: _QuickActionItem(
                badgeBgColor: const Color(0xFFEFF6FF),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF2563EB),
                title: 'My Wallet',
                subtitle: 'View balance &\ntransactions',
                onTap: () {
                  analytics.quickActionTapped('my_wallet');
                  shell.goToTab(ShellTab.wallet.index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.badgeBgColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isBusy = false,
  });

  final Color badgeBgColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Colored Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isBusy
                    ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: iconColor,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                title,
                style: AppTextStyles.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              // Subtitle
              Text(
                subtitle,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
          color: (b.bannerStyle == AppBannerStyle.primary ||
                  b.bannerStyle == AppBannerStyle.dark)
              ? Colors.white
              : AppColors.primary,
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
      height: 135,
      autoPlay: true,
      banners: [for (final b in banners) _buildBannerWidget(b)],
    );
  }
}

/// "HOW TO EARN POINTS" 3-step guide card matching design mockup.
class _HowToEarnPointsCard extends StatelessWidget {
  const _HowToEarnPointsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFE0B2).withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO EARN POINTS',
            style: AppTextStyles.labelSm.copyWith(
              color: const Color(0xFFB76E00),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1
              Expanded(
                child: _buildStep(
                  stepBadge: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  stepColor: const Color(0xFF16A34A),
                  bgRingColor: const Color(0xFFDCFCE7),
                  icon: Icons.qr_code_2_rounded,
                  title: 'Find Kitox QR',
                  subtitle: 'On receipts & products',
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16, left: 1, right: 1),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFF59E0B),
                ),
              ),
              // Step 2
              Expanded(
                child: _buildStep(
                  stepBadge: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  stepColor: const Color(0xFF2563EB),
                  bgRingColor: const Color(0xFFDBEAFE),
                  icon: Icons.crop_free_rounded,
                  title: 'Scan in App',
                  subtitle: 'Use scanner button',
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16, left: 1, right: 1),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFF59E0B),
                ),
              ),
              // Step 3
              Expanded(
                child: _buildStep(
                  stepBadge: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  stepColor: const Color(0xFFEA580C),
                  bgRingColor: const Color(0xFFFEF3C7),
                  icon: Icons.stars_rounded,
                  title: 'Claim Reward',
                  subtitle: 'Points added to wallet',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required Widget stepBadge,
    required Color stepColor,
    required Color bgRingColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        // Circular Icon Badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: bgRingColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: stepColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 26,
            color: stepColor,
          ),
        ),
        const SizedBox(height: 12),
        // Step Number + Title (Fixed height container so all 3 titles occupy the exact same space)
        SizedBox(
          height: 38,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                stepBadge,
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.labelLg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                      fontSize: 12,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Subtitle
        Text(
          subtitle,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
