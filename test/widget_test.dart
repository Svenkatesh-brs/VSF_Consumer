import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vsf_consumer/providers/auth_provider.dart';
import 'package:vsf_consumer/screens/login_screen.dart';

void main() {
  setUp(() {
    Get.put(AuthProvider());
  });

  tearDown(() {
    Get.delete<AuthProvider>();
  });

  testWidgets('Login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}