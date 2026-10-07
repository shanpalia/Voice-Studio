import 'dart:async';
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
const page = Color(0xFFF6FBF9);
const currentVersion = '1.0.0';
const appStoreUrl = 'https://shanpalia.github.io/WebsitePaliaAPK_V.2/';
const versionUrl =
    'https://shanpalia.github.io/WebsitePaliaAPK_V.2/voice-studio/version.json';

void main() => runApp(const VoiceStudioApp());

class VoiceStudioApp extends StatelessWidget {
  const VoiceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: mint,
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Studio',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: page,
        fontFamily: 'sans',
        appBarTheme: const AppBarTheme(
          backgroundColor: page,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FCFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Color(0xFFE2ECE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: mint, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: mint,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2212C9A0),
                        blurRadius: 30,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Voice Studio',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: dark,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Translate • Speak • Listen • Create',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 34),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: mint,
                  ),
                ),
                const SizedBox(height: 52),
                const Text(
                  'Branding by PaliaAPK HUB',
                  style: TextStyle(
                    color: mint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Developer by shanpalia',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  bool speaking = false;
  int selectedIndex = 0;
  String activeVoice = 'female';
  final List<String> history = [];

  static const languages = <String, String>{
    'en': 'English',
    'hi': 'Hindi',
    'bn': 'Bengali',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'ta': 'Tamil',
    'te': 'Telugu',
    'pa': 'Punjabi',
    'ur': 'Urdu',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'ar': 'Arabic',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
  };

  @override
  void initState() {
    super.initState();
    tts.setCompletionHandler(() {
      if (mounted) setState(() => speaking = false);
    });
    tts.setCancelHandler(() {
      if (mounted) setState(() => speaking = false);
    });
    tts.setErrorHandler((_) {
      if (mounted) setState(() => speaking = false);
    });
  }

  @override
  void dispose() {
    input.dispose();
    output.dispose();
    tts.stop();
    speech.stop();
    super.dispose();
  }

  Future<String?> _speechLocale() async {
    final locales = await speech.locales();
    final wanted = _localePrefix(from);
    final exact = locales.where((l) => l.localeId.toLowerCase() == wanted.toLowerCase());
    if (exact.isNotEmpty) return exact.first.localeId;
    final sameLanguage = locales.where(
      (l) => l.localeId.toLowerCase().startsWith('$wanted-'),
    );
    return sameLanguage.isNotEmpty ? sameLanguage.first.localeId : null;
  }

  Future<bool> _startSpeech({bool autoStop = false}) async {
    final available = await speech.initialize(
      debugLogging: true,
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => listening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => listening = false);
        _showMessage(error.errorMsg.isEmpty
            ? 'Speech recognition failed.'
            : 'Speech recognition: ${error.errorMsg}');
      },
    );

    if (!available) {
      if (mounted) {
        _showMessage(
          'Speech recognition is not available. Check microphone and speech permissions.',
        );
      }
      return false;
    }

    final localeId = await _speechLocale();
    if (mounted) setState(() => listening = true);

    await speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 5),
        enableHapticFeedback: true,
      ),
      onResult: (result) {
        input.text = result.recognizedWords;
        input.selection = TextSelection.collapsed(offset: input.text.length);
        if (mounted) setState(() {});
        if (autoStop && result.finalResult) {
          speech.stop();
        }
      },
    );
    return true;
  }

  Future<void> _listen() async {
    if (listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    await _startSpeech();
  }

  Future<void> _voiceToVoice() async {
    if (listening) return;
    final started = await _startSpeech(autoStop: true);
    if (!started) return;
    if (!mounted) return;

    _showMessage('Speak now. Voice Studio will translate and speak the result.');
    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (mounted && DateTime.now().isBefore(deadline)) {
        if (!listening && input.text.trim().isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      await speech.stop();
      if (input.text.trim().isEmpty) return;
      await _translate();
      if (output.text.trim().isNotEmpty) {
        await _speak(voice: activeVoice);
      }
    } catch (_) {
      if (mounted) _showMessage('Voice-to-voice could not be completed.');
    }
  }

  Future<void> _translate() async {
    if (input.text.trim().isEmpty) {
      _showMessage('Enter or speak some text first.');
      return;
    }
    setState(() => busy = true);
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeQueryComponent(input.text)}&langpair=$from|$to',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final translated = '${data['responseData']?['translatedText'] ?? ''}'.trim();
      if (translated.isEmpty) throw Exception('Empty translation');
      output.text = translated;
      history.insert(0, translated);
      if (history.length > 20) history.removeLast();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _showMessage('Translation service unavailable. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _speak({String voice = 'female'}) async {
    final text = output.text.trim().isEmpty ? input.text.trim() : output.text.trim();
    if (text.isEmpty) {
      _showMessage('Enter some text first.');
      return;
    }

    final pitch = voice == 'male' ? 0.72 : 1.22;
    final rate = voice == 'male' ? 0.43 : 0.47;
    activeVoice = voice;
    await tts.stop();
    await tts.setLanguage(_ttsLocale(to));
    await _selectSystemVoice(voice, _ttsLocale(to));
    await tts.setSpeechRate(rate);
    await tts.setPitch(pitch);
    await tts.setVolume(1.0);
    if (mounted) setState(() => speaking = true);
    await tts.speak(text);
  }

  Future<void> _selectSystemVoice(String gender, String locale) async {
    try {
      final raw = await tts.getVoices;
      if (raw is! List) return;
      final voices = raw
          .whereType<Map>()
          .map((voice) => Map<String, dynamic>.from(voice))
          .where((voice) => (voice['locale'] ?? '')
              .toString()
              .toLowerCase()
              .startsWith(locale.split('-').first.toLowerCase()))
          .toList();

      if (voices.isEmpty) return;

      final keywords = gender == 'male'
          ? ['male', 'man', 'david', 'alex', 'daniel', 'george', 'ravi']
          : ['female', 'woman', 'samantha', 'karen', 'sara', 'zira', 'neerja'];

      Map<String, dynamic>? selected;
      for (final voice in voices) {
        final name = (voice['name'] ?? '').toString().toLowerCase();
        if (keywords.any(name.contains)) {
          selected = voice;
          break;
        }
      }
      selected ??= voices.first;

      final clean = <String, String>{};
      selected.forEach((key, value) {
        if (value != null) clean[key.toString()] = value.toString();
      });
      if (clean.containsKey('name') && clean.containsKey('locale')) {
        await tts.setVoice(clean);
      }
    } catch (_) {
      // Pitch remains as the reliable fallback when the Android TTS engine
      // does not expose separate gender-labelled voices.
    }
  }

  Future<void> _downloadAudio() async {
    final text = output.text.trim().isEmpty ? input.text.trim() : output.text.trim();
    if (text.isEmpty) {
      _showMessage('Enter or translate text before creating audio.');
      return;
    }
    try {
      await tts.stop();
      await tts.setLanguage(_ttsLocale(to));
      await _selectSystemVoice(activeVoice, _ttsLocale(to));
      await tts.setPitch(activeVoice == 'male' ? 0.72 : 1.22);
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/voice_studio_${DateTime.now().millisecondsSinceEpoch}.wav';
      await tts.synthesizeToFile(text, filePath, true);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: 'Voice Studio • ${activeVoice == 'male' ? 'Male' : 'Female'} voice',
          files: [XFile(filePath)],
        ),
      );
    } catch (_) {
      if (mounted) _showMessage('Audio could not be generated.');
    }
  }

  String _localePrefix(String code) {
    switch (code) {
      case 'hi': return 'hi-IN';
      case 'bn': return 'bn-IN';
      case 'mr': return 'mr-IN';
      case 'gu': return 'gu-IN';
      case 'ta': return 'ta-IN';
      case 'te': return 'te-IN';
      case 'pa': return 'pa-IN';
      case 'ur': return 'ur-IN';
      case 'es': return 'es-ES';
      case 'fr': return 'fr-FR';
      case 'de': return 'de-DE';
      case 'ar': return 'ar-SA';
      case 'pt': return 'pt-BR';
      case 'ru': return 'ru-RU';
      case 'ja': return 'ja-JP';
      case 'ko': return 'ko-KR';
      case 'zh': return 'zh-CN';
      default: return 'en-IN';
    }
  }

  String _ttsLocale(String language) => _localePrefix(language);

  Future<void> _openStore() async {
    final uri = Uri.parse(appStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkUpdate() async {
    try {
      final response =
          await http.get(Uri.parse(versionUrl)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = '${data['version'] ?? currentVersion}';
      final store = '${data['storeUrl'] ?? appStoreUrl}';
      final newer = _isNewerVersion(latest, currentVersion);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(newer ? 'New update available' : 'You’re up to date'),
          content: Text(
            newer
                ? 'Voice Studio $latest is available on PaliaAPK HUB.'
                : 'Voice Studio $currentVersion is the latest version.',
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
      if (mounted) _showMessage('Could not check for updates.');
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(message),
        ),
      );
  }

  void _selectTab(int index) => setState(() => selectedIndex = index);

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
          toolbarHeight: 72,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Studio',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: dark,
                    ),
                  ),
                  Text(
                    'Translate • Speak • Create',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _checkUpdate,
              tooltip: 'Check for Update',
              icon: const Icon(Icons.system_update_alt_rounded),
            ),
            IconButton(
              onPressed: _openStore,
              tooltip: 'More Apps',
              icon: const Icon(Icons.grid_view_rounded),
            ),
            const SizedBox(width: 8),
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
          height: 76,
          selectedIndex: selectedIndex,
          onDestinationSelected: _selectTab,
          backgroundColor: const Color(0xFFEEF6F2),
          indicatorColor: const Color(0xFFD2F2E7),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(icon: Icon(Icons.translate_rounded), label: 'Translate'),
            NavigationDestination(icon: Icon(Icons.mic_none_rounded), label: 'Voice'),
            NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _homeView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _hero(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _quickAction(Icons.translate_rounded, 'Translate', () => _selectTab(1))),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(Icons.mic_rounded, 'Speak to Type', _listen)),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(Icons.record_voice_over_rounded, 'Text to Voice', () => _selectTab(2))),
            ],
          ),
          const SizedBox(height: 18),
          _editorPanel(),
          const SizedBox(height: 14),
          _outputPanel(),
          const SizedBox(height: 14),
          _voiceStudioPanel(),
          const SizedBox(height: 22),
          _branding(),
        ],
      ),
    );
  }

  Widget _hero() => Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF123B52), Color(0xFF176A67)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your voice,
your language.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Translate, speak and create voice clips in one place.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .78),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: mint, size: 40),
            ),
          ],
        ),
      );

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4EEE9)),
          ),
          child: Column(
            children: [
              Icon(icon, color: mint, size: 24),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark),
              ),
            ],
          ),
        ),
      );

  Widget _editorPanel() => _surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark)),
            const SizedBox(height: 4),
            const Text('Type, paste or use your microphone.', style: TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: input,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'e.g. mera new app aaya hai',
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: IconButton.filledTonal(
                    onPressed: _listen,
                    tooltip: listening ? 'Stop listening' : 'Speak to type',
                    icon: Icon(
                      listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: listening ? Colors.redAccent : mint,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _lang(from, (v) => setState(() => from = v))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Icon(Icons.swap_horiz_rounded, color: Colors.black54),
                ),
                Expanded(child: _lang(to, (v) => setState(() => to = v))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : _translate,
                style: FilledButton.styleFrom(
                  backgroundColor: dark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.translate_rounded),
                label: Text(busy ? 'Translating…' : 'Translate'),
              ),
            ),
          ],
        ),
      );

  Widget _outputPanel() => _surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Translated result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark)),
                ),
                if (speaking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: mint),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: output,
              readOnly: true,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Your translated text will appear here.',
                suffixIcon: IconButton(
                  onPressed: () => _speak(voice: activeVoice),
                  icon: const Icon(Icons.play_circle_fill_rounded, color: mint, size: 30),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _translateView() => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            _sectionTitle('Translate', 'Convert text between multiple languages.'),
            const SizedBox(height: 14),
            _editorPanel(),
            const SizedBox(height: 14),
            _outputPanel(),
          ],
        ),
      );

  Widget _voiceView() => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            _sectionTitle('Voice Studio', 'Choose a voice, preview it, then create your audio.'),
            const SizedBox(height: 14),
            _surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Text to Voice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: output,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(hintText: 'Enter or translate text first...'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _voiceCard('Male', Icons.person_rounded, 'male')),
                      const SizedBox(width: 10),
                      Expanded(child: _voiceCard('Female', Icons.person_4_rounded, 'female')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _downloadAudio,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: mint),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.download_rounded, color: mint),
                      label: const Text('Create & Share Audio'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _voiceToVoiceCard(),
          ],
        ),
      );

  Widget _voiceToVoiceCard() => _surface(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: const Color(0xFFE6F8F2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.sync_alt_rounded, color: mint),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice to Voice', style: TextStyle(fontWeight: FontWeight.w800, color: dark)),
                  SizedBox(height: 3),
                  Text('Speak → translate → hear', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: _voiceToVoice,
              icon: const Icon(Icons.play_arrow_rounded, color: mint),
            ),
          ],
        ),
      );

  Widget _historyView() => SafeArea(
        child: history.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(color: Color(0xFFE6F8F2), shape: BoxShape.circle),
                        child: const Icon(Icons.history_rounded, color: mint, size: 38),
                      ),
                      const SizedBox(height: 16),
                      const Text('No history yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: dark)),
                      const SizedBox(height: 6),
                      const Text('Your translated results will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: history.length,
                itemBuilder: (_, index) => _surface(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE6F8F2),
                      child: Icon(Icons.translate_rounded, color: mint),
                    ),
                    title: Text(history[index], maxLines: 3, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      onPressed: () {
                        output.text = history[index];
                        setState(() => selectedIndex = 2);
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, color: mint),
                    ),
                  ),
                ),
              ),
      );

  Widget _settingsView() => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            _sectionTitle('Settings', 'App updates, links and information.'),
            const SizedBox(height: 16),
            _settingsCard(
              icon: Icons.system_update_alt_rounded,
              title: 'Check for Update',
              subtitle: 'Version $currentVersion',
              onTap: _checkUpdate,
            ),
            _settingsCard(
              icon: Icons.grid_view_rounded,
              title: 'More Apps',
              subtitle: 'Explore PaliaAPK HUB',
              onTap: _openStore,
            ),
            _settingsCard(
              icon: Icons.info_outline_rounded,
              title: 'About Voice Studio',
              subtitle: 'Translate • Speak • Listen • Create',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Voice Studio',
                applicationVersion: currentVersion,
                applicationLegalese: 'Branding by PaliaAPK HUB • Developer by shanpalia',
              ),
            ),
            const SizedBox(height: 18),
            _branding(),
          ],
        ),
      );

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: const Color(0xFFE6F8F2), borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: mint),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: dark)),
                        const SizedBox(height: 3),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _voiceStudioPanel() => _surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Voice preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark)),
                ),
                Text(
                  activeVoice == 'male' ? 'Male selected' : 'Female selected',
                  style: const TextStyle(fontSize: 11, color: mint, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _voiceCard('Male', Icons.person_rounded, 'male')),
                const SizedBox(width: 10),
                Expanded(child: _voiceCard('Female', Icons.person_4_rounded, 'female')),
              ],
            ),
          ],
        ),
      );

  Widget _voiceCard(String title, IconData icon, String voice) {
    final selected = activeVoice == voice;
    return Material(
      color: selected ? const Color(0xFFE5F8F2) : const Color(0xFFF7FAF9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _speak(voice: voice),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? mint : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? mint : const Color(0xFFDDE8E3)),
                ),
                child: Icon(icon, color: selected ? Colors.white : dark),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: dark)),
              const SizedBox(height: 3),
              Text(
                selected ? 'Playing' : 'Tap to preview',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: dark)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      );

  Widget _surface({required Widget child, EdgeInsetsGeometry? margin}) => Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5EEE9)),
          boxShadow: const [
            BoxShadow(color: Color(0x09000000), blurRadius: 18, offset: Offset(0, 7)),
          ],
        ),
        child: child,
      );

  Widget _lang(String code, ValueChanged<String> onChanged) => DropdownButtonFormField<String>(
        initialValue: code,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.language_rounded, size: 19, color: mint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        ),
        items: languages.entries
            .map(
              (entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      );

  Widget _branding() => const Column(
        children: [
          Text(
            'Branding by PaliaAPK HUB',
            style: TextStyle(color: mint, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 3),
          Text('Developer by shanpalia', style: TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      );
}
