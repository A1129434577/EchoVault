import 'package:echo_vault/core/configuration/application_settings.dart';
import 'package:echo_vault/src/app/echo_vault_app.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ApplicationSettings.start();
  } catch (_) {}
  runApp(EchoVaultApp());
}
