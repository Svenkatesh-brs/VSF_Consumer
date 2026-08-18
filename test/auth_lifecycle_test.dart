import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:vsf_consumer/bindings/app_binding.dart';
import 'package:vsf_consumer/providers/auth_provider.dart';
import 'package:vsf_consumer/routes/app_pages.dart';
import 'package:vsf_consumer/routes/app_routes.dart';
import 'package:vsf_consumer/screens/otp_screen.dart';
import 'package:vsf_consumer/utils/app_theme.dart';

Finder otpTextField() => find.byWidgetPredicate(
      (w) => w is TextField && w.maxLength == 6,
    );

Finder loginTextField() => find.byWidgetPredicate(
      (w) => w is TextField && w.maxLength == 10,
    );

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 80,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $finder');
}

Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 60,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for $finder to be removed');
}

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        title: 'VSF Consumer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialBinding: AppBinding(),
        initialRoute: AppRoutes.login,
        getPages: AppPages.pages,
      ),
    );
    await tester.pump();
  }

  testWidgets('Login -> OTP -> Home -> Logout -> Login -> OTP works',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    // ---- FIRST LOGIN ----
    await pumpUntilFound(tester, find.text('Welcome Back'));

    await tester.enterText(loginTextField(), '9876543210');
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Continue'));
    await pumpUntilFound(tester, find.text('Verify OTP'));
    expect(tester.takeException(), isNull);

    // ---- ENTER OTP + VERIFY ----
    await tester.enterText(otpTextField(), '123456');
    await tester.pump();

    // Let the staggered OTP entrance animations finish so the
    // Verify button is on screen and tappable.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.text('Verify'));
    // Success overlay + 900ms delay before navigating Home.
    await pumpUntilFound(tester, find.text('Welcome back'));
    expect(tester.takeException(), isNull);

    // Let the static dashboard finish loading.
    await pumpUntilFound(tester, find.text('My Loans'));
    expect(tester.takeException(), isNull);

    // Let the otp -> home pushReplacement transition fully complete so the
    // first OTP screen is disposed before we touch AuthProvider again.
    await pumpUntilGone(tester, find.byType(OtpScreen));
    expect(tester.takeException(), isNull);

    // ---- LOGOUT ----
    // The logout button is off-screen in the test's wider-than-real Ahem font,
    // so invoke the exact callback the button is wired to.
    final logoutIcon = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.logout_rounded),
    );
    logoutIcon.onPressed!();
    await pumpUntilFound(tester, find.text('Are you sure you want to logout?'));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await pumpUntilFound(tester, find.text('Welcome Back'));
    expect(tester.takeException(), isNull);

    // ---- SECOND LOGIN ----
    await tester.enterText(loginTextField(), '9876543210');
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Continue'));
    await pumpUntilFound(tester, find.text('Verify OTP'));
    expect(tester.takeException(), isNull);

    // OTP reached on the second attempt: can type and verify again.
    await tester.enterText(otpTextField(), '123456');
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Leave the app in a stable state: unmount the tree first, then dispose
    // the permanent provider so its OTP countdown timer isn't left pending.
    await tester.pumpWidget(const SizedBox.shrink());
    // Fire any remaining entrance-animation delay timers before the test ends.
    await tester.pump(const Duration(milliseconds: 500));
    Get.delete<AuthProvider>(force: true);
  });
}