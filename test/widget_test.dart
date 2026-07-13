import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mdr/main.dart';

void main() {
  testWidgets('RoutineSync home renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('RoutineSync'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
  });
}
