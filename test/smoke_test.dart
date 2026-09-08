import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/main.dart';

void main() {
  testWidgets('the app builds', (tester) async {
    await tester.pumpWidget(const WizCtlApp());
    expect(find.text('WizCtl'), findsOneWidget);
  });
}
