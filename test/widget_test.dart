import 'package:flutter_test/flutter_test.dart';
import 'package:standby/main.dart';

void main() {
  testWidgets('Standby smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StandbyApp());
    expect(find.byType(GetStartedPage), findsOneWidget);
  });
}
