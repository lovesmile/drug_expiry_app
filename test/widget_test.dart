import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expiry_tracker/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpiryTrackerApp());
    expect(find.byType(ExpiryTrackerApp), findsOneWidget);
  });
}
