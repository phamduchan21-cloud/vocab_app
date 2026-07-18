import 'package:flutter/foundation.dart';

class AuthConfig {
  static const String mobileCallbackUrl =
      'com.vocabapp.vocab_app://login-callback/';

  static String get oauthRedirectUrl {
    if (!kIsWeb) return mobileCallbackUrl;
    return '${Uri.base.origin}/';
  }

  static String get passwordRecoveryRedirectUrl {
    if (!kIsWeb) return mobileCallbackUrl;
    return '${Uri.base.origin}/#/login';
  }
}
