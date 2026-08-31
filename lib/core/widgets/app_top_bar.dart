import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared app bar used across all main screens.
///
/// Implements [PreferredSizeWidget] so it works as both:
/// - `appBar:` in a [Scaffold]
/// - wrapped in [SliverToBoxAdapter] for sliver-based screens
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title = AppStrings.productName,
    this.showBackButton = true,
    this.onBackTap,
    this.showLogo = false,
    this.showDivider = true,
    this.centerTitle = true,
    this.actions,
    this.onHelpTap,
    this.onNotificationTap,
    this.leading,
    this.backgroundColor,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final bool showLogo;
  final bool showDivider;
  final bool centerTitle;
  final List<Widget>? actions;
  final VoidCallback? onHelpTap;
  final VoidCallback? onNotificationTap;
  final Widget? leading;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final bool displayBackButton =
        showBackButton && (canPop || onBackTap != null);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && displayBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.onSurface,
          size: 22,
        ),
        onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
      );
    }

    final List<Widget> actionWidgets = [];
    if (actions != null) {
      actionWidgets.addAll(actions!);
    } else {
      if (onHelpTap != null) {
        actionWidgets.add(
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.onSurface,
              size: 22,
            ),
            onPressed: onHelpTap,
            tooltip: 'Help',
          ),
        );
      }
      if (onNotificationTap != null) {
        actionWidgets.add(
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.onSurface,
              size: 22,
            ),
            onPressed: onNotificationTap,
            tooltip: 'Notifications',
          ),
        );
      }
    }

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo && !displayBackButton) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: actionWidgets.isNotEmpty ? actionWidgets : null,
      bottom: showDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
                height: 0.5,
              ),
            )
          : null,
    );
  }
}
