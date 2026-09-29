// ============================================================
// LOAN PICKER DIALOG
//
// Verifies the compact modal the Profile Drawer opens for Quick
// Actions on Home:
//
//   * every option shows its complete loan number
//   * tapping one closes the dialog and returns that "My Loans"
//     card, so the caller can load exactly that loan
//   * a long list stays inside a scrollable, capped-height dialog
//   * the currently selected loan is marked
//   * empty and still-loading lists degrade gracefully
//   * the dialog reads its colours from the active theme, so it
//     stays readable in light AND dark mode
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:vsf_consumer/translations/language_selection_translations.dart';
import 'package:vsf_consumer/utils/app_colors.dart';
import 'package:vsf_consumer/utils/app_theme.dart';
import 'package:vsf_consumer/widgets/loan_dashboard/loan_picker_dialog.dart';

Map<String, dynamic> _loan(String number, {String borrower = 'Test User'}) {
  return {
    'loanNumber': number,
    'borrowers': <String>[borrower],
    'amount': 150000.0,
    'status': 'Active',
  };
}

/// Dark counterpart used only to prove the dialog is theme-driven.
/// The app itself currently ships a light theme, so this is derived
/// from the same seed colour rather than a second product theme.
ThemeData get _darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}

Widget _app({required Widget child, Brightness brightness = Brightness.light}) {
  return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    translations: LanguageSelectionTranslations(),
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    theme: AppTheme.light,
    darkTheme: _darkTheme,
    themeMode: brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('lists every loan number and returns the tapped loan', (
    tester,
  ) async {
    Map<String, dynamic>? result;

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await LoanPickerDialog.show(
                  context,
                  loans: [_loan('LN123456'), _loan('LN654321')],
                  selectedLoanNumber: '',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Both complete loan numbers are listed, and the borrower and
    // amount are shown alongside them.
    expect(find.text('LN123456'), findsOneWidget);
    expect(find.text('LN654321'), findsOneWidget);
    expect(find.text('Test User · ₹150000 · Active'), findsNWidgets(2));
    expect(find.text('Select Loan'), findsOneWidget);

    await tester.tap(find.text('LN654321'));
    await tester.pumpAndSettle();

    // The dialog closed and handed the exact "My Loans" card back.
    expect(find.text('Select Loan'), findsNothing);
    expect(result, isNotNull);
    expect(result!['loanNumber'], 'LN654321');
  });

  testWidgets('dismissing returns null', (tester) async {
    Map<String, dynamic>? result;

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await LoanPickerDialog.show(
                  context,
                  loans: [_loan('LN123456')],
                  selectedLoanNumber: '',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('the selected loan is marked and a long list scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final loans = List<Map<String, dynamic>>.generate(
      30,
      (index) => _loan('LN${index.toString().padLeft(6, '0')}'),
    );

    await tester.pumpWidget(
      _app(
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => LoanPickerDialog.show(
                context,
                loans: loans,
                selectedLoanNumber: 'LN000007',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The full list is scrollable instead of overflowing.
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Exactly one option is marked as the current selection.
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(
      find.byIcon(Icons.radio_button_unchecked_rounded),
      findsNWidgets(29),
    );

    // The selected entry is highlighted with the brand colour.
    final selectedTitle = tester.widget<Text>(find.text('LN000007'));

    expect(selectedTitle.style?.color, AppColors.lightBlue);

    // A long list is capped at half the screen height instead of
    // growing with the number of loans, and it really does scroll.
    final scrollable = find.byType(SingleChildScrollView);
    final visibleHeight = tester.getSize(scrollable).height;
    final screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;

    expect(visibleHeight, lessThanOrEqualTo(screenHeight * 0.5));

    // The content is taller than the viewport, so scrolling works.
    expect(
      tester.getSize(find.byType(Column).last).height,
      greaterThan(visibleHeight),
    );

    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();

    // Later loans are reachable.
    expect(find.text('LN000029'), findsOneWidget);
  });

  testWidgets('an empty list degrades gracefully', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        child: const LoanPickerDialog(
          loans: <Map<String, dynamic>>[],
          selectedLoanNumber: '',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No loans available'), findsOneWidget);
    expect(find.text('Your loan information will appear here.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('a still-loading list shows progress, not an empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        child: const LoanPickerDialog(
          loans: <Map<String, dynamic>>[],
          selectedLoanNumber: '',
          isLoading: true,
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('No loans available'), findsNothing);
  });

  testWidgets('dark mode keeps the dialog on the dark surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        brightness: Brightness.dark,
        child: LoanPickerDialog(
          loans: [_loan('LN123456')],
          selectedLoanNumber: '',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AlertDialog));
    final theme = Theme.of(context);

    // The dialog resolved the dark theme rather than the light one.
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface.computeLuminance(), lessThan(0.5));

    // No hard-coded white background was applied to the dialog.
    final materials = tester
        .widgetList<Material>(find.byType(Material))
        .where((material) => material.color != null)
        .toList();

    for (final material in materials) {
      expect(material.color, isNot(const Color(0xFFFFFFFF)));
    }
  });
}
