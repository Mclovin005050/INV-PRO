import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/main.dart';

void main() {
  testWidgets('Dashboard load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InventoryApp());

    // Verify that the Dashboard is showing (Overview is the header in DashboardScreen)
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Total Products'), findsOneWidget);
  });
}
