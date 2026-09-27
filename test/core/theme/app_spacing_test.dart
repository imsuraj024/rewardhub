import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';

void main() {
  test('positive: spacing scale has its spec values', () {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.md, 12);
    expect(AppSpacing.lg, 16);
    expect(AppSpacing.xl, 20);
    expect(AppSpacing.xxl, 24);
    expect(AppSpacing.xxxl, 32);
    expect(AppSpacing.pageGutter, 16);
    expect(AppSpacing.authGutter, 24);
    expect(AppSpacing.cardPadding, 16);
    expect(AppSpacing.sheetPadding, 24);
  });

  test('positive: radius scale has its spec values', () {
    expect(AppRadius.xs, 4);
    expect(AppRadius.sm, 8);
    expect(AppRadius.md, 12);
    expect(AppRadius.lg, 16);
    expect(AppRadius.xl, 24);
    expect(AppRadius.sheet, 28);
    expect(AppRadius.pill, 999);
  });
}
