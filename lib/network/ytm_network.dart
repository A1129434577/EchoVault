import 'dart:ui';

import 'package:player_base/player_base.dart';

class YTMApis {
  //api上加了一些自定义参数用来区分是具体是哪里的请求
  static String home = 'browse?source=home';
  static String artistDetail = 'browse?source=artist';
  static String playlistDetail = 'browse?source=playlist';
  static String detail = 'browse';
  static String search = 'search';
  static String searchTabResult = 'search?source=tab';
  static String suggestions = 'music/get_search_suggestions';
  static String player = 'player';
  static String playRecommend = 'next';

  static String ytHome = 'browse?source=yt_home';
  static String ytPlaylistDetail = 'next?source=yt_playlist';
  static String ytArtistDetail = 'browse?source=yt_artist';
  static String ytSearch = 'search?source=yt';
  static String ytPlayRecommend = 'next?source=yt_recommend';
}

///网络解析
///youtube music和youtube的videoId双平台通用，但是playlistId不共用
class YTMNetwork {
  static const String baseUrl = "https://music.youtube.com/youtubei/v1/";
  static const String ytBaseUrl = "https://www.youtube.com/youtubei/v1/";

  //Youtube Music
  static Map webPrams = {
    'context':{
      'client' :{
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20260220.00.00',
      }
    }
  };
  //Youtube
  static Map ytWebPrams = {
    'context':{
      'client' :{
        'clientName': 'WEB',
        'clientVersion': '2.20260126.01.00',
      }
    }
  };
  static Map appPrams = {
    'context':{
      'client' :{
        'clientName': 'ANDROID',
        'clientVersion': '21.06.252',
      }
    }
  };
  //针对某个特定url的请求参数<url:prams>
  static Map<String, Map> specialPrams = {};

  static const String visitorDataKey = 'visitorDataKey';
  static String? _visitorData;
  static set visitorData(String? value) {
    _visitorData = value;
    SharedPreferences.getInstance().then((sp) async {
      if(value != null) {
        await sp.setString(visitorDataKey, value);
      }else{
        await sp.remove(visitorDataKey);
      }
    });
  }
  static Future<String?> get visitorData async {
    if(_visitorData != null){
      return _visitorData;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    _visitorData = sp.getString(visitorDataKey);
    return _visitorData;
  }

  static String? _languageCode;
  static String get languageCode {
    if(_languageCode != null) return _languageCode!;
    String languageCode = PlatformDispatcher.instance.locale.languageCode;
    if (languageCode.contains("zh")) {
      languageCode = "zh-CN";
    }
    _languageCode = languageCode;
    return languageCode;
  }

  static String? _countryCode;
  static String get countryCode {
    if(_countryCode != null) return _countryCode!;
    // String countryCode = PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? "US";
    // if (countryCode.contains("CN")) {
    //   countryCode = "US";
    // }
    //其他国家或者地区可能也不能用，直接写死US
    String countryCode = "US";
    _countryCode = countryCode;
    return countryCode;
  }

  static Future<T?> post<T>({
    required String url,
    Map prams = const {},
    Map<String, dynamic>? query,
    bool? isApp,
    bool isMusic = true,
  }) async {
    if(url.startsWith('http')==false){
      if(isMusic) {
        url = baseUrl + url;
      }else{
        url = ytBaseUrl + url;
      }
    }

    Map postPrams = {};
    if(isApp==true){
      postPrams.addAll(appPrams);
    }else {
      if (isMusic) {
        postPrams.addAll(webPrams);
      } else {
        postPrams.addAll(ytWebPrams);
      }
    }

    Map? special = specialPrams[url];
    if(special != null){
      postPrams = special;
    }

    String? vd = await visitorData;
    if (vd != null) {
      postPrams['context']['client']['visitorData'] = vd;
    }
    postPrams['context']['client']['hl'] = languageCode;
    postPrams['context']['client']['gl'] = countryCode;

    postPrams.addAll(prams);

    return await NetworkManager.instance.requestMethod(
      url: url,
      method: 'post',
      body: postPrams,
      query: query,
    );
  }
}