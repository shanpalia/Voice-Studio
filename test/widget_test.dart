import 'package:flutter_test/flutter_test.dart';
import 'package:voice_studio/main.dart';

void main() {
  testWidgets('Voice Studio opens the home screen', (tester) async {
    await tester.pumpWidget(const VoiceStudioApp());

    // SplashPage intentionally stays visible for about 1.2 seconds.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    expect(find.text('Voice Studio'), findsWidgets);
    expect(find.text('Voice Studio\nby PaliaAPK HUB'), findsOneWidget);
    expect(find.text('Translate'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
