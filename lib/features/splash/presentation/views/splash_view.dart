import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';

/// Shown on app launch while [AuthController.restoreSession] initializes.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LogoBadge(pulse: _pulseAnim),
                        const SizedBox(height: 28),
                        const _Wordmark(),
                        const SizedBox(height: 10),
                        Text(
                          'Scan, earn, and redeem rewards every day.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.productNameUpper,
                          style: AppTextStyles.labelSm.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = 8.0 + (pulse.value * 12.0);
        return Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35 * pulse.value),
                blurRadius: glow,
                spreadRadius: pulse.value * 3,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.stars_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.headlineLg.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: [
          const TextSpan(
            text: 'Kitox',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: ' Hardware',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
