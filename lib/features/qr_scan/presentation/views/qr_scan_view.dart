import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/qr_scan/presentation/controllers/qr_scan_controller.dart';
import 'package:rewardhub/features/qr_scan/presentation/widgets/scanner_overlay_shape.dart';

class QrScanView extends GetView<QrScanController> {
  const QrScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Scan & Earn'),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 55,
                child: Container(
                  color: const Color(0xFF191A1E),
                  child: Obx(() => _buildCameraArea(controller.cameraStatus.value)),
                ),
              ),
              Expanded(
                flex: 45,
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: const Column(children: [_InfoCard()]),
                ),
              ),
            ],
          ),
          Obx(() {
            if (!controller.isSubmitting.value) return const SizedBox.shrink();
            return Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(height: 18),
                      Text(
                        'Verifying QR Code...',
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please hold on while we claim your points.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCameraArea(PermissionStatus status) {
    if (status.isPermanentlyDenied) {
      return _PermissionDenied(permanent: true, onRequest: openAppSettings);
    }
    if (status.isDenied) {
      return _PermissionDenied(
        permanent: false,
        onRequest: controller.requestCameraPermission,
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: controller.scannerController,
          onDetect: controller.onDetect,
        ),
        // Dim everything outside the 220px scan window.
        Positioned.fill(
          child: CustomPaint(painter: ScannerScrim(windowSize: 220)),
        ),
        // Corner brackets, centered to match the scrim cutout exactly.
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              size: const Size(220, 220),
              painter: ScannerOverlayShape(),
            ),
          ),
        ),
        // Dynamic animated laser line sweeping up and down inside the 220px box.
        const _AnimatedLaserLine(boxSize: 220),
        // Caption sits below the window without shifting the frame's centering.
        Center(
          child: Transform.translate(
            offset: const Offset(0, 110 + 28),
            child: Text(
              'Align QR code within the frame',
              style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dynamic animated laser line that sweeps vertically inside the scanner window.
class _AnimatedLaserLine extends StatefulWidget {
  const _AnimatedLaserLine({this.boxSize = 220});

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
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.permanent, required this.onRequest});

  final bool permanent;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              permanent
                  ? 'Camera access is blocked'
                  : 'Camera permission required',
              style: AppTextStyles.titleMd.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              permanent
                  ? 'Please enable camera access in your device settings to scan QR codes.'
                  : 'Camera access is needed to scan QR codes and earn rewards.',
              style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRequest,
              child: Text(
                permanent ? 'Open Settings' : 'Grant Permission',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.info, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scanning for Rewards', style: AppTextStyles.titleMd),
                    const SizedBox(height: 6),
                    Text(
                      'Scan the QR code found on your ${AppStrings.productName} receipts or partner storefronts to instantly claim your points.',
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
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Obx(() {
              final points = Get.find<ProfileController>().profile?.points;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Balance:',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFFFB800),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        points != null
                            ? '${_formatPoints(points)} Points'
                            : '...',
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  static String _formatPoints(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
