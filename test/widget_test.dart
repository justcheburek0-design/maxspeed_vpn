import 'package:flutter_test/flutter_test.dart';
import 'package:maxspeed_vpn/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaxSpeedVpnApp());
    await tester.pumpAndSettle();
  });
}
