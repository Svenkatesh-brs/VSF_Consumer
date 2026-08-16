import 'package:flutter_test/flutter_test.dart';
import 'package:vsf_consumer/main.dart';

void main() {
  testWidgets('Login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VSFConsumerApp());

    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}