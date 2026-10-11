import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/core/widgets/app_state_message.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';
import 'package:rewardhub/features/catalogue/presentation/controllers/catalogue_controller.dart';

/// Screen displaying the PDF product catalogue from a remote URL or local cache.
class CatalogueView extends GetView<CatalogueController> {
  const CatalogueView({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // Scaffold.appBar needs a PreferredSizeWidget; the Obx rebuilds only
      // the bar on page changes.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          final ready =
              controller.isPdfReady.value && controller.totalPages.value > 0;
          return AppTopBar(
            title: controller.documentTitle.value,
            subtitle: ready
                ? 'Page ${controller.currentPage.value + 1} of ${controller.totalPages.value}'
                : null,
            showBackButton: showBackButton,
            actions: [
              IconButton(
                tooltip: 'Reload catalogue',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.onSurface,
                ),
                onPressed: () => controller.loadPdf(forceRefresh: true),
              ),
              if (controller.isPdfReady.value &&
                  controller.totalPages.value > 1)
                IconButton(
                  tooltip: 'Go to page',
                  icon: const Icon(
                    Icons.find_in_page_rounded,
                    color: AppColors.onSurface,
                  ),
                  onPressed: _showJumpToPageDialog,
                ),
              const SizedBox(width: AppSpacing.sm),
            ],
          );
        }),
      ),
      body: Obx(() {
        final state = controller.state.value;

        if (state is ViewStateLoading || state is ViewStateInitial) {
          return _DownloadingState(progress: controller.downloadProgress.value);
        }

        if (state is ViewStateError<String>) {
          return _ErrorState(
            message: state.message,
            onRetry: () => controller.loadPdf(forceRefresh: true),
          );
        }

        final filePath = (state as ViewStateSuccess<String>).data;
        if (filePath == null) {
          return _ErrorState(
            message:
                'Catalogue not available right now. Please try again later.',
            onRetry: () => controller.loadPdf(forceRefresh: true),
          );
        }

        return PDFView(
          filePath: filePath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          onRender: controller.onPdfRender,
          onViewCreated: controller.onPdfViewCreated,
          onPageChanged: controller.onPageChanged,
          onError: controller.onPdfError,
          onPageError: (page, error) => controller.onPdfError(error),
        );
      }),
    );
  }

  void _showJumpToPageDialog() {
    Get.dialog<void>(
      _GoToPageDialog(
        total: controller.totalPages.value,
        current: controller.currentPage.value,
        onGo: controller.jumpToPage,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Go to page dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Asks for a page number and validates it inline.
class _GoToPageDialog extends StatefulWidget {
  const _GoToPageDialog({
    required this.total,
    required this.current,
    required this.onGo,
  });

  /// Number of pages in the document.
  final int total;

  /// 0-based page on screen.
  final int current;

  /// Receives the chosen 0-based page.
  final ValueChanged<int> onGo;

  @override
  State<_GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<_GoToPageDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final n = int.tryParse(_text.text.trim());
    if (n == null || n < 1 || n > widget.total) {
      setState(() => _error = 'Enter a number from 1 to ${widget.total}.');
      return;
    }
    Navigator.of(context).pop();
    widget.onGo(n - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('Go to page', style: AppTextStyles.sheetTitle),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enter a page from 1 to ${widget.total}',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _text,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.go,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter('${widget.total}'.length),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'e.g. ${widget.current + 1}',
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                AppButton(
                  label: 'Go',
                  size: AppButtonSize.sm,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Downloading View
// ─────────────────────────────────────────────────────────────────────────────

class _DownloadingState extends StatelessWidget {
  const _DownloadingState({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIconBadge(
              icon: Icons.menu_book_rounded,
              size: AppIconBadgeSize.lg,
              circular: true,
            ),
            const SizedBox(height: 28),

            Text(
              'Loading catalogue…',
              style: AppTextStyles.titleMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              progress > 0 && progress < 1
                  ? 'Downloading $percent%'
                  : 'Getting the latest catalogue',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Progress bar
            SizedBox(
              width: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  semanticsLabel: 'Catalogue download',
                  semanticsValue: progress > 0 ? '$percent%' : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: AppStateMessage(
          icon: Icons.cloud_off_rounded,
          tone: AppIconBadgeTone.error,
          title: "Couldn't load catalogue",
          message: message,
          actionLabel: 'Try again',
          onAction: onRetry,
          boxed: false,
        ),
      ),
    );
  }
}
