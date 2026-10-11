import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/harness.dart';

void main() {
  late List<RecordedToast> toasts;
  late List<String> clipboard;
  late List<(Uri, LaunchMode)> opened;

  setUp(() {
    toasts = installGetTestHarness();
    clipboard = [];
    opened = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    ExternalLinks.opener = null;
    await resetGet();
  });

  group('ExternalLinks.phone / email', () {
    test('phone keeps only digits and +', () {
      expect(
        ExternalLinks.phone('+91 98765 43210').toString(),
        'tel:+919876543210',
      );
    });

    test('email trims the address', () {
      expect(ExternalLinks.email(' a@b.com ').toString(), 'mailto:a@b.com');
    });
  });

  group('ExternalLinks.open', () {
    test('passes the URI and the default external mode to the opener',
        () async {
      ExternalLinks.opener = (uri, mode) async {
        opened.add((uri, mode));
        return true;
      };

      final result = await ExternalLinks.open(Uri.parse('https://x.com'));

      expect(result, isTrue);
      expect(opened.single.$1.toString(), 'https://x.com');
      expect(opened.single.$2, LaunchMode.externalApplication);
    });

    test('never throws: an opener error resolves false', () async {
      ExternalLinks.opener = (_, __) async => throw Exception('no handler');

      expect(await ExternalLinks.open(Uri.parse('tel:123')), isFalse);
    });
  });

  group('ExternalLinks.openOrCopy', () {
    test('opened: no copy and no toast', () async {
      ExternalLinks.opener = (_, __) async => true;

      final result = await ExternalLinks.openOrCopy(
        ExternalLinks.email('a@b.com'),
        fallbackText: 'a@b.com',
        fallbackMessage: 'Copied instead.',
      );

      expect(result, isTrue);
      expect(clipboard, isEmpty);
      expect(toasts, isEmpty);
    });

    test('not opened: copies the fallback and shows one info toast', () async {
      ExternalLinks.opener = (_, __) async => false;

      final result = await ExternalLinks.openOrCopy(
        ExternalLinks.email('a@b.com'),
        fallbackText: 'a@b.com',
        fallbackMessage: 'Copied instead.',
      );

      expect(result, isFalse);
      expect(clipboard, ['a@b.com']);
      expect(toasts, hasLength(1));
      expect(toasts.single.type, ToastType.info);
      expect(toasts.single.message, 'Copied instead.');
      expect(toasts.single.title, isNull);
    });

    test('opener throws: same fallback as not opened', () async {
      ExternalLinks.opener = (_, __) async => throw Exception('boom');

      final result = await ExternalLinks.openOrCopy(
        ExternalLinks.phone('+91 98765 43210'),
        fallbackText: '+91 98765 43210',
        fallbackMessage: 'Number copied instead.',
      );

      expect(result, isFalse);
      expect(clipboard, ['+91 98765 43210']);
      expect(toasts.single.type, ToastType.info);
      expect(toasts.single.message, 'Number copied instead.');
    });
  });

  group('ExternalLinks.copy', () {
    test('copies the text and shows a success toast without a title', () async {
      await ExternalLinks.copy('KX-1', message: 'Code copied.');

      expect(clipboard, ['KX-1']);
      expect(toasts.single.type, ToastType.success);
      expect(toasts.single.message, 'Code copied.');
      expect(toasts.single.title, isNull);
    });
  });
}
