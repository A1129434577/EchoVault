import 'dart:math';

import 'package:player_base/http/network_manager.dart';
import 'package:player_base/models/file_info.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class AudioTrackingTransport {
  //videoId: {playbackUrl:,watchTimeUrl:, end:}
  static Map<String, Map> playTrackingInfo = {};

  static Future post({required FileInfo mediaDetails}) async {
    String videoId = mediaDetails.fileId;
    Map info = playTrackingInfo[videoId] ?? {};
    String? playbackUrl, watchTimeUrl;
    if (info.length < 2) {
      String cpn = watchCpn;
      Map params = {'videoId': videoId, 'cpn': cpn};
      dynamic result = await MusicCatalogGateway.post(
        url: MusicCatalogEndpoints.player,
        prams: params,
        isApp: true,
      );
      playbackUrl = ParserHelper.parse<String>(
        result,
        PlaybackTrackingParserKeys.playbackUrl,
      );
      watchTimeUrl = ParserHelper.parse<String>(
        result,
        PlaybackTrackingParserKeys.watchTimeUrl,
      );

      if (playbackUrl != null && playbackUrl.startsWith('http')) {
        playbackUrl = playbackUrl.replaceFirst('s.', 'music.');
        info['playbackUrl'] = playbackUrl;
      }
      if (watchTimeUrl != null && watchTimeUrl.startsWith('http')) {
        watchTimeUrl = watchTimeUrl.replaceFirst('s.', 'music.');
        info['watchTimeUrl'] = watchTimeUrl;
      }
      info['cpn'] = cpn;
      playTrackingInfo[videoId] = info;
    } else {
      playbackUrl = info['playbackUrl'];
      watchTimeUrl = info['watchTimeUrl'];
    }
    double end = mediaDetails.position?.toDouble() ?? 0;
    double start = info['end'] ?? 0;
    if (start > end) {
      start = 0;
    }
    info['end'] = end;

    //headers的X-Goog-Visitor-Id对应的是visitorData
    //是做根据播放记录刷新首页猜你喜欢的关键
    Map<String, String>? headers;
    String? vd = await MusicCatalogGateway.visitorData;
    if (vd != null) {
      headers = {"X-Goog-Visitor-Id": vd};
    }
    String path =
        "&cpn=${info['cpn']}"
        "&ver=2"
        "&volume=100"
        "&muted=0"
        "&cmt=${mediaDetails.position}"
        "&hl=${MusicCatalogGateway.languageCode}"
        "&cr=${MusicCatalogGateway.countryCode}"
        "&c=${MusicCatalogGateway.webPrams['context']?['client']?['clientName']}"
        "&cver=${MusicCatalogGateway.webPrams['context']?['client']?['clientVersion']}";
    if (playbackUrl != null) {
      playbackUrl += path;
      await NetworkManager.instance.requestMethod(
        url: playbackUrl,
        method: 'get',
        headers: headers,
      );
    }
    if (watchTimeUrl != null) {
      watchTimeUrl +=
          "$path"
          "&state='playing'"
          "&st=$start"
          "&et=$end";
      await NetworkManager.instance.requestMethod(
        url: watchTimeUrl,
        method: 'get',
        headers: headers,
      );
    }
  }

  static String get watchCpn {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const separators = ['-', '_'];
    final rand = Random.secure();
    final buffer = StringBuffer();
    final r = Random().nextInt(10) + 3;
    for (int i = 0; i < 16; i++) {
      if (i == r && rand.nextBool()) {
        buffer.write(separators[rand.nextInt(separators.length)]);
      } else {
        buffer.write(chars[rand.nextInt(chars.length)]);
      }
    }
    return buffer.toString();
  }
}

class PlaybackTrackingParserKeys {
  static List playbackUrl = [
    'playbackTracking',
    'videostatsPlaybackUrl',
    'baseUrl',
  ];

  static List watchTimeUrl = [
    'playbackTracking',
    'videostatsWatchtimeUrl',
    'baseUrl',
  ];
}
