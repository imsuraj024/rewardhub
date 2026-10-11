import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/core/widgets/app_state_message.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';

/// A single question-and-answer entry.
class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

/// One row of the results list: a category header or a question.
sealed class _FaqEntry {
  const _FaqEntry();
}

/// Category title shown above its questions when the scope is "All".
final class _FaqHeaderEntry extends _FaqEntry {
  const _FaqHeaderEntry(this.title);
  final String title;
}

final class _FaqItemEntry extends _FaqEntry {
  const _FaqItemEntry(this.item);
  final _FaqItem item;
}

/// A titled group of FAQ entries.
class _FaqCategory {
  const _FaqCategory(this.title, this.items);
  final String title;
  final List<_FaqItem> items;
}

/// All FAQ content, grouped by topic. Written in plain, user-friendly language.
const List<_FaqCategory> _faqCategories = [
  _FaqCategory('Getting started', [
    _FaqItem(
      'What is the ${AppStrings.productName} app?',
      '${AppStrings.productName} is a rewards app. Scan the QR code on genuine '
          '${AppStrings.productName} products to earn points. Then redeem your '
          'points for money in your UPI or bank account.',
    ),
    _FaqItem(
      'How do I create an account?',
      'On the login screen, tap Register and complete three simple steps:\n\n'
          '1. Enter your full name and mobile number.\n'
          '2. Enter your UPI ID or Google Pay number. You can also add a bank '
          'account.\n'
          '3. Upload a photo of your Aadhaar card and a selfie for verification.\n\n'
          'Once submitted, your registration is reviewed by our team for approval. '
          'After approval, you can log in and start earning points.',
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
  _FaqCategory('Earning points', [
    _FaqItem(
      'How do I earn points?',
      'Tap Scan in the bottom menu. Point your camera at the QR code.',
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
  _FaqCategory('Redeeming points', [
    _FaqItem(
      'How do I redeem my accumulated points?',
      'Tap Redeem on the Home screen, or Redeem points in Wallet. Check the '
          'details, then tap Send request. The money goes to the UPI ID or bank '
          'account you gave when you registered.',
    ),
    _FaqItem(
      'Where will my redemption money be sent?',
      'Your rewards money is transferred to the UPI ID (Google Pay, PhonePe, Paytm) '
          'or bank account you provided during registration.',
    ),
    _FaqItem(
      'How do I check a redemption?',
      'Redeemed points show in Wallet under Transaction history. If the money '
          "hasn't reached your UPI ID or bank account, email support. The address "
          'is at the top of this screen.',
    ),
    _FaqItem(
      'Can I update my UPI ID or bank account details?',
      'To change your UPI ID or bank account, email support. The address is at '
          'the top of this screen.',
    ),
  ]),
  _FaqCategory('Product catalogue', [
    _FaqItem(
      'What is the product catalogue?',
      'The Catalogue tab gives you instant digital access to the complete range '
          'of ${AppStrings.productName} products, technical specifications, and hardware '
          'listings directly inside the app.',
    ),
    _FaqItem(
      'How do I search or jump to specific pages in the catalogue?',
      'Use the "Go to page" icon at the top of the Catalogue screen to type a page '
          'number directly. You can also swipe vertically to browse through pages.',
    ),
    _FaqItem(
      'Can I view the catalogue offline?',
      'Yes — once loaded, the catalogue document is saved locally on your device so '
          'you can view product details even without an active internet connection. '
          'Tap the Reload icon anytime to check for updated versions.',
    ),
  ]),
  _FaqCategory('Account & security', [
    _FaqItem(
      'Where can I see my points and history?',
      'Your points show on Home and in Wallet. Wallet › Transaction history '
          'lists points earned and redeemed.',
    ),
    _FaqItem(
      'How do I log in to my account?',
      'Enter your registered mobile number on the login screen and tap Continue.',
    ),
    _FaqItem(
      'How do I safely log out of the app?',
      'Go to the Profile tab and tap Log out at the bottom of the screen.',
    ),
  ]),
];

/// Static Help & support / FAQ screen.
///
/// Reached from the "Help & support" row on the Profile page and the "Support"
/// quick action on Home. The support contact card scrolls away; the search
/// field and category chips stay pinned above a list of expandable question
/// cards.
class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  final _searchController = TextEditingController();
  String _query = '';

  /// 0 = All; i ≥ 1 maps to `_faqCategories[i - 1]`.
  int _categoryIndex = 0;

  /// Question text of the currently expanded card, or null if all collapsed.
  /// Only one card is open at a time.
  String? _openQuestion;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Rows matching the active chip and search text. "All" groups the matches
  /// under their category headers and skips categories with no match.
  List<_FaqEntry> get _entries {
    final q = _query.trim().toLowerCase();
    bool matches(_FaqItem i) =>
        q.isEmpty ||
        i.question.toLowerCase().contains(q) ||
        i.answer.toLowerCase().contains(q);

    if (_categoryIndex > 0) {
      return [
        for (final i in _faqCategories[_categoryIndex - 1].items)
          if (matches(i)) _FaqItemEntry(i),
      ];
    }

    final entries = <_FaqEntry>[];
    for (final c in _faqCategories) {
      final items = c.items.where(matches).toList();
      if (items.isEmpty) continue;
      entries.add(_FaqHeaderEntry(c.title));
      entries.addAll(items.map(_FaqItemEntry.new));
    }
    return entries;
  }

  Widget _buildEntry(List<_FaqEntry> entries, int index) {
    return switch (entries[index]) {
      _FaqHeaderEntry(:final title) => Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.sm),
          child: Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.overline),
          ),
        ),
      _FaqItemEntry(:final item) => _buildCard(item),
    };
  }

  Widget _buildCard(_FaqItem item) {
    final expanded = item.question == _openQuestion;
    return _FaqCard(
      key: ValueKey(item.question),
      item: item,
      expanded: expanded,
      query: _query,
      onTap: () {
        // Only an open counts as engagement, not a collapse.
        if (!expanded && Get.isRegistered<AppAnalytics>()) {
          Get.find<AppAnalytics>().faqQuestionExpanded(item.question);
        }
        setState(() => _openQuestion = expanded ? null : item.question);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Help & support', showBackButton: true),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.sm,
                AppSpacing.pageGutter,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(child: _ContactSupportCard()),
            ),
            // Sizes itself to its child, so it grows with the text scale.
            PinnedHeaderSliver(
              child: ColoredBox(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageGutter,
                        ),
                        child: _SearchField(
                          controller: _searchController,
                          query: _query,
                          // Starting a search widens the scope to All, so no
                          // chip claims a narrower scope than the results.
                          onChanged: (v) => setState(() {
                            if (_query.trim().isEmpty && v.trim().isNotEmpty) {
                              _categoryIndex = 0;
                            }
                            _query = v;
                          }),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CategoryChips(
                        selectedIndex: _categoryIndex,
                        onSelected: (i) => setState(() => _categoryIndex = i),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (entries.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyResults(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageGutter,
                  AppSpacing.xs,
                  AppSpacing.pageGutter,
                  AppSpacing.xxl,
                ),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _buildEntry(entries, i),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
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
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                tooltip: 'Clear search',
                onPressed: onClear,
              ),
        // Borders come from the theme: the outline is what makes the white
        // field visible on the surface background.
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Horizontal, single-select scope chips: "All", then one for each topic.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = ['All', for (final c in _faqCategories) c.title];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(labels[i]),
              selected: i == selectedIndex,
              onSelected: (_) => onSelected(i),
              showCheckmark: false,
              // 48 dp touch target.
              materialTapTargetSize: MaterialTapTargetSize.padded,
              shape: const StadiumBorder(),
              side: BorderSide(
                color: i == selectedIndex
                    ? AppColors.primary
                    : AppColors.outline,
              ),
              backgroundColor: AppColors.surfaceContainerLowest,
              selectedColor: AppColors.primary,
              labelStyle: AppTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: i == selectedIndex
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when a search/filter combination matches no questions.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: AppStateMessage(
          icon: Icons.search_off_rounded,
          tone: AppIconBadgeTone.neutral,
          title: 'No results found',
          message: 'Try another word, or email us at the top of this screen.',
          boxed: false,
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

/// "Need help?" card: tap to email support, or copy the address.
class _ContactSupportCard extends StatelessWidget {
  const _ContactSupportCard();

  String get _supportEmail {
    if (Get.isRegistered<RemoteConfigService>()) {
      final email = Get.find<RemoteConfigService>().supportEmail;
      if (email.isNotEmpty) return email;
    }
    return kSupportEmail;
  }

  Future<void> _emailSupport(String email) async {
    final opened = await ExternalLinks.openOrCopy(
      ExternalLinks.email(email),
      fallbackText: email,
      fallbackMessage: "Couldn't open your email app. Email address copied.",
    );
    // A copy is a proxy for problems the FAQ did not solve.
    if (!opened && Get.isRegistered<AppAnalytics>()) {
      Get.find<AppAnalytics>().supportEmailCopied();
    }
  }

  void _copyEmail(String email) {
    // A proxy for problems the FAQ did not solve.
    if (Get.isRegistered<AppAnalytics>()) {
      Get.find<AppAnalytics>().supportEmailCopied();
    }
    ExternalLinks.copy(email, message: 'Email address copied.');
  }

  @override
  Widget build(BuildContext context) {
    final email = _supportEmail;

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _emailSupport(email),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Semantics(
                  button: true,
                  label: 'Email support, $email',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: AppColors.onPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Need help? Email us',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _copyEmail(email),
              tooltip: 'Copy support email',
              icon: const Icon(
                Icons.copy_rounded,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}
