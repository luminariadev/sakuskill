import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuskill_mobile/core/constants/campus_constants.dart';
import 'package:sakuskill_mobile/features/services/presentation/widgets/category_chips_bar.dart';

void main() {
  testWidgets('CategoryChipsBar renders all campus categories and handles tap', (WidgetTester tester) async {
    ServiceCategory? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CategoryChipsBar(
                selectedCategory: selected,
                onSelected: (cat) => setState(() => selected = cat),
              );
            },
          ),
        ),
      ),
    );

    // Verify chips render
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('IT & Troubleshoot'), findsOneWidget);
    expect(find.text('Desain Grafis'), findsOneWidget);

    // Tap on 'IT & Troubleshoot'
    await tester.tap(find.text('IT & Troubleshoot'));
    await tester.pumpAndSettle();

    expect(selected, ServiceCategory.itSupport);
  });
}
