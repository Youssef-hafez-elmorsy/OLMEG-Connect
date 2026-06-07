import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_admin_web/core/widgets/admin_scaffold.dart';

void main() {
  testWidgets('admin page navigation bar stays pinned while content scrolls',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminScaffold(
          title: 'Scrollable Admin Page',
          description: 'The page header should not permanently cover records.',
          icon: Icons.people_alt_outlined,
          child: ListView.builder(
            primary: true,
            itemCount: 40,
            itemBuilder: (context, index) => SizedBox(
              height: 72,
              child: Text('Record $index'),
            ),
          ),
        ),
      ),
    );

    final title = find.text('Scrollable Admin Page');
    final firstRecord = find.text('Record 0');
    expect(title, findsOneWidget);
    final initialTop = tester.getTopLeft(title).dy;
    expect(tester.getTopLeft(firstRecord).dy, lessThan(230));
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, 0);

    await tester.drag(firstRecord, const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(title).dy, initialTop);
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
