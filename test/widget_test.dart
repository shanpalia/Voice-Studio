import 'package:flutter_test/flutter_test.dart';

import 'package:voice_studio/main.dart';

void main() {
  testWidgets('Voice Studio starts on the home screen', (tester) async {
    await tester.pumpWidget(const VoiceStudioApp());

    expect(find.text('Voice Studio'), findsWidgets);
    expect(find.text('Translate • Speak • Listen • Create'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
