
import 'package:flutter_test/flutter_test.dart';
import 'package:titipin_aja/main.dart';

void main() {
  testWidgets('TitipinAja berhasil ditampilkan', (WidgetTester tester) async {
    await tester.pumpWidget(const TitipinAja());

    expect(find.text('TitipinAja'), findsOneWidget);
  });
}
