import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_format.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/core/widgets/app_state_message.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';
import 'package:rewardhub/core/widgets/points_balance_card.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:rewardhub/features/wallet/presentation/widgets/redeem_confirmation.dart';

/// The Wallet tab: points balance, redeem, and transaction history.
class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final homeController =
        Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'Wallet',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageGutter,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: AppSpacing.lg),
                          Obx(() {
                            final s = profileController.state;
                            final profile = s is ViewStateSuccess<ProfileModel>
                                ? s.data
                                : null;
                            return PointsBalanceCard(
                              label: 'Available points',
                              points: profile?.points,
                              isLoading: s is ViewStateLoading ||
                                  s is ViewStateInitial,
                              onRetry: () =>
                                  profileController.loadProfile(force: true),
                              graphic: const _CoinStackGraphic(),
                            );
                          }),
                          const SizedBox(height: AppSpacing.xxl),
                          Obx(() {
                            final s = profileController.state;
                            final points = s is ViewStateSuccess<ProfileModel>
                                ? s.data?.points
                                : null;
                            return _RedeemPointsSection(
                              points: points,
                              isSubmitting: controller.isSubmitting.value,
                              onRedeem: () async {
                                if (!canRedeem(points)) return;
                                final confirmed = await confirmRedemption(
                                  context,
                                  points: points!,
                                );
                                if (confirmed) await controller.raiseRequest();
                              },
                            );
                          }),
                          const SizedBox(height: AppSpacing.xxl),
                          // Without a HomeController there's no data source,
                          // so the section isn't shown at all.
                          if (homeController != null)
                            Obx(
                              () => _TransactionHistorySection(
                                state: homeController.state,
                                onRetry: homeController.loadActivities,
                                onScan: () => Get.find<ShellController>()
                                    .goToTab(ShellTab.qrScan.index),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xxl),
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

/// Gold and blue coin stacks for the balance card. Scales into the card's
/// graphic slot.
class _CoinStackGraphic extends StatelessWidget {
  const _CoinStackGraphic();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 100,
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Blue coin stack (right/back)
            Positioned(
              right: 4,
              bottom: 12,
              child: _CoinStack(
                baseColor: AppColors.inversePrimary,
                topColor: AppColors.primaryFixed,
                borderColor: AppColors.onPrimary,
                count: 4,
              ),
            ),
            // Gold coin stack (left/front)
            Positioned(
              right: 36,
              bottom: 4,
              child: _CoinStack(
                baseColor: AppColors.tertiaryStrong,
                topColor: AppColors.tertiary,
                borderColor: AppColors.tertiaryFixed,
                count: 5,
              ),
            ),
          ],
        ),
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
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.15),
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
                      borderRadius: BorderRadius.circular(AppRadius.xs),
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

/// "Redeem points": a helper line and the Redeem button. The button is
/// disabled until the balance has loaded and is above zero.
class _RedeemPointsSection extends StatelessWidget {
  const _RedeemPointsSection({
    required this.points,
    required this.isSubmitting,
    required this.onRedeem,
  });

  /// null while the profile hasn't loaded.
  final int? points;
  final bool isSubmitting;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Redeem points', style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          points == 0
              ? 'You have no points to redeem yet. Scan a QR code to earn some.'
              : 'Turn your points into money. '
                  'It goes to your saved payment details.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Redeem points',
          isFullWidth: true,
          isLoading: isSubmitting,
          leadingIcon: const Icon(Icons.redeem_rounded),
          onPressed: canRedeem(points) ? onRedeem : null,
        ),
      ],
    );
  }
}

/// "Transaction history": the latest 5 transactions, or a loading, empty or
/// error state. Never shows sample rows.
class _TransactionHistorySection extends StatelessWidget {
  const _TransactionHistorySection({
    required this.state,
    required this.onRetry,
    required this.onScan,
  });

  final ViewState<List<RecentActivityModel>> state;
  final VoidCallback onRetry;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final items = state is ViewStateSuccess<List<RecentActivityModel>>
        ? (state.data ?? const <RecentActivityModel>[])
        : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Transaction history',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ),
            if (items != null && items.length > 5)
              TextButton(
                onPressed: () => _showAllTransactions(context, items),
                child: Text(
                  'View all (${items.length})',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _body(state, items),
      ],
    );
  }

  Widget _body(
    ViewState<List<RecentActivityModel>> state,
    List<RecentActivityModel>? items,
  ) {
    if (state is ViewStateError<List<RecentActivityModel>>) {
      return AppStateMessage(
        icon: Icons.cloud_off_rounded,
        tone: AppIconBadgeTone.error,
        title: "Couldn't load your transactions",
        message: state.message,
        actionLabel: 'Try again',
        onAction: onRetry,
      );
    }

    if (items == null) {
      return Semantics(
        label: 'Loading transactions',
        child: const Shimmer(
          child: Column(
            children: [
              SkeletonBox(height: 64, radius: AppRadius.lg),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 64, radius: AppRadius.lg),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 64, radius: AppRadius.lg),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return AppStateMessage(
        icon: Icons.receipt_long_rounded,
        title: 'No transactions yet',
        message: 'Scan a QR code to earn your first points.',
        actionLabel: 'Scan QR code',
        onAction: onScan,
      );
    }

    final shown = items.take(5).toList();
    return Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _TransactionTile(activity: shown[i]),
        ],
      ],
    );
  }
}

/// One transaction, read as a single node. Only the type, points and date
/// come from the API, so nothing else (source, method, status) is shown.
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.activity});

  final RecentActivityModel activity;

  @override
  Widget build(BuildContext context) {
    final points = activity.points;
    final (icon, tone, title, amount, amountColour) = activity.isCredit
        ? (
            Icons.add_rounded,
            AppIconBadgeTone.success,
            'Points earned',
            AppFormat.signedPoints(points, isCredit: true),
            AppColors.success,
          )
        : activity.isDebit
            ? (
                Icons.redeem_rounded,
                AppIconBadgeTone.primary,
                'Points redeemed',
                AppFormat.signedPoints(points, isCredit: false),
                AppColors.onSurface,
              )
            : (
                Icons.swap_vert_rounded,
                AppIconBadgeTone.neutral,
                'Points',
                AppFormat.pointsWithUnit(points),
                AppColors.onSurface,
              );
    final date = _formatDate(activity.date);

    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          // Decorative card edge.
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (context, c) => Row(
            children: [
              AppIconBadge(icon: icon, tone: tone),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.listTitle.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        date,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: c.maxWidth * 0.45),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amount,
                    maxLines: 1,
                    style: AppTextStyles.amount.copyWith(color: amountColour),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Today, 3:15 PM", "Yesterday, 3:15 PM" or "27 Sep, 3:15 PM". null for
  /// the model's 1970 fallback (an unparseable date), so no date is invented.
  static String? _formatDate(DateTime date) {
    if (date.year <= 1970) return null;

    final local = date.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final time = DateFormat('h:mm a').format(local);

    if (DateUtils.isSameDay(local, today)) return 'Today, $time';
    if (DateUtils.isSameDay(local, DateUtils.addDaysToDate(today, -1))) {
      return 'Yesterday, $time';
    }
    return AppFormat.dateTime(date);
  }
}

/// Lists every transaction in the app's list sheet.
void _showAllTransactions(
  BuildContext context,
  List<RecentActivityModel> items,
) {
  AppBottomSheet.show<void>(
    context: context,
    builder: (_) => AppBottomSheet.list(
      title: 'Transaction history',
      itemCount: items.length,
      itemBuilder: (_, i) => _TransactionTile(activity: items[i]),
    ),
  );
}
