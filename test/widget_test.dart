import 'package:flutter_test/flutter_test.dart';
import 'package:voice_studio/main.dart';

void main() {
  test('Voice Studio configuration is valid', () {
    expect(currentVersion, '1.2.0');
    expect(appStoreUrl, contains('shanpalia.github.io/WebsitePaliaAPK_V.2'));
    expect(versionUrl, contains('/voice-studio/version.json'));
  });
}
