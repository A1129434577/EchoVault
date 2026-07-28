import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:player_base/observer/app_route_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'src/app/echo_vault_app.dart';
part 'src/services/audio_service.dart';
part 'src/models/track.dart';
part 'src/utils/audio_file_utils.dart';
part 'src/features/home/echo_vault_home.dart';
part 'src/widgets/echo_vault_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EchoVaultApp(service: FlutterAudioService()));
}
