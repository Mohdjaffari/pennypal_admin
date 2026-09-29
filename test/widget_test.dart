import 'package:flutter_test/flutter_test.dart';
import 'package:pennypal_admin/main.dart';

void main() {
  testWidgets('PennyPal Admin smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PennyPalAdminApp());
    expect(find.byType(PennyPalAdminApp), findsOneWidget);
  });
}
