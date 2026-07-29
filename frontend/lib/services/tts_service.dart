// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// Web Speech API requires dart:html — only used on web platforms.
// When package:web becomes available in the SDK, migrate to it.

import 'dart:async';
import 'dart:html' as html;

/// Text-to-Speech service using Web Speech API (browser built-in).
///
/// Uses `window.speechSynthesis` available in Chrome, Edge, Safari.
/// No external API keys or packages required.
///
/// NOTE: This only works on Flutter Web. On mobile/desktop,
/// the [_checkSupport] will return false and buttons will hide.
class TtsService {
  static bool? _supported;
  static html.SpeechSynthesisUtterance? _activeUtterance;
  static final List<StreamSubscription<html.Event>> _activeSubscriptions = [];
  static int _requestId = 0;

  /// Whether the browser supports speech synthesis.
  static bool get isSupported {
    _supported ??= _checkSupport();
    return _supported!;
  }

  static bool _checkSupport() {
    try {
      return html.window.speechSynthesis != null;
    } catch (_) {
      return false;
    }
  }

  /// Speak the given [text] using the browser's speech synthesis.
  /// [lang] defaults to 'en-US' for English pronunciation.
  /// [rate] controls speed (0.1 to 10, default 0.9 for clear pronunciation).
  static Future<bool> speak(
    String text, {
    String lang = 'en-US',
    double rate = 0.9,
  }) async {
    final normalizedText = _normalizeText(text);
    if (!isSupported || normalizedText.isEmpty) return false;

    try {
      final synthesis = html.window.speechSynthesis!;
      final requestId = ++_requestId;
      _cancelActive(synthesis);

      // Chromium may drop an utterance queued in the same task as cancel().
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (requestId != _requestId) return false;

      if (synthesis.paused == true) synthesis.resume();
      final voice = await _findEnglishVoice(synthesis, lang);

      for (var attempt = 0; attempt < 2; attempt++) {
        if (requestId != _requestId) return false;
        final started = await _speakOnce(
          synthesis,
          normalizedText,
          lang: lang,
          rate: rate,
          voice: voice,
        );
        if (started) return true;

        synthesis.cancel();
        await Future<void>.delayed(
          Duration(milliseconds: attempt == 0 ? 140 : 0),
        );
      }
    } catch (_) {
      _clearActive();
    }
    return false;
  }

  /// Stop any ongoing speech immediately.
  static void stop() {
    _requestId++;
    if (!isSupported) return;
    try {
      _cancelActive(html.window.speechSynthesis!);
    } catch (_) {}
  }

  static Future<bool> _speakOnce(
    html.SpeechSynthesis synthesis,
    String text, {
    required String lang,
    required double rate,
    required html.SpeechSynthesisVoice? voice,
  }) async {
    final completer = Completer<bool>();
    final utterance = html.SpeechSynthesisUtterance(text)
      ..lang = voice?.lang ?? lang
      ..rate = rate.clamp(0.1, 2.0)
      ..pitch = 1.0
      ..volume = 1.0;
    if (voice != null) utterance.voice = voice;

    _clearActive();
    _activeUtterance = utterance;

    late final StreamSubscription<html.SpeechSynthesisEvent> startSubscription;
    late final StreamSubscription<html.Event> errorSubscription;
    late final StreamSubscription<html.SpeechSynthesisEvent> endSubscription;
    Timer? startTimer;

    void complete(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    void finishPlayback() {
      startTimer?.cancel();
      startSubscription.cancel();
      errorSubscription.cancel();
      endSubscription.cancel();
      _activeSubscriptions.clear();
      if (identical(_activeUtterance, utterance)) {
        _activeUtterance = null;
      }
    }

    startSubscription = utterance.onStart.listen((_) {
      startTimer?.cancel();
      complete(true);
    });
    errorSubscription = utterance.onError.listen((_) {
      complete(false);
      finishPlayback();
    });
    endSubscription = utterance.onEnd.listen((_) {
      // Very short words can finish before the start event is dispatched.
      complete(true);
      finishPlayback();
    });
    _activeSubscriptions
      ..add(startSubscription)
      ..add(errorSubscription)
      ..add(endSubscription);

    synthesis.speak(utterance);
    startTimer = Timer(const Duration(milliseconds: 850), () {
      final accepted = synthesis.speaking == true || synthesis.pending == true;
      complete(accepted);
      if (!accepted) finishPlayback();
    });

    return completer.future;
  }

  static Future<html.SpeechSynthesisVoice?> _findEnglishVoice(
    html.SpeechSynthesis synthesis,
    String lang,
  ) async {
    var voices = synthesis.getVoices();
    for (var attempt = 0; voices.isEmpty && attempt < 3; attempt++) {
      await Future<void>.delayed(Duration(milliseconds: 100 + attempt * 100));
      voices = synthesis.getVoices();
    }
    if (voices.isEmpty) return null;

    final requested = lang.toLowerCase();
    final englishVoices = voices
        .where((voice) => voice.lang?.toLowerCase().startsWith('en') == true)
        .toList();
    if (englishVoices.isEmpty) return null;

    int rank(html.SpeechSynthesisVoice voice) {
      final voiceLang = voice.lang?.toLowerCase() ?? '';
      final voiceName = voice.name?.toLowerCase() ?? '';
      var score = 0;
      if (voiceLang == requested) score += 100;
      if (voiceLang == 'en-us') score += 40;
      if (voice.defaultValue == true) score += 20;
      if (voice.localService == true) score += 10;
      if (voiceName.contains('google') ||
          voiceName.contains('microsoft') ||
          voiceName.contains('samantha')) {
        score += 5;
      }
      return score;
    }

    englishVoices.sort((a, b) => rank(b).compareTo(rank(a)));
    return englishVoices.first;
  }

  static String _normalizeText(String text) {
    return text
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static void _cancelActive(html.SpeechSynthesis synthesis) {
    synthesis.cancel();
    _clearActive();
  }

  static void _clearActive() {
    for (final subscription in _activeSubscriptions) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    _activeUtterance = null;
  }
}
