import 'package:flutter_test/flutter_test.dart';
import 'package:lexicore_ui/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LexiCoreApp());
    expect(find.text('LexiCore'), findsOneWidget);
  });
}
