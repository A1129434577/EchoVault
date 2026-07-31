import 'dart:math';

import 'package:player_base/http/network_manager.dart';
import 'package:player_base/models/file_info.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class AudioTrackingTransport {
  //videoId: {playbackUrl:,watchTimeUrl:, end:}
  static Map<String, Map> playbackTelemetry = {};

  static String get watchCpn {
    const charsLocal =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const separatorsLocal = ['-', '_'];
    final randLocal = Random.secure();
    final bufferLocal = StringBuffer();
    final rLocal = Random().nextInt(10) + 3;
    for (int offset = 0; offset < 16; offset++) {
      if (offset == rLocal && randLocal.nextBool()) {
        bufferLocal.write(
          separatorsLocal[randLocal.nextInt(separatorsLocal.length)],
        );
      } else {
        bufferLocal.write(charsLocal[randLocal.nextInt(charsLocal.length)]);
      }
    }
    return bufferLocal.toString();
  }

  static Future post({required FileInfo mediaEntry}) async {
    String mediaId = mediaEntry.fileId;
    Map details = playbackTelemetry[mediaId] ?? {};
    String? playbackUrlLocal, watchTimeUrlValueLocal;
    if (details.length < 2) {
      String cpnLocal = watchCpn;
      Map requestParameters = {'videoId': mediaId, 'cpn': cpnLocal};
      dynamic response = await MusicCatalogGateway.post(
        resourceUrl: MusicCatalogEndpoints.playbackInfo,
        pramsArg: requestParameters,
        isAppArg: true,
      );
      playbackUrlLocal = ParserHelper.parse<String>(
        response,
        PlaybackTrackingParserKeys.playbackTrackingPath,
      );
      watchTimeUrlValueLocal = ParserHelper.parse<String>(
        response,
        PlaybackTrackingParserKeys.watchTimeTrackingPath,
      );

      if (playbackUrlLocal != null && playbackUrlLocal.startsWith('http')) {
        playbackUrlLocal = playbackUrlLocal.replaceFirst('s.', 'music.');
        details['playbackUrl'] = playbackUrlLocal;
      }
      if (watchTimeUrlValueLocal != null &&
          watchTimeUrlValueLocal.startsWith('http')) {
        watchTimeUrlValueLocal = watchTimeUrlValueLocal.replaceFirst(
          's.',
          'music.',
        );
        details['watchTimeUrl'] = watchTimeUrlValueLocal;
      }
      details['cpn'] = cpnLocal;
      playbackTelemetry[mediaId] = details;
    } else {
      playbackUrlLocal = details['playbackUrl'];
      watchTimeUrlValueLocal = details['watchTimeUrl'];
    }
    double endLocal = mediaEntry.position?.toDouble() ?? 0;
    double startLocal = details['end'] ?? 0;
    if (startLocal > endLocal) {
      startLocal = 0;
    }
    details['end'] = endLocal;

    //headers的X-Goog-Visitor-Id对应的是visitorData
    //是做根据播放记录刷新首页猜你喜欢的关键
    Map<String, String>? headersLocal;
    String? vdLocal = await MusicCatalogGateway.visitorData;
    if (vdLocal != null) {
      headersLocal = {"X-Goog-Visitor-Id": vdLocal};
    }
    String pathLocal =
        "&cpn=${details['cpn']}"
        "&ver=2"
        "&volume=100"
        "&muted=0"
        "&cmt=${mediaEntry.position}"
        "&hl=${MusicCatalogGateway.languageCode}"
        "&cr=${MusicCatalogGateway.countryCode}"
        "&c=${MusicCatalogGateway.musicWebContext['context']?['client']?['clientName']}"
        "&cver=${MusicCatalogGateway.musicWebContext['context']?['client']?['clientVersion']}";
    if (playbackUrlLocal != null) {
      playbackUrlLocal += pathLocal;
      await NetworkManager.instance.requestMethod(
        url: playbackUrlLocal,
        method: 'get',
        headers: headersLocal,
      );
    }
    if (watchTimeUrlValueLocal != null) {
      watchTimeUrlValueLocal +=
          "$pathLocal"
          "&state='playing'"
          "&st=$startLocal"
          "&et=$endLocal";
      await NetworkManager.instance.requestMethod(
        url: watchTimeUrlValueLocal,
        method: 'get',
        headers: headersLocal,
      );
    }
  }
}

class PlaybackTrackingParserKeys {
  static List playbackTrackingPath = [
    'playbackTracking',
    'videostatsPlaybackUrl',
    'baseUrl',
  ];

  static List watchTimeTrackingPath = [
    'playbackTracking',
    'videostatsWatchtimeUrl',
    'baseUrl',
  ];
}
