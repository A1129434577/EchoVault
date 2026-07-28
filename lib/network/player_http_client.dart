import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/modules/player/controllers/play_controller.dart';

class PlayerHttpClient implements PlayerHttpClientInterface {
  @override
  Future<String?> getFileUrl({required FileInfo fileInfo}) async {
    String? url = await PlayController.instance.queryMediaDetail(fileInfo);
    return url;
  }
}