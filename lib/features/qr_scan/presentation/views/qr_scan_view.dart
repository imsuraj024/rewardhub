import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_format.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/qr_scan/presentation/controllers/qr_scan_controller.dart';
import 'package:rewardhub/features/qr_scan/presentation/widgets/scanner_overlay_shape.dart';

/// Side of the square scan window for a camera area of [c]: up to 220 dp,
/// never under 96 dp, with room for the brackets on small screens. The scrim
/// cutout, the brackets and the laser all use this one value.
@visibleForTesting
double scanWindowSize(BoxConstraints c) => math
    .min(220.0, math.min(c.maxWidth - 64, c.maxHeight - 32))
    .clamp(96.0, 220.0)
    .toDouble();

class QrScanView extends GetView<QrScanController> {
  const QrScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Scan & earn'),
      body: Stack(
        children: [
          // The camera takes whatever the info panel leaves; the panel
          // shrink-wraps up to 45% of the body and scrolls beyond that.
          LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: AppColors.onSurface,
                    child: Obx(
                      () => _buildCameraArea(controller.cameraStatus.value),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.45,
                  ),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageGutter,
                      vertical: AppSpacing.md,
                    ),
                    child: _InfoCard(),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (!controller.isSubmitting.value) return const SizedBox.shrink();
            return const _SubmittingOverlay();
          }),
        ],
      ),
    );
  }

  Widget _buildCameraArea(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted || PermissionStatus.limited => _scanner(),
      PermissionStatus.denied ||
      PermissionStatus.provisional =>
        _CameraPermissionPanel(
          blocked: false,
          onPressed: controller.requestCameraPermission,
        ),
      PermissionStatus.permanentlyDenied ||
      PermissionStatus.restricted =>
        const _CameraPermissionPanel(
          blocked: true,
          onPressed: openAppSettings,
        ),
    };
  }

  Widget _scanner() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final windowSize = scanWindowSize(c);
              return ExcludeSemantics(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: controller.scannerController,
                      onDetect: controller.onDetect,
                    ),
                    // Dims everything outside the scan window.
                    CustomPaint(painter: ScannerScrim(windowSize: windowSize)),
                    // Corner brackets, centred on the scrim cutout.
                    Center(
                      child: SizedBox.square(
                        dimension: windowSize,
                        child: CustomPaint(painter: ScannerOverlayShape()),
                      ),
                    ),
                    _AnimatedLaserLine(boxSize: windowSize),
                  ],
                ),
              );
            },
          ),
        ),
        // Its own strip under the preview, so it can't be clipped or cover
        // the window.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.lg,
          ),
          child: Text(
            'Fit the QR code inside the frame',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      ],
    );
  }
}

/// Blocks the screen while a scanned code is being checked.
class _SubmittingOverlay extends StatelessWidget {
  const _SubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scrim,
      child: Center(
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Checking code…',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMd,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Please wait while we check this code.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
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

/// Decorative laser line that sweeps vertically inside the scan window.
/// Holds still at the centre when the system asks for reduced motion.
class _AnimatedLaserLine extends StatefulWidget {
  const _AnimatedLaserLine({required this.boxSize});

  final double boxSize;

  @override
  State<_AnimatedLaserLine> createState() => _AnimatedLaserLineState();
}

class _AnimatedLaserLineState extends State<_AnimatedLaserLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final halfHeight = widget.boxSize / 2 - 10;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offsetY = -halfHeight + (_animation.value * (halfHeight * 2));
        return Center(
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          ),
        );
      },
      child: Container(
        height: 2.5,
        width: widget.boxSize - 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primaryContainer,
              AppColors.primary,
              AppColors.primaryContainer,
              AppColors.primary.withValues(alpha: 0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.85),
              blurRadius: 12,
              spreadRadius: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains why the camera is needed before asking ([blocked] false), or how
/// to turn it back on once the OS won't ask again ([blocked] true).
class _CameraPermissionPanel extends StatelessWidget {
  const _CameraPermissionPanel({
    required this.blocked,
    required this.onPressed,
  });

  final bool blocked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final title = blocked ? 'Camera is off' : 'Allow camera to scan';
    final body = blocked
        ? 'Tap Open settings, then turn on Camera.'
        : 'We need your camera to scan QR codes.';

    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      blocked
                          ? Icons.no_photography_rounded
                          : Icons.photo_camera_rounded,
                      size: 48,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: blocked ? 'Open settings' : 'Allow camera',
                    variant: AppButtonVariant.inverted,
                    onPressed: onPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIconBadge(icon: Icons.info_outline_rounded),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'How scanning works',
                        style: AppTextStyles.titleMd,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Point your camera at a QR code. If the code is valid, '
                      'we add the points to your wallet.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (Get.isRegistered<ProfileController>()) ...[
            const SizedBox(height: AppSpacing.lg),
            Obx(() => _PointsRow(state: Get.find<ProfileController>().state)),
          ],
        ],
      ),
    );
  }
}

/// "Your points" band in the info card: the balance, a skeleton while it
/// loads, or "—" when it couldn't load.
class _PointsRow extends StatelessWidget {
  const _PointsRow({required this.state});

  final ViewState<ProfileModel> state;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final profile = state is ViewStateSuccess<ProfileModel> ? state.data : null;

    final Widget value;
    if (profile != null) {
      value = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          AppFormat.pointsWithUnit(profile.points),
          style: AppTextStyles.titleMd.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (state is ViewStateLoading || state is ViewStateInitial) {
      value = Semantics(
        label: 'Loading',
        child: const Shimmer(child: SkeletonBox(width: 96, height: 20)),
      );
    } else {
      value = Text(
        '—',
        semanticsLabel: 'Not available',
        style: AppTextStyles.titleMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      );
    }

    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const AppIconBadge(
              icon: Icons.stars_rounded,
              tone: AppIconBadgeTone.gold,
              size: AppIconBadgeSize.sm,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your points',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  value,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
