import 'package:flutter/foundation.dart';

class AuthConfig {
  static const String mobileCallbackUrl =
      'com.vocabapp.vocab_app://login-callback/';

  static String get oauthRedirectUrl {
    if (!kIsWeb) return mobileCallbackUrl;
    // Keep OAuth callbacks on a public route while Supabase restores the session.
    return '${Uri.base.origin}/#/login';
  }

  static String get passwordRecoveryRedirectUrl {
    if (!kIsWeb) return mobileCallbackUrl;
    return '${Uri.base.origin}/#/login';
  }
}
