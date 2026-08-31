import 'package:flutter/material.dart';
import 'package:rewardhub/core/widgets/app_banner.dart';

/// Data model representing a promotional or announcement banner.
class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.variant = 'split',
    this.style = 'primary',
    this.imageUrl,
    this.badgeText,
    this.iconName,
    this.isActive = true,
    this.order = 0,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Variant type: 'split' | 'text' | 'image' | 'progress'
  final String variant;

  /// Visual theme: 'primary' | 'gold' | 'success' | 'dark' | 'subtle'
  final String style;

  /// Remote image URL for 'image' variant.
  final String? imageUrl;

  /// Badge chip text (e.g. 'LIMITED OFFER', 'BONUS').
  final String? badgeText;

  /// Name identifier for leading/graphic icon.
  final String? iconName;

  /// Whether this banner is currently active and visible.
  final bool isActive;

  /// Display priority/order index.
  final int order;

  /// Maps [style] string to [AppBannerStyle] enum.
  AppBannerStyle get bannerStyle {
    switch (style.toLowerCase()) {
      case 'gold':
        return AppBannerStyle.gold;
      case 'success':
        return AppBannerStyle.success;
      case 'dark':
        return AppBannerStyle.dark;
      case 'subtle':
        return AppBannerStyle.subtle;
      case 'primary':
      default:
        return AppBannerStyle.primary;
    }
  }

  /// Maps [iconName] string to [IconData].
  IconData get iconData {
    switch (iconName?.toLowerCase()) {
      case 'gift':
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'flag':
      case 'quest':
        return Icons.flag_rounded;
      case 'book':
      case 'menu_book':
      case 'catalogue':
        return Icons.menu_book_rounded;
      case 'bolt':
      case 'flash':
        return Icons.bolt_rounded;
      case 'qr':
      case 'qr_code':
        return Icons.qr_code_scanner_rounded;
      case 'trophy':
      case 'star':
      case 'stars':
      default:
        return Icons.stars_rounded;
    }
  }

  /// Factory converter from JSON map.
  factory BannerModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return BannerModel(
      id: docId ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      variant: json['variant'] as String? ?? 'split',
      style: json['style'] as String? ?? 'primary',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      badgeText: json['badgeText'] as String? ?? json['badge_text'] as String?,
      iconName: json['iconName'] as String? ?? json['icon_name'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'variant': variant,
      'style': style,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (badgeText != null) 'badgeText': badgeText,
      if (iconName != null) 'iconName': iconName,
      'isActive': isActive,
      'order': order,
    };
  }
}
