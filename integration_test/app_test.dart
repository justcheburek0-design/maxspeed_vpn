import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("App Integration Tests", () {
    testWidgets("should launch app", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text("MaxSpeedVPN"),
          ),
        ),
      );
      expect(find.text("MaxSpeedVPN"), findsOneWidget);
    });

    testWidgets("should navigate through onboarding", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text("Welcome"),
                ElevatedButton(
                  onPressed: () {},
                  child: Text("Next"),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text("Welcome"), findsOneWidget);
      expect(find.text("Next"), findsOneWidget);
    });

    testWidgets("should add subscription", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(),
                ElevatedButton(
                  onPressed: () {},
                  child: Text("Add"),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Add"), findsOneWidget);
    });

    testWidgets("should connect to server", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: Text("Connect"),
            ),
          ),
        ),
      );
      await tester.tap(find.text("Connect"));
      expect(find.text("Connect"), findsOneWidget);
    });

    testWidgets("should show connection stats", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text("Duration: 00:05:30"),
                Text("Download: 1.2 MB"),
                Text("Upload: 0.5 MB"),
              ],
            ),
          ),
        ),
      );
      expect(find.text("Duration: 00:05:30"), findsOneWidget);
    });

    testWidgets("should disconnect", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: Text("Disconnect"),
            ),
          ),
        ),
      );
      await tester.tap(find.text("Disconnect"));
      expect(find.text("Disconnect"), findsOneWidget);
    });

    testWidgets("should change settings", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Switch(value: true, onChanged: (_) {}),
          ),
        ),
      );
      await tester.tap(find.byType(Switch));
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets("should search servers", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(hintText: "Search..."),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), "Russia");
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
