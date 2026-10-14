import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'models.dart';
import 'speech_script.dart';
import 'strings.dart';
import 'theme.dart';

/// Says one part aloud. Separate from [Narrator] so tests can listen in.
abstract interface class Speaker {
  /// Plays the recorded [clip] (an asset path under `assets/`) when given,
  /// otherwise speaks [text] with a device voice. Completes when the part
  /// finishes or is stopped.
  Future<void> say(String text, AppLanguage language, {String? clip});
  Future<void> stop();
}

/// Recorded clips first; the device's built-in voices for anything else.
class DeviceSpeaker implements Speaker {
  final _tts = FlutterTts();
  final _player = AudioPlayer();
  late final Future<void> _ready = _setUp();
  Completer<void>? _part;

  Future<void> _setUp() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setSharedInstance(true);
      // Plays even with the silent switch on, and lowers other audio.
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ], IosTextToSpeechAudioMode.spokenAudio);
    }
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.duckOthers).build(),
    );
    await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
    _tts
      ..setCompletionHandler(_finish)
      ..setCancelHandler(_finish)
      ..setErrorHandler((_) => _finish());
    _player.onPlayerComplete.listen((_) => _finish());
  }

  void _finish() {
    final part = _part;
    _part = null;
    if (part != null && !part.isCompleted) part.complete();
  }

  @override
  Future<void> say(String text, AppLanguage language, {String? clip}) async {
    try {
      await _ready;
      _finish();
      final part = _part = Completer<void>();
      if (clip != null) {
        await _player.play(AssetSource(clip));
      } else {
        // Latin American Spanish, matching the app's written Spanish.
        await _tts.setLanguage(language == AppLanguage.en ? 'en-US' : 'es-MX');
        await _tts.speak(text);
      }
      await part.future;
      // A short breath between parts gives the reading a natural rhythm.
      await Future<void>.delayed(const Duration(milliseconds: 220));
    } catch (_) {
      // Speech is an extra; a missing voice must never break exploring.
      _finish();
    }
  }

  @override
  Future<void> stop() async {
    _finish();
    try {
      await _ready;
      await Future.wait([_tts.stop(), _player.stop()]);
    } catch (_) {}
  }
}

/// Keys of the recorded clips bundled in `assets/audio/`.
Future<Set<String>> loadClipIndex() async {
  try {
    final index = jsonDecode(
      await rootBundle.loadString('assets/audio/index.json'),
    );
    return {for (final key in index['clips'] as List<dynamic>) key as String};
  } catch (_) {
    return {};
  }
}

/// Which text is being read, and whether new content is read automatically.
class Narrator extends ChangeNotifier {
  Narrator(this._speaker, {Future<Set<String>>? clips})
    : _clips = clips ?? loadClipIndex();
  final Speaker _speaker;
  final Future<Set<String>> _clips;
  String? speakingId;
  bool autoRead = false;
  int _run = 0;

  /// Reads [parts] in order, using a recorded clip for each when available.
  Future<void> say(String id, List<String> parts, AppLanguage language) async {
    final run = ++_run;
    // Claim [id] before waiting, so a pending [release] of the previous text
    // sees that something newer has started and leaves it alone.
    speakingId = id;
    notifyListeners();
    await _speaker.stop();
    final clips = await _clips;
    for (final part in parts) {
      if (run != _run) return;
      final key = speechKey(language, part);
      await _speaker.say(
        forSpeech(part, language),
        language,
        clip: clips.contains(key) ? 'audio/$key.m4a' : null,
      );
    }
    if (run == _run) {
      speakingId = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _run++;
    if (speakingId == null) return;
    speakingId = null;
    notifyListeners();
    await _speaker.stop();
  }

  /// Stops [id] after the current frame, unless something else has started.
  /// Safe to call while widgets are building or being removed.
  void release(String id) => scheduleMicrotask(() {
    if (speakingId == id) unawaited(stop());
  });

  void toggleAutoRead() {
    autoRead = !autoRead;
    if (!autoRead) unawaited(stop());
    notifyListeners();
  }
}

/// A "Listen" button for some text. With read-aloud on, the text is also
/// spoken as soon as it appears or changes ([id] should change with it).
class ListenButton extends StatefulWidget {
  const ListenButton({
    super.key,
    required this.id,
    required this.parts,
    required this.language,
    required this.narrator,
  });
  final String id;
  final List<String> parts;
  final AppLanguage language;
  final Narrator narrator;
  @override
  State<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<ListenButton> {
  @override
  void initState() {
    super.initState();
    _autoRead();
  }

  @override
  void didUpdateWidget(ListenButton old) {
    super.didUpdateWidget(old);
    if (old.id == widget.id) return;
    widget.narrator.release(old.id);
    _autoRead();
  }

  @override
  void dispose() {
    widget.narrator.release(widget.id);
    super.dispose();
  }

  void _autoRead() {
    if (!widget.narrator.autoRead) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.narrator.autoRead) {
        unawaited(
          widget.narrator.say(widget.id, widget.parts, widget.language),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.narrator,
    builder: (context, _) {
      final s = Strings(widget.language);
      final speaking = widget.narrator.speakingId == widget.id;
      return TextButton.icon(
        onPressed: () => speaking
            ? widget.narrator.stop()
            : widget.narrator.say(widget.id, widget.parts, widget.language),
        style: TextButton.styleFrom(
          foregroundColor: forest,
          backgroundColor: speaking ? mint : Colors.transparent,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          speaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
          size: 22,
        ),
        label: Text(
          speaking ? s.stopListening : s.listen,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    },
  );
}
