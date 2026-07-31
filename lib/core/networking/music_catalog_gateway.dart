import 'dart:ui';

import 'package:player_base/player_base.dart';

class MusicCatalogEndpoints {
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
class MusicCatalogGateway {
  static const String baseUrl = "https://music.youtube.com/youtubei/v1/";
  static const String ytBaseUrl = "https://www.youtube.com/youtubei/v1/";

  //Youtube Music
  static Map webPrams = {
    'context': {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20260220.00.00',
      },
    },
  };
  //Youtube
  static Map ytWebPrams = {
    'context': {
      'client': {'clientName': 'WEB', 'clientVersion': '2.20260126.01.00'},
    },
  };
  static Map appPrams = {
    'context': {
      'client': {'clientName': 'ANDROID', 'clientVersion': '21.06.252'},
    },
  };
  //针对某个特定url的请求参数<url:prams>
  static Map<String, Map> specialPrams = {};

  static const String visitorDataKey = 'visitorDataKey';
  static String? _visitorData;

  static String? _languageCode;

  static String? _countryCode;
  static String get countryCode {
    if (_countryCode != null) return _countryCode!;
    // String countryCode = PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? "US";
    // if (countryCode.contains("CN")) {
    //   countryCode = "US";
    // }
    //其他国家或者地区可能也不能用，直接写死US
    String countryCodeLocal = "US";
    _countryCode = countryCodeLocal;
    return countryCodeLocal;
  }

  static String get languageCode {
    if (_languageCode != null) return _languageCode!;
    String languageCodeLocal = PlatformDispatcher.instance.locale.languageCode;
    if (languageCodeLocal.contains("zh")) {
      languageCodeLocal = "zh-CN";
    }
    _languageCode = languageCodeLocal;
    return languageCodeLocal;
  }

  static set visitorData(String? currentValue) {
    _visitorData = currentValue;
    SharedPreferences.getInstance().then((spInputArg) async {
      if (currentValue != null) {
        await spInputArg.setString(visitorDataKey, currentValue);
      } else {
        await spInputArg.remove(visitorDataKey);
      }
    });
  }

  static Future<String?> get visitorData async {
    if (_visitorData != null) {
      return _visitorData;
    }
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    _visitorData = spLocal.getString(visitorDataKey);
    return _visitorData;
  }

  static Future<T?> post<T>({
    required String resourceUrl,
    Map pramsArg = const {},
    Map<String, dynamic>? queryArg,
    bool? isAppArg,
    bool isMusicArg = true,
  }) async {
    if (resourceUrl.startsWith('http') == false) {
      if (isMusicArg) {
        resourceUrl = baseUrl + resourceUrl;
      } else {
        resourceUrl = ytBaseUrl + resourceUrl;
      }
    }

    Map postPramsLocal = {};
    if (isAppArg == true) {
      postPramsLocal.addAll(appPrams);
    } else {
      if (isMusicArg) {
        postPramsLocal.addAll(webPrams);
      } else {
        postPramsLocal.addAll(ytWebPrams);
      }
    }

    Map? specialLocal = specialPrams[resourceUrl];
    if (specialLocal != null) {
      postPramsLocal = specialLocal;
    }

    String? vdLocal = await visitorData;
    if (vdLocal != null) {
      postPramsLocal['context']['client']['visitorData'] = vdLocal;
    }
    postPramsLocal['context']['client']['hl'] = languageCode;
    postPramsLocal['context']['client']['gl'] = countryCode;

    postPramsLocal.addAll(pramsArg);

    return await NetworkManager.instance.requestMethod(
      url: resourceUrl,
      method: 'post',
      body: postPramsLocal,
      query: queryArg,
    );
  }
}
