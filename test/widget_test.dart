import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeshop_app/core/theme/app_theme.dart';
import 'package:pokeshop_app/core/widgets/pk_button.dart';

void main() {
  testWidgets('PkButton renders and handles taps', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PkButton(
            label: 'Checkout',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('CHECKOUT'), findsOneWidget);
    await tester.tap(find.text('CHECKOUT'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
