
import 'package:echo_vault/src/app/echo_vault_app.dart';
import 'package:echo_vault/src/services/audio_service.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EchoVaultApp(service: FlutterAudioService()));
}
