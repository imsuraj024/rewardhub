import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/catalogue/presentation/controllers/catalogue_controller.dart';

/// Screen displaying the PDF product catalogue from a remote URL or local cache.
class CatalogueView extends GetView<CatalogueController> {
  const CatalogueView({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.onSurface,
                ),
                onPressed: () => Get.back(),
              )
            : null,
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.documentTitle.value,
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (controller.isPdfReady.value &&
                  controller.totalPages.value > 0)
                Text(
                  'Page ${controller.currentPage.value + 1} of ${controller.totalPages.value}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Catalogue',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurface),
            onPressed: () => controller.loadPdf(forceRefresh: true),
          ),
          Obx(() {
            if (!controller.isPdfReady.value ||
                controller.totalPages.value <= 1) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Go to Page',
              icon: const Icon(
                Icons.find_in_page_outlined,
                color: AppColors.onSurface,
              ),
              onPressed: () => _showJumpToPageDialog(context),
            );
          }),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
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
            message: 'Catalogue file is unavailable.',
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

  void _showJumpToPageDialog(BuildContext context) {
    final textController = TextEditingController();
    Get.dialog<void>(
      Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Go to Page',
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter page number (1 - ${controller.totalPages.value}):',
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. ${(controller.currentPage.value + 1)}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Go',
                    size: AppButtonSize.sm,
                    onPressed: () {
                      final input = int.tryParse(textController.text.trim());
                      if (input != null &&
                          input >= 1 &&
                          input <= controller.totalPages.value) {
                        Get.back();
                        controller.jumpToPage(input - 1);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Loading Catalogue...',
              style: AppTextStyles.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress > 0 && progress < 1
                  ? 'Downloading $percent%'
                  : 'Preparing document for high-res viewing',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Progress bar
            SizedBox(
              width: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: progress > 0
                    ? LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      )
                    : const LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Catalogue',
              style: AppTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Try Again',
              leadingIcon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 16,
              ),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
