import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/models/banner_model.dart';
import 'package:rewardhub/core/widgets/app_banner.dart';

void main() {
  group('BannerModel', () {
    test('positive: fromJson parses full banner JSON map correctly', () {
      final json = {
        'id': 'b1',
        'title': 'Double Points Weekend',
        'subtitle': 'Scan and earn 2X',
        'variant': 'split',
        'style': 'gold',
        'imageUrl': 'https://example.com/b.png',
        'badgeText': 'HOT',
        'iconName': 'stars',
        'isActive': true,
        'order': 2,
      };

      final banner = BannerModel.fromJson(json, 'b1');

      expect(banner.id, 'b1');
      expect(banner.title, 'Double Points Weekend');
      expect(banner.subtitle, 'Scan and earn 2X');
      expect(banner.variant, 'split');
      expect(banner.style, 'gold');
      expect(banner.bannerStyle, AppBannerStyle.gold);
      expect(banner.imageUrl, 'https://example.com/b.png');
      expect(banner.badgeText, 'HOT');
      expect(banner.iconName, 'stars');
      expect(banner.iconData, Icons.stars_rounded);
      expect(banner.isActive, isTrue);
      expect(banner.order, 2);
    });

    test('positive: style and icon mapping handles all presets', () {
      expect(
        const BannerModel(id: '1', title: '', subtitle: '', style: 'primary')
            .bannerStyle,
        AppBannerStyle.primary,
      );
      expect(
        const BannerModel(id: '2', title: '', subtitle: '', style: 'success')
            .bannerStyle,
        AppBannerStyle.success,
      );
      expect(
        const BannerModel(id: '3', title: '', subtitle: '', style: 'dark')
            .bannerStyle,
        AppBannerStyle.dark,
      );
      expect(
        const BannerModel(id: '4', title: '', subtitle: '', style: 'subtle')
            .bannerStyle,
        AppBannerStyle.subtle,
      );

      expect(
        const BannerModel(id: '1', title: '', subtitle: '', iconName: 'gift')
            .iconData,
        Icons.card_giftcard_rounded,
      );
      expect(
        const BannerModel(id: '2', title: '', subtitle: '', iconName: 'flag')
            .iconData,
        Icons.flag_rounded,
      );
      expect(
        const BannerModel(id: '3', title: '', subtitle: '', iconName: 'book')
            .iconData,
        Icons.menu_book_rounded,
      );
      expect(
        const BannerModel(id: '4', title: '', subtitle: '', iconName: 'bolt')
            .iconData,
        Icons.bolt_rounded,
      );
      expect(
        const BannerModel(id: '5', title: '', subtitle: '', iconName: 'qr')
            .iconData,
        Icons.qr_code_scanner_rounded,
      );
    });

    test('positive: toJson produces expected map structure', () {
      const banner = BannerModel(
        id: 'b2',
        title: 'Referral Program',
        subtitle: 'Share code',
        variant: 'text',
        style: 'primary',
        badgeText: 'BONUS',
        isActive: true,
        order: 1,
      );

      final json = banner.toJson();

      expect(json['title'], 'Referral Program');
      expect(json['subtitle'], 'Share code');
      expect(json['variant'], 'text');
      expect(json['style'], 'primary');
      expect(json['badgeText'], 'BONUS');
      expect(json['isActive'], isTrue);
      expect(json['order'], 1);
    });
  });
}
