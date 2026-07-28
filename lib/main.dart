
import 'package:echo_vault/config/app_config.dart';
import 'package:echo_vault/src/app/echo_vault_app.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try{
    await AppConfig.start();
  }catch(_){}
  runApp(EchoVaultApp());
}
