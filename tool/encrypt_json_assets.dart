import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';

import 'package:echo_vault/utils/string_cipher.dart';
import 'package:echo_vault/utils/string_cipher_key.dart';

String _decryptExisting(String payload) {
  final parts = payload.trim().split(':');
  if (parts.length != 3) {
    return payload;
  }
  final encrypted = Encrypted.fromBase64(parts[2]);
  final iv = IV.fromBase64(parts[1]);
  if (parts.first == 'EVJSON1') {
    final legacyEncrypter = Encrypter(AES(Key.fromUtf8(stringCipherKey)));
    return legacyEncrypter.decrypt(encrypted, iv: iv);
  }
  if (parts.first == 'EVJSON2') {
    final legacyEncrypter = Encrypter(
      AES(Key.fromUtf8(stringCipherKey), mode: AESMode.gcm),
    );
    return legacyEncrypter.decrypt(encrypted, iv: iv);
  }
  if (parts.first == StringCipher.prefix) {
    return StringCipher.decrypt(payload);
  }
  return payload;
}

void main() {
  final files =
      Directory('assets/json')
          .listSync(recursive: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final plaintext = _decryptExisting(file.readAsStringSync());
    jsonDecode(plaintext);

    final payload = StringCipher.encrypt(plaintext);
    final recovered = StringCipher.decrypt(payload);
    if (recovered != plaintext) {
      throw StateError('Encryption verification failed: ${file.path}');
    }
    file.writeAsStringSync(payload, flush: true);
    stdout.writeln('Encrypted ${file.path}');
  }
}
