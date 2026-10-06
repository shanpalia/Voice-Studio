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
const appStoreUrl = 'https://shanpalia.github.io/WebsitePaliaAPK_V.2/';
const versionUrl = 'https://shanpalia.github.io/WebsitePaliaAPK_V.2/voice-studio/version.json';

void main() => runApp(const VoiceStudioApp());

class VoiceStudioApp extends StatelessWidget {
  const VoiceStudioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Voice Studio',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF7FFFC), colorScheme: ColorScheme.fromSeed(seedColor: mint)),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final input = TextEditingController();
  final output = TextEditingController();
  final tts = FlutterTts();
  final speech = stt.SpeechToText();
  String from = 'en', to = 'hi';
  bool listening = false, busy = false;

  Future<void> _listen() async {
    if (listening) { await speech.stop(); setState(() => listening = false); return; }
    final ok = await speech.initialize(onStatus: (s) { if (s == 'done' && mounted) setState(() => listening = false); });
    if (!ok) return;
    setState(() => listening = true);
    await speech.listen(localeId: from == 'hi' ? 'hi-IN' : 'en-IN', onResult: (r) {
      input.text = r.recognizedWords;
      input.selection = TextSelection.collapsed(offset: input.text.length);
      if (mounted) setState(() {});
    });
  }

  Future<void> _translate() async {
    if (input.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final uri = Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeQueryComponent(input.text)}&langpair=$from|$to');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      output.text = '${data['responseData']?['translatedText'] ?? ''}';
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Translation service unavailable. Please try again.')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _speak() async {
    if (output.text.trim().isEmpty) return;
    await tts.setLanguage(to == 'hi' ? 'hi-IN' : 'en-US');
    await tts.setSpeechRate(.46);
    await tts.speak(output.text);
  }

  Future<void> _downloadAudio() async {
    if (output.text.trim().isEmpty) return;
    try {
      await tts.setLanguage(to == 'hi' ? 'hi-IN' : 'en-US');
      final dir = await getApplicationDocumentsDirectory();
      final file = '${dir.path}/voice_studio_${DateTime.now().millisecondsSinceEpoch}.wav';
      await tts.synthesizeToFile(output.text, file, true);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(text: 'Voice Studio audio', files: [XFile(file)]));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio could not be generated.')));
    }
  }

  Future<void> _openStore() async { final u = Uri.parse(appStoreUrl); if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication); }

  Future<void> _checkUpdate() async {
    try {
      final r = await http.get(Uri.parse(versionUrl)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final latest = '${data['version'] ?? '1.0.0'}';
      final store = '${data['storeUrl'] ?? appStoreUrl}';
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text(latest == '1.0.0' ? 'You’re up to date' : 'New update available'),
        content: Text(latest == '1.0.0' ? 'You are using the latest version of Voice Studio.' : 'Voice Studio $latest is available. Open PaliaAPK HUB to update.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          if (latest != '1.0.0') FilledButton(onPressed: () async { Navigator.pop(context); final u=Uri.parse(store); if(await canLaunchUrl(u)) await launchUrl(u,mode:LaunchMode.externalApplication); }, child: const Text('Update Now')),
        ],
      ));
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not check for updates.'))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Voice Studio', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _checkUpdate, icon: const Icon(Icons.system_update_alt)), IconButton(onPressed: _openStore, icon: const Icon(Icons.apps_rounded))]),
    body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      const Text('Translate • Speak • Listen • Create', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 10, children: const [FeatureCard(icon: Icons.translate, title: 'Translate Text'), FeatureCard(icon: Icons.mic, title: 'Speak to Type'), FeatureCard(icon: Icons.record_voice_over, title: 'Text to Voice'), FeatureCard(icon: Icons.swap_calls, title: 'Voice to Voice')]),
      const SizedBox(height: 16),
      _panel('Enter Text', TextField(controller: input, maxLines: 4, decoration: InputDecoration(hintText: 'Type or paste your text here...', suffixIcon: IconButton(onPressed: _listen, icon: Icon(listening ? Icons.stop_circle : Icons.mic))))),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _lang(from, (v) => setState(() => from = v))), IconButton(onPressed: () => setState(() { final x=from; from=to; to=x; }), icon: const Icon(Icons.swap_horiz)), Expanded(child: _lang(to, (v) => setState(() => to = v)))]),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : _translate, icon: busy ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.translate), label: Text(busy ? 'Translating…' : 'Translate'))),
      const SizedBox(height: 16),
      _panel('Output', TextField(controller: output, maxLines: 4, readOnly: true, decoration: InputDecoration(hintText: 'Translated text appears here...', suffixIcon: IconButton(onPressed: _speak, icon: const Icon(Icons.play_circle_fill))))),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Voice Studio', style: TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:dark)), const SizedBox(height:12), Row(children: [Expanded(child: _voiceCard('Male Voice', Icons.man)), const SizedBox(width:10), Expanded(child: _voiceCard('Female Voice', Icons.woman))]), const SizedBox(height:12), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _downloadAudio, icon: const Icon(Icons.download), label: const Text('Download / Share Audio')))])),
      const SizedBox(height: 22),
      Center(child: Column(children: const [Text('Branding by PaliaAPK HUB', style: TextStyle(fontWeight: FontWeight.w700, color: mint)), Text('Developer by shanpalia', style: TextStyle(color: Colors.black54))]))
    ])),
    bottomNavigationBar: const NavigationBar(selectedIndex: 0, destinations: [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.translate), label: 'Translate'), NavigationDestination(icon: Icon(Icons.mic_none), label: 'Voice'), NavigationDestination(icon: Icon(Icons.history), label: 'History'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings')]),
  );

  Widget _panel(String title, Widget child) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize:16,fontWeight:FontWeight.w700)), const SizedBox(height:8), child]));
  Widget _lang(String code, ValueChanged<String> onChanged) => DropdownButtonFormField<String>(initialValue: code, decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)))), items: const [DropdownMenuItem(value:'en',child:Text('🇺🇸 English')),DropdownMenuItem(value:'hi',child:Text('🇮🇳 Hindi')),DropdownMenuItem(value:'bn',child:Text('🇮🇳 Bengali')),DropdownMenuItem(value:'mr',child:Text('🇮🇳 Marathi')),DropdownMenuItem(value:'gu',child:Text('🇮🇳 Gujarati')),DropdownMenuItem(value:'ta',child:Text('🇮🇳 Tamil')),DropdownMenuItem(value:'te',child:Text('🇮🇳 Telugu')),DropdownMenuItem(value:'pa',child:Text('🇮🇳 Punjabi')),DropdownMenuItem(value:'ur',child:Text('🇮🇳 Urdu')),DropdownMenuItem(value:'es',child:Text('🇪🇸 Spanish'))], onChanged:(v){if(v!=null)onChanged(v);});
  Widget _voiceCard(String title, IconData icon) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF2FFFB), borderRadius: BorderRadius.circular(18)), child: Row(children:[CircleAvatar(backgroundColor: mint.withOpacity(.15), child: Icon(icon,color:mint)), const SizedBox(width:8), Expanded(child:Text(title,style:const TextStyle(fontWeight:FontWeight.w700))), IconButton(onPressed:_speak,icon:const Icon(Icons.play_circle_fill,color:mint))]));
}

class FeatureCard extends StatelessWidget {
  final IconData icon; final String title;
  const FeatureCard({super.key,required this.icon,required this.title});
  @override Widget build(BuildContext c)=>Container(width: (MediaQuery.sizeOf(c).width-52)/2,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),boxShadow:const[BoxShadow(color:Color(0x10000000),blurRadius:12)]),child:Column(children:[Icon(icon,size:34,color:mint),const SizedBox(height:8),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w700))]);
}
