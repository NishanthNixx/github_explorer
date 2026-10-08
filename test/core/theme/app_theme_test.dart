import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/theme/app_theme.dart';
import 'package:github_explorer_starter/features/search/presentation/pages/search_page.dart';

import '../../helpers/test_app.dart';

void main() {
  test('light and dark themes share the seed but differ in brightness', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
  });

  Future<Brightness> appBrightness(
    WidgetTester tester,
    Brightness platform,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = platform;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await TestApp.pump(tester);
    return Theme.of(tester.element(find.byType(SearchPage))).brightness;
  }

  testWidgets('follows the system light mode', (tester) async {
    expect(await appBrightness(tester, Brightness.light), Brightness.light);
  });

  testWidgets('follows the system dark mode', (tester) async {
    expect(await appBrightness(tester, Brightness.dark), Brightness.dark);
  });
}
