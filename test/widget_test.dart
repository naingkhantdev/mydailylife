import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mdr/widgets/app_drawer.dart';

void main() {
  testWidgets('drawer navigates to a top-level destination smoothly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        routes: {
          AppRoutes.home: (_) => const _DrawerTestPage(
                title: 'Today page',
                route: AppRoutes.home,
              ),
          AppRoutes.dashboard: (_) => const _DrawerTestPage(
                title: 'Dashboard page',
                route: AppRoutes.dashboard,
              ),
        },
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Cloud sync active'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard page'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('selecting the current destination only closes the drawer',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        routes: {
          AppRoutes.home: (_) => const _DrawerTestPage(
                title: 'Today page',
                route: AppRoutes.home,
              ),
        },
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Today page'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });
}

class _DrawerTestPage extends StatelessWidget {
  const _DrawerTestPage({required this.title, required this.route});

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: AppDrawer(currentRoute: route),
    );
  }
}
