// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:acil_durum_app/main.dart';

void main() {
  testWidgets('Emergency app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our app starts with emergency page
    expect(find.text('Acil Yardım'), findsOneWidget);
    expect(find.text('ACİL DURUM ÇAĞRI SİSTEMİ'), findsOneWidget);

    // Tap the announcements tab and verify navigation
    await tester.tap(find.text('Duyurular'));
    await tester.pump();

    // Verify we're now on announcements page
    expect(find.text('Duyurular yükleniyor...'), findsOneWidget);
  });
}
