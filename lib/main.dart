import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

const mint = Color(0xFF12C9A0);
const dark = Color(0xFF102A43);
const currentVersion = '1.0.0';
const appStoreUrl = 'https://shanpalia.github.io/WebsitePaliaAPK_V.2/';
const versionUrl = 'https://shanpalia.github.io/WebsitePaliaAPK_V.2/voice-studio/version.json';

void main() => runApp(const VoiceStudioApp());

class VoiceStudioApp extends StatelessWidget {
  const VoiceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Studio',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FFFC),
        colorScheme: ColorScheme.fromSeed(seedColor: mint),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final input = TextEditingController();
  final output = TextEditingController();
  final tts = FlutterTts();
  final speech = stt.SpeechToText();

  String from = 'en';
  String to = 'hi';
  bool listening = false;
  bool busy = false;
  int selectedIndex = 0;

  @override
  void dispose() {
    input.dispose();
    output.dispose();
    tts.stop();
    speech.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    if (listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }

    final ok = await speech.initialize(
      onStatus: (status) {
        if (status == 'done' && mounted) {
          setState(() => listening = false);
        }
      },
    );
    if (!ok) return;

    setState(() => listening = true);
    await speech.listen(
      localeId: from == 'hi' ? 'hi-IN' : 'en-IN',
      onResult: (result) {
        input.text = result.recognizedWords;
        input.selection = TextSelection.collapsed(offset: input.text.length);
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _translate() async {
    if (input.text.trim().isEmpty) return;

    setState(() => busy = true);
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeQueryComponent(input.text)}&langpair=$from|$to',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      output.text = '${data['responseData']?['translatedText'] ?? ''}';
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translation service unavailable. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _speak({double pitch = 1.0}) async {
    if (output.text.trim().isEmpty) return;
    await tts.setLanguage(_ttsLocale(to));
    await tts.setSpeechRate(0.46);
    await tts.setPitch(pitch);
    await tts.speak(output.text);
  }

  Future<void> _downloadAudio() async {
    if (output.text.trim().isEmpty) return;
    try {
      await tts.setLanguage(_ttsLocale(to));
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/voice_studio_${DateTime.now().millisecondsSinceEpoch}.wav';
      await tts.synthesizeToFile(output.text, filePath, true);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(text: 'Voice Studio audio', files: [XFile(filePath)]),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio could not be generated.')),
        );
      }
    }
  }

  String _ttsLocale(String language) {
    switch (language) {
      case 'hi':
        return 'hi-IN';
      case 'bn':
        return 'bn-IN';
      case 'mr':
        return 'mr-IN';
      case 'gu':
        return 'gu-IN';
      case 'ta':
        return 'ta-IN';
      case 'te':
        return 'te-IN';
      case 'pa':
        return 'pa-IN';
      case 'ur':
        return 'ur-IN';
      case 'es':
        return 'es-ES';
      default:
        return 'en-US';
    }
  }

  Future<void> _openStore() async {
    final uri = Uri.parse(appStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkUpdate() async {
    try {
      final response = await http.get(Uri.parse(versionUrl)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = '${data['version'] ?? currentVersion}';
      final store = '${data['storeUrl'] ?? appStoreUrl}';
      final newer = _isNewerVersion(latest, currentVersion);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(newer ? 'New update available' : 'You\'re up to date'),
          content: Text(
            newer
                ? 'Voice Studio $latest is available. Open PaliaAPK HUB to update.'
                : 'You are using the latest version of Voice Studio ($currentVersion).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Later'),
            ),
            if (newer)
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final uri = Uri.parse(store);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now'),
              ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check for updates.')),
        );
      }
    }
  }

  bool _isNewerVersion(String latest, String installed) {
    List<int> parts(String value) => value
        .replaceFirst(RegExp(r'^v', caseSensitive: false), '')
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9].*'), '')) ?? 0)
        .toList();

    final a = parts(latest);
    final b = parts(installed);
    for (var i = 0; i < 3; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av > bv;
    }
    return false;
  }

  void _selectTab(int index) {
    setState(() => selectedIndex = index);
  }

  Future<bool> _handleBack() async {
    if (selectedIndex != 0) {
      setState(() => selectedIndex = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedIndex != 0) {
          setState(() => selectedIndex = 0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Studio', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              onPressed: _checkUpdate,
              tooltip: 'Check for Update',
              icon: const Icon(Icons.system_update_alt),
            ),
            IconButton(
              onPressed: _openStore,
              tooltip: 'More Apps',
              icon: const Icon(Icons.apps_rounded),
            ),
          ],
        ),
        body: IndexedStack(
          index: selectedIndex,
          children: [
            _homeView(),
            _translateView(),
            _voiceView(),
            _historyView(),
            _settingsView(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.translate), label: 'Translate'),
            NavigationDestination(icon: Icon(Icons.mic_none), label: 'Voice'),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _homeView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Translate • Speak • Listen • Create', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              FeatureCard(icon: Icons.translate, title: 'Translate Text'),
              FeatureCard(icon: Icons.mic, title: 'Speak to Type'),
              FeatureCard(icon: Icons.record_voice_over, title: 'Text to Voice'),
              FeatureCard(icon: Icons.swap_calls, title: 'Voice to Voice'),
            ],
          ),
          const SizedBox(height: 16),
          _panel(
            'Enter Text',
            TextField(
              controller: input,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type or paste your text here...',
                suffixIcon: IconButton(
                  onPressed: _listen,
                  icon: Icon(listening ? Icons.stop_circle : Icons.mic),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _lang(from, (value) => setState(() => from = value))),
              IconButton(
                onPressed: () => setState(() {
                  final old = from;
                  from = to;
                  to = old;
                }),
                icon: const Icon(Icons.swap_horiz),
              ),
              Expanded(child: _lang(to, (value) => setState(() => to = value))),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : _translate,
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.translate),
              label: Text(busy ? 'Translating…' : 'Translate'),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            'Output',
            TextField(
              controller: output,
              maxLines: 4,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Translated text appears here...',
                suffixIcon: IconButton(
                  onPressed: () => _speak(),
                  icon: const Icon(Icons.play_circle_fill),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _voiceStudioPanel(),
          const SizedBox(height: 22),
          _branding(),
        ],
      ),
    );
  }

  Widget _translateView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Translate', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: dark)),
          const SizedBox(height: 12),
          _panel('Source', TextField(controller: input, maxLines: 7, decoration: const InputDecoration(hintText: 'Enter text...'))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _lang(from, (value) => setState(() => from = value))), const SizedBox(width: 8), Expanded(child: _lang(to, (value) => setState(() => to = value)))]),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: busy ? null : _translate, icon: const Icon(Icons.translate), label: const Text('Translate')),
          const SizedBox(height: 12),
          _panel('Result', TextField(controller: output, maxLines: 7, readOnly: true)),
        ],
      ),
    );
  }

  Widget _voiceView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Voice Studio', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: dark)),
          const SizedBox(height: 12),
          _panel('Text to Voice', TextField(controller: output, maxLines: 7, decoration: const InputDecoration(hintText: 'Enter or translate text first...'))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _voiceCard('Male Voice', Icons.man, 0.85)), const SizedBox(width: 10), Expanded(child: _voiceCard('Female Voice', Icons.woman, 1.15))]),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _downloadAudio, icon: const Icon(Icons.download), label: const Text('Download / Share Audio')),
        ],
      ),
    );
  }

  Widget _historyView() {
    return SafeArea(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.history, size: 56, color: mint),
          SizedBox(height: 12),
          Text('No generated audio yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Your future voice clips will appear here.'),
        ]),
      ),
    );
  }

  Widget _settingsView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: dark)),
          const SizedBox(height: 16),
          _settingsCard(
            icon: Icons.system_update_alt,
            title: 'Check for Update',
            subtitle: 'Current version $currentVersion',
            onTap: _checkUpdate,
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 10),
          _settingsCard(
            icon: Icons.apps_rounded,
            title: 'More Apps',
            subtitle: 'Explore apps from PaliaAPK HUB',
            onTap: _openStore,
            trailing: const Icon(Icons.open_in_new),
          ),
          const SizedBox(height: 10),
          _settingsCard(
            icon: Icons.info_outline,
            title: 'About Voice Studio',
            subtitle: 'Translate • Speak • Listen • Create',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Voice Studio',
              applicationVersion: currentVersion,
              applicationLegalese: 'Branding by PaliaAPK HUB • Developer by shanpalia',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 28),
          _branding(),
        ],
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: mint.withValues(alpha: 0.12), child: Icon(icon, color: mint)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  Widget _voiceStudioPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Voice Studio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: dark)),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _voiceCard('Male Voice', Icons.man, 0.85)), const SizedBox(width: 10), Expanded(child: _voiceCard('Female Voice', Icons.woman, 1.15))]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _downloadAudio, icon: const Icon(Icons.download), label: const Text('Download / Share Audio'))),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 8), child]),
    );
  }

  Widget _lang(String code, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: code,
      decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
        DropdownMenuItem(value: 'hi', child: Text('🇮🇳 Hindi')),
        DropdownMenuItem(value: 'bn', child: Text('🇮🇳 Bengali')),
        DropdownMenuItem(value: 'mr', child: Text('🇮🇳 Marathi')),
        DropdownMenuItem(value: 'gu', child: Text('🇮🇳 Gujarati')),
        DropdownMenuItem(value: 'ta', child: Text('🇮🇳 Tamil')),
        DropdownMenuItem(value: 'te', child: Text('🇮🇳 Telugu')),
        DropdownMenuItem(value: 'pa', child: Text('🇮🇳 Punjabi')),
        DropdownMenuItem(value: 'ur', child: Text('🇮🇳 Urdu')),
        DropdownMenuItem(value: 'es', child: Text('🇪🇸 Spanish')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _voiceCard(String title, IconData icon, double pitch) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF2FFFB), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: mint.withValues(alpha: 0.15), child: Icon(icon, color: mint)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(onPressed: () => _speak(pitch: pitch), icon: const Icon(Icons.play_circle_fill, color: mint)),
        ],
      ),
    );
  }

  Widget _branding() {
    return const Center(
      child: Column(
        children: [
          Text('Branding by PaliaAPK HUB', style: TextStyle(fontWeight: FontWeight.w700, color: mint)),
          Text('Developer by shanpalia', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const FeatureCard({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 12)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 2),
          Icon(icon, size: 34, color: mint),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
