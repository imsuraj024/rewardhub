import 'package:flutter/material.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_header.dart';

/// Shared shell for the multi-step registration screens.
///
/// Renders the branded gradient background, header, a step progress indicator
/// and the white form card, so each step only supplies its own fields.
///
/// Set [canPop] to false to block system back (e.g. while uploading);
/// [onPopBlocked] then runs on each blocked attempt.
class RegisterStepScaffold extends StatelessWidget {
  const RegisterStepScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    this.canPop = true,
    this.onPopBlocked,
  });

  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final bool canPop;
  final VoidCallback? onPopBlocked;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onPopBlocked?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.authBackgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.authGutter,
                      vertical: AppSpacing.xxxl,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        const AuthHeader(
                          title: AppStrings.productName,
                          subtitle: 'Scan, earn, and redeem rewards every day.',
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _StepIndicator(
                          currentStep: currentStep,
                          totalSteps: totalSteps,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _StepTransition(
                          // Re-run the entrance animation whenever the step changes.
                          key: ValueKey(currentStep),
                          child: AuthFormCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: AppTextStyles.headlineSm),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Fades and slides its child up on first build — used to animate each
/// registration step as it appears.
class _StepTransition extends StatefulWidget {
  const _StepTransition({super.key, required this.child});

  final Widget child;

  @override
  State<_StepTransition> createState() => _StepTransitionState();
}

class _StepTransitionState extends State<_StepTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Numbered circles with connectors showing progress through registration.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 1; i <= totalSteps; i++) ...[
              _StepNode(
                index: i,
                completed: i < currentStep,
                active: i == currentStep,
              ),
              if (i < totalSteps)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: i < currentStep
                          ? AppColors.primary
                          : AppColors.outlineVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Step $currentStep of $totalSteps',
            style: AppTextStyles.overline,
          ),
        ),
      ],
    );
  }
}

/// A single circular step marker: a check when completed, its number otherwise.
class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.completed,
    required this.active,
  });

  final int index;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final filled = completed || active;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : AppColors.surfaceContainerHighest,
        border: active
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 3,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: completed
          ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.onPrimary,
            )
          : Text(
              '$index',
              style: AppTextStyles.labelMd.copyWith(
                color:
                    filled ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
