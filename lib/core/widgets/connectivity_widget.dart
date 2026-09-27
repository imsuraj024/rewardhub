import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rewardhub/core/network/connection_status.dart';
import 'package:rewardhub/core/services/connectivity_service.dart';
import 'package:rewardhub/core/services/i_connectivity_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';

/// A widget that listens to [IConnectivityService.statusStream] and displays
/// a [MaterialBanner] above [child] when the connection is degraded.
///
/// Mounted once for the whole app via `GetMaterialApp.builder`, so [child] is
/// the root Navigator. The tree shape never changes with the status, so the
/// Navigator (and every route's state) survives the banner coming and going.
///
/// - [ConnectionStatus.disconnected]: non-dismissible error banner
/// - [ConnectionStatus.slow]: dismissible warning banner
/// - [ConnectionStatus.connected]: renders [child] with no banner
class ConnectivityWidget extends StatefulWidget {
  const ConnectivityWidget({super.key, required this.child, this.service});

  final Widget child;

  /// Optional [IConnectivityService] override — useful for testing.
  final IConnectivityService? service;

  @override
  State<ConnectivityWidget> createState() => _ConnectivityWidgetState();
}

class _ConnectivityWidgetState extends State<ConnectivityWidget> {
  late ConnectionStatus _status;
  late final StreamSubscription<ConnectionStatus> _subscription;

  @override
  void initState() {
    super.initState();
    final service = widget.service ?? ConnectivityService();
    _status = service.currentStatus;
    _subscription = service.statusStream.listen((status) {
      if (!mounted) return;
      setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// The banner for [status], or null when connected.
  Widget? _bannerFor(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connected => null,
      ConnectionStatus.disconnected => _banner(
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        icon: Icons.wifi_off_rounded,
        iconColor: AppColors.error,
        message: "You're offline. Your points may not be up to date.",
      ),
      ConnectionStatus.slow => _banner(
        background: AppColors.warningContainer,
        foreground: AppColors.onWarningContainer,
        icon: Icons.network_check_rounded,
        iconColor: AppColors.warning,
        message: 'Slow internet. Things may take longer to load.',
        onDismiss: () => setState(() => _status = ConnectionStatus.connected),
      ),
    };
  }

  Widget _banner({
    required Color background,
    required Color foreground,
    required IconData icon,
    required Color iconColor,
    required String message,
    VoidCallback? onDismiss,
  }) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: ColoredBox(
        color: background,
        // The banner consumes the status-bar inset for the page below it.
        child: SafeArea(
          bottom: false,
          child: MaterialBanner(
            backgroundColor: background,
            elevation: 0,
            dividerColor: Colors.transparent,
            leading: Icon(icon, color: iconColor, size: 20),
            content: Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(color: foreground),
            ),
            actions: onDismiss == null
                ? const [SizedBox.shrink()]
                : [
                    TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(foregroundColor: foreground),
                      child: Text(
                        'Dismiss',
                        style: AppTextStyles.labelLg.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerFor(_status);
    return Column(
      children: [
        banner ?? const SizedBox.shrink(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: banner != null,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
