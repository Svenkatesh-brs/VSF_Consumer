import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vsf_consumer/screens/login_screen.dart';

void main() {
  testWidgets('Login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}