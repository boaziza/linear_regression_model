import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('Shows the page title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Monthly income'), findsOneWidget);
  });
}
