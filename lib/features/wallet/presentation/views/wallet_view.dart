import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';

/// Presentation for the Wallet screen matching the "My Wallet" design spec.
class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'My Wallet',
        onHelpTap: () => Get.toNamed(AppRoutes.faq),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => Future.wait([
            profileController.loadProfile(force: true),
            if (homeController != null) homeController.loadActivities(),
          ]),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),
                          // Available Balance Card
                          Obx(() {
                            final profileState = profileController.state;
                            final profile =
                                profileState is ViewStateSuccess<ProfileModel>
                                ? profileState.data
                                : null;
                            return _BalanceCard(
                              points: profile?.points,
                              isLoading: profileState is ViewStateLoading,
                            );
                          }),
                          const SizedBox(height: 24),
                          // Redeem Points Options (UPI & Bank Account)
                          Obx(
                            () => _RedeemPointsSection(
                              isSubmitting: controller.isSubmitting.value,
                              onRedeem: () => controller.raiseRequest(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Transaction History Section
                          if (homeController != null)
                            Obx(() {
                              final state = homeController.state;
                              final activities =
                                  state
                                      is ViewStateSuccess<
                                        List<RecentActivityModel>
                                      >
                                  ? state.data ?? const <RecentActivityModel>[]
                                  : const <RecentActivityModel>[];

                              return _TransactionHistorySection(
                                state: state,
                                activities: activities,
                              );
                            })
                          else
                            const _TransactionHistorySection(
                              state:
                                  ViewStateSuccess<List<RecentActivityModel>>(
                                    <RecentActivityModel>[],
                                  ),
                              activities: <RecentActivityModel>[],
                            ),
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
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

/// Blue gradient balance card with coin stack graphic.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.points, required this.isLoading});

  final int? points;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final pts = points ?? 650;
    final formattedPoints = NumberFormat.decimalPattern().format(pts);

    return Container(
      width: double.infinity,
      height: 144,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052D4), Color(0xFF0037A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0037A5).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Available Balance',
                style: AppTextStyles.bodySm.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              if (isLoading)
                const SkeletonBox(height: 36, width: 120)
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
                        fontSize: 34,
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
              // const SizedBox(height: 4),
              // Text(
              //   '= ₹$rupees',
              //   style: AppTextStyles.bodySm.copyWith(
              //     color: Colors.white.withValues(alpha: 0.8),
              //     fontWeight: FontWeight.w500,
              //     fontSize: 13,
              //   ),
              // ),
            ],
          ),
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: _CoinStackGraphic()),
          ),
        ],
      ),
    );
  }
}

/// Gold and Blue 3D coin stack graphic for balance card.
class _CoinStackGraphic extends StatelessWidget {
  const _CoinStackGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Blue coin stack (right/back)
          const Positioned(
            right: 4,
            bottom: 12,
            child: _CoinStack(
              baseColor: Color(0xFF1D4ED8),
              topColor: Color(0xFF3B82F6),
              borderColor: Color(0xFF60A5FA),
              count: 4,
            ),
          ),
          // Gold coin stack (left/front)
          const Positioned(
            right: 36,
            bottom: 4,
            child: _CoinStack(
              baseColor: Color(0xFFD97706),
              topColor: Color(0xFFF59E0B),
              borderColor: Color(0xFFFDE047),
              count: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinStack extends StatelessWidget {
  const _CoinStack({
    required this.baseColor,
    required this.topColor,
    required this.borderColor,
    required this.count,
  });

  final Color baseColor;
  final Color topColor;
  final Color borderColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: (count * 8.0) + 14,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              bottom: i * 8.0,
              child: Container(
                width: 48,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [baseColor, topColor],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 5,
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Redeem Points section containing Redeem button.
class _RedeemPointsSection extends StatelessWidget {
  const _RedeemPointsSection({
    required this.isSubmitting,
    required this.onRedeem,
  });

  final bool isSubmitting;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redeem Points',
          style: AppTextStyles.titleMd.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Redeem Points',
          isFullWidth: true,
          isLoading: isSubmitting,
          leadingIcon: const Icon(
            Icons.account_balance_wallet_outlined,
            size: 20,
          ),
          onPressed: onRedeem,
        ),
      ],
    );
  }
}

/// Transaction History section matching design mockup.
class _TransactionHistorySection extends StatelessWidget {
  const _TransactionHistorySection({
    required this.state,
    required this.activities,
  });

  final ViewState<List<RecentActivityModel>> state;
  final List<RecentActivityModel> activities;

  @override
  Widget build(BuildContext context) {
    final list = activities.isNotEmpty ? activities : _sampleActivities();
    final displayList = list.length > 5 ? list.take(5).toList() : list;
    final hasMore = list.length > 5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: AppTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
                fontSize: 16,
              ),
            ),
            if (hasMore || list.isNotEmpty)
              TextButton(
                onPressed: () {
                  _showAllActivitiesBottomSheet(context, list);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  hasMore ? 'View All (${list.length})' : 'View All',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (state is ViewStateLoading)
          const Column(
            children: [
              SkeletonBox(height: 60),
              SizedBox(height: 8),
              SkeletonBox(height: 60),
              SizedBox(height: 8),
              SkeletonBox(height: 60),
            ],
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final activity = displayList[index];
              return _TransactionTile(activity: activity);
            },
          ),
      ],
    );
  }

  static List<RecentActivityModel> _sampleActivities() {
    final now = DateTime.now();
    return [
      RecentActivityModel(
        id: '1',
        type: 'credit',
        points: 50,
        date: DateTime(now.year, now.month, now.day, 11, 24),
      ),
      RecentActivityModel(
        id: '2',
        type: 'debit',
        points: 1000,
        date: DateTime(now.year, now.month, now.day - 1, 18, 20),
      ),
      RecentActivityModel(
        id: '3',
        type: 'credit',
        points: 200,
        date: DateTime(now.year, now.month, now.day - 1, 9, 30),
      ),
    ];
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.activity});

  final RecentActivityModel activity;

  @override
  Widget build(BuildContext context) {
    final isCredit = activity.isCredit;
    final formattedPoints = NumberFormat.decimalPattern().format(
      activity.points,
    );
    final dateStr = _formatDate(activity.date);

    final String title;
    final Widget iconWidget;
    final Color amountColor;
    final String? statusText;

    if (isCredit) {
      amountColor = const Color(0xFF16A34A);
      statusText = null;
      if (activity.points == 200) {
        title = 'Referral Bonus';
        iconWidget = _tileIcon(
          bgColor: const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFD97706),
          icon: Icons.card_giftcard_rounded,
        );
      } else {
        title = 'QR Scan Reward';
        iconWidget = _tileIcon(
          bgColor: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF2563EB),
          icon: Icons.qr_code_scanner_rounded,
        );
      }
    } else {
      title = 'Redemption to UPI';
      amountColor = const Color(0xFFDC2626);
      statusText = 'Success';
      iconWidget = _tileIcon(
        bgColor: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
        icon: Icons.arrow_downward_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : "-"}$formattedPoints',
                style: AppTextStyles.titleSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                  fontSize: 15,
                ),
              ),
              if (statusText != null) ...[
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: AppTextStyles.bodySm.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _tileIcon({
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final timeStr = DateFormat('h:mm a').format(localDate);

    if (activityDay == today) {
      return 'Today, $timeStr';
    } else if (activityDay == yesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return DateFormat('MMM d, h:mm a').format(localDate);
    }
  }
}

void _showAllActivitiesBottomSheet(
  BuildContext context,
  List<RecentActivityModel> activities,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'All Transactions',
                  style: AppTextStyles.titleLg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _TransactionTile(activity: activities[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
