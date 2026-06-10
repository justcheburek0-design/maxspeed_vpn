import 'package:flutter_test/flutter_test.dart';
import 'package:maxspeed_vpn/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const MaxSpeedVpnApp());
    expect(find.text('MaxSpeedVPN'), findsOneWidget);
  });
}
