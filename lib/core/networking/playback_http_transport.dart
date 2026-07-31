import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/features/playback/controllers/playback_coordinator.dart';

class PlaybackHttpTransport implements PlayerHttpClientInterface {
  @override
  Future<String?> getFileUrl({required FileInfo fileInfo}) async {
    String? resourceUrl = await PlaybackCoordinator.instance.queryMediaDetail(
      fileInfo,
    );
    return resourceUrl;
  }
}
