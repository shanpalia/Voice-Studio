import 'package:flutter_test/flutter_test.dart';
import 'package:voice_studio/main.dart';

void main() {
  testWidgets('Voice Studio opens the home screen', (tester) async {
    await tester.pumpWidget(const VoiceStudioApp());

    // Allow the branded splash (1.2s) and its fade transition (280ms)
    // to finish before checking the Home screen.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Voice Studio'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Translate'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);
  });
}
