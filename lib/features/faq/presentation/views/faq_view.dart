import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';

/// A single question-and-answer entry.
class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

/// A titled group of FAQ entries.
class _FaqCategory {
  const _FaqCategory(this.title, this.items);
  final String title;
  final List<_FaqItem> items;
}

/// All FAQ content, grouped by topic. Written in plain, user-friendly language.
const List<_FaqCategory> _faqCategories = [
  _FaqCategory('Getting Started', [
    _FaqItem(
      'What is the ${AppStrings.productName} app?',
      '${AppStrings.productName} is a loyalty and rewards program app. You earn '
          'points every time you purchase genuine ${AppStrings.productName} products '
          'or shop at partner stores, and you can turn those points into real cash '
          'paid straight to your UPI or bank account.',
    ),
    _FaqItem(
      'How do I create an account?',
      'Tap "Register" on the welcome screen and complete three simple steps:\n\n'
          '1. Enter your full name and mobile number.\n'
          '2. Enter your preferred payout account — your UPI ID (Google Pay, '
          'PhonePe, Paytm) or bank account details.\n'
          '3. Upload a photo of your Aadhaar card and a selfie for verification.\n\n'
          'Once submitted, your registration is reviewed by our team for approval. '
          'After approval, you can log in and start earning rewards.',
    ),
    _FaqItem(
      'Why do I need to submit Aadhaar and a selfie?',
      'This one-time identity verification (KYC) ensures that your reward earnings '
          'and payouts are secure and delivered safely to you. Your details are '
          'encrypted and used solely for identity verification.',
    ),
    _FaqItem(
      'Do I need a referral code to sign up?',
      'No — the referral code is optional. If someone invited you, enter their '
          'code during registration. Otherwise, you can leave it blank and continue.',
    ),
    _FaqItem(
      'Why can\'t I log in immediately after registering?',
      'New registrations undergo a quick security review by our admin team. '
          'You will be able to log in as soon as your account is approved. '
          'If approval takes longer than expected, please reach out to support.',
    ),
  ]),
  _FaqCategory('Earning Points', [
    _FaqItem(
      'How do I earn reward points?',
      'On the home screen or bottom menu, tap "QR Scan" and point your camera at '
          'the QR code printed on your ${AppStrings.productName} receipt or product '
          'packaging. Points are credited to your balance instantly upon a successful scan.',
    ),
    _FaqItem(
      'Where do I find the QR code to scan?',
      'QR codes are printed on authentic ${AppStrings.productName} purchase receipts, '
          'product tags, and promotional vouchers at authorized partner stores.',
    ),
    _FaqItem(
      'The camera isn\'t opening or scanning. What should I do?',
      'Ensure the app has camera permissions enabled. If prompted, tap "Allow". '
          'If previously denied, go to your phone\'s Settings > Apps > ${AppStrings.productName} '
          '> Permissions, and turn on Camera access. Make sure the QR code is well-lit '
          'and placed fully inside the scanning frame.',
    ),
    _FaqItem(
      'I scanned a QR code, but my points weren\'t added.',
      'Points usually update instantly — try pulling down to refresh the Home screen. '
          'Each QR code can only be scanned once. If your code is valid but points '
          'did not appear, contact support with the receipt details.',
    ),
  ]),
  _FaqCategory('Redeeming Rewards', [
    _FaqItem(
      'How do I redeem my accumulated points?',
      'Tap the "Redeem" button on your Home screen. Enter the points you wish to '
          'convert, and submit your request. The equivalent payout will be processed '
          'directly to your saved payout method.',
    ),
    _FaqItem(
      'Where will my redemption money be sent?',
      'Your rewards money is transferred to the UPI ID (Google Pay, PhonePe, Paytm) '
          'or bank account you provided during registration.',
    ),
    _FaqItem(
      'How long does a reward payout take to process?',
      'Redemption requests are verified promptly and payouts are initiated '
          'shortly after review. You can check the status in your Recent Activity.',
    ),
    _FaqItem(
      'Can I update my UPI ID or bank account details?',
      'To update your registered payout details securely, please contact our '
          'support team using the email link below.',
    ),
  ]),
  _FaqCategory('Product Catalogue', [
    _FaqItem(
      'What is the Product Catalogue?',
      'The Catalogue tab gives you instant digital access to the complete range '
          'of ${AppStrings.productName} products, technical specifications, and hardware '
          'listings directly inside the app.',
    ),
    _FaqItem(
      'How do I search or jump to specific pages in the catalogue?',
      'Use the "Go to Page" icon at the top of the Catalogue screen to type a page '
          'number directly. You can also swipe vertically to browse through pages.',
    ),
    _FaqItem(
      'Can I view the catalogue offline?',
      'Yes — once loaded, the catalogue document is saved locally on your device so '
          'you can view product details even without an active internet connection. '
          'Tap the Refresh icon anytime to check for updated versions.',
    ),
  ]),
  _FaqCategory('Account & Security', [
    _FaqItem(
      'Where can I check my current balance and activity?',
      'Your live points balance is displayed prominently on the Home and Profile '
          'screens. You can view a breakdown of earned and redeemed points under '
          'Recent Activity on the Home screen.',
    ),
    _FaqItem(
      'How do I log in to my account?',
      'Enter your registered mobile number on the login screen. You will receive '
          'a 6-digit OTP code via SMS — enter it to log in securely without needing a password.',
    ),
    _FaqItem(
      'How do I safely log out of the app?',
      'Go to the Profile tab, scroll down to the bottom, and tap "Logout Account".',
    ),
  ]),
];

/// Static Help & Support / FAQ screen.
///
/// Reached from the "Help & Support" row on the Profile page and the "Support"
/// quick action on Home. A sticky header (support contact, search and category
/// chips) sits above a scrolling list of expandable question cards.
class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  final _searchController = TextEditingController();
  String _query = '';

  /// 0..n map to [_faqCategories].
  int _categoryIndex = 0;

  /// Question text of the currently expanded card, or null if all collapsed.
  /// Only one card is open at a time.
  String? _openQuestion;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Questions matching the active category chip and search text.
  List<_FaqItem> get _visibleItems {
    final source = _faqCategories[_categoryIndex].items;

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return source.toList();
    return source
        .where(
          (i) =>
              i.question.toLowerCase().contains(q) ||
              i.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Help & Support', showBackButton: true),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  const _ContactSupportCard(),
                  const SizedBox(height: 16),
                  _SearchField(
                    controller: _searchController,
                    query: _query,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                ],
              ),
            ),
            _CategoryChips(
              selectedIndex: _categoryIndex,
              onSelected: (i) => setState(() => _categoryIndex = i),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyResults()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final expanded = item.question == _openQuestion;
                        return _FaqCard(
                          key: ValueKey(item.question),
                          item: item,
                          expanded: expanded,
                          query: _query,
                          onTap: () {
                            // Only an open counts as engagement, not a collapse.
                            if (!expanded) {
                              Get.find<AppAnalytics>().faqQuestionExpanded(
                                item.question,
                              );
                            }
                            setState(
                              () => _openQuestion = expanded
                                  ? null
                                  : item.question,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded, filled search box used to filter questions live.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMd,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search help topics',
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: 'Clear',
                onPressed: onClear,
              ),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Horizontal, single-select category filter chips (one for each topic).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = [for (final c in _faqCategories) c.title];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                labels[i],
                style: AppTextStyles.labelLg.copyWith(
                  color: selected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown when a search/filter combination matches no questions.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search, or email support above.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single expandable question card. Expansion is controlled by the parent so
/// only one card is open at a time.
class _FaqCard extends StatelessWidget {
  const _FaqCard({
    super.key,
    required this.item,
    required this.expanded,
    required this.onTap,
    required this.query,
  });

  final _FaqItem item;
  final bool expanded;
  final VoidCallback onTap;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
          width: expanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: expanded ? 0.04 : 0.08),
            blurRadius: expanded ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _HighlightedText(
                          text: item.question,
                          query: query,
                          style: AppTextStyles.titleSm,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: expanded
                              ? AppColors.primary
                              : AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: expanded
                                ? AppColors.onPrimary
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 12),
                    _HighlightedText(
                      text: item.answer,
                      query: query,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders [text] with every case-insensitive occurrence of [query] visually
/// highlighted. Falls back to a plain [Text] when [query] is empty.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
  });

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final term = query.trim();
    if (term.isEmpty) return Text(text, style: style);

    final lowerText = text.toLowerCase();
    final lowerTerm = term.toLowerCase();

    final highlightStyle = style.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      backgroundColor: AppColors.primaryFixed,
    );

    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerTerm, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + term.length),
          style: highlightStyle,
        ),
      );
      start = index + term.length;
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}

/// Support email fallback when RemoteConfigService is unavailable.
const String kSupportEmail = 'support@kitoxhardware.com';

/// "Still need help?" card with a tap-to-copy support email.
class _ContactSupportCard extends StatelessWidget {
  const _ContactSupportCard();

  String get _supportEmail {
    if (Get.isRegistered<RemoteConfigService>()) {
      final email = Get.find<RemoteConfigService>().supportEmail;
      if (email.isNotEmpty) return email;
    }
    return kSupportEmail;
  }

  void _copyEmail(String email) {
    if (email.isEmpty) return;
    // A proxy for problems the FAQ did not solve.
    Get.find<AppAnalytics>().supportEmailCopied();
    Clipboard.setData(ClipboardData(text: email));
    AppToast.success('Support email copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final email = _supportEmail;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help? Email support',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyEmail(email),
              child: Icon(
                Icons.copy_rounded,
                color: AppColors.onPrimary.withValues(alpha: 0.9),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
