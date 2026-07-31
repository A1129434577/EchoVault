import 'dart:convert';
import 'dart:io';

import 'package:echo_vault/utils/string_cipher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assetPaths = [
    'assets/data/art_seed.json',
    'assets/data/file_seed.json',
    'assets/data/top_seed.json',
  ];

  test('encrypted JSON assets decrypt into valid JSON', () {
    for (final assetPath in assetPaths) {
      final encrypted = File(assetPath).readAsStringSync();
      expect(encrypted, startsWith('EVSTR2:'));
      expect(jsonDecode(StringCipher.decrypt(encrypted)), isNotNull);
    }
  });

  test('round-trips arbitrary strings', () {
    const plaintext = 'EchoVault: private string 123';
    final encrypted = StringCipher.encrypt(plaintext);

    expect(encrypted, startsWith('EVSTR2:'));
    expect(StringCipher.decrypt(encrypted), plaintext);
  });
}
