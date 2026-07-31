import 'package:encrypt/encrypt.dart';

import 'string_cipher_key.dart';

class StringCipher {
  StringCipher._();

  static const String prefix = 'EVSTR2';
  static final Encrypter _encrypter = Encrypter(
    AES(Key.fromUtf8(stringCipherKey), mode: AESMode.gcm),
  );

  /// Encrypts a UTF-8 string into a versioned, self-contained payload.
  static String encrypt(String plaintext) {
    final iv = IV.fromSecureRandom(12);
    final ciphertext = _encrypter.encrypt(plaintext, iv: iv);
    return '$prefix:${iv.base64}:${ciphertext.base64}';
  }

  /// Decrypts a payload returned by [encrypt].
  static String decrypt(String payload) {
    final parts = payload.trim().split(':');
    if (parts.length != 3 || parts.first != prefix) {
      throw const FormatException('Invalid encrypted string payload');
    }

    try {
      return _encrypter.decrypt(
        Encrypted.fromBase64(parts[2]),
        iv: IV.fromBase64(parts[1]),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Could not decrypt string payload', error);
    }
  }
}
