// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// Web Speech API requires dart:html — only used on web platforms.
// When package:web becomes available in the SDK, migrate to it.

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
  static void speak(
    String text, {
    String lang = 'en-US',
    double rate = 0.9,
  }) {
    if (!isSupported) return;

    try {
      // Cancel any ongoing speech to avoid overlapping
      html.window.speechSynthesis!.cancel();

      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = lang;
      utterance.rate = rate;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;

      html.window.speechSynthesis!.speak(utterance);
    } catch (e) {
      // Silently fail — speech is a non-critical feature
    }
  }

  /// Stop any ongoing speech immediately.
  static void stop() {
    if (!isSupported) return;
    try {
      html.window.speechSynthesis!.cancel();
    } catch (_) {}
  }
}
