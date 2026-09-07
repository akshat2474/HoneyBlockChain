import 'package:flutter_test/flutter_test.dart';
import 'package:honey_chain/main.dart';

void main() {
  testWidgets('Honey Chain opens its landing experience', (tester) async {
    await tester.pumpWidget(const HoneyChainApp());

    expect(find.text('Honey Chain'), findsWidgets);
  });
}
