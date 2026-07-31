import 'dart:ui';

import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/user_preference_keys.dart';

class MusicCatalogEndpoints {
  //api上加了一些自定义参数用来区分是具体是哪里的请求
  static String discoveryFeed = 'browse?source=home';
  static String performerProfile = 'browse?source=artist';
  static String collectionProfile = 'browse?source=playlist';
  static String browseResource = 'browse';
  static String catalogSearch = 'search';
  static String filteredSearch = 'search?source=tab';
  static String querySuggestions = 'music/get_search_suggestions';
  static String playbackInfo = 'player';
  static String playbackRecommendations = 'next';

  static String videoDiscoveryFeed = 'browse?source=yt_home';
  static String videoCollectionProfile = 'next?source=yt_playlist';
  static String videoPerformerProfile = 'browse?source=yt_artist';
  static String videoSearch = 'search?source=yt';
  static String videoPlaybackRecommendations = 'next?source=yt_recommend';
}

///网络解析
///youtube music和youtube的videoId双平台通用，但是playlistId不共用
class MusicCatalogGateway {
  static const String musicApiRoot = "https://music.youtube.com/youtubei/v1/";
  static const String videoApiRoot = "https://www.youtube.com/youtubei/v1/";

  //Youtube Music
  static Map musicWebContext = {
    'context': {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20260220.00.00',
      },
    },
  };
  //Youtube
  static Map videoWebContext = {
    'context': {
      'client': {'clientName': 'WEB', 'clientVersion': '2.20260126.01.00'},
    },
  };
  static Map mobileAppContext = {
    'context': {
      'client': {'clientName': 'ANDROID', 'clientVersion': '21.06.252'},
    },
  };
  //针对某个特定url的请求参数<url:prams>
  static Map<String, Map> endpointOverrides = {};

  static String? _cachedVisitorToken;

  static String? _cachedLanguage;

  static String? _cachedRegion;
  static String get countryCode {
    if (_cachedRegion != null) return _cachedRegion!;
    // String countryCode = PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? "US";
    // if (countryCode.contains("CN")) {
    //   countryCode = "US";
    // }
    //其他国家或者地区可能也不能用，直接写死US
    String countryCodeLocal = "US";
    _cachedRegion = countryCodeLocal;
    return countryCodeLocal;
  }

  static String get languageCode {
    if (_cachedLanguage != null) return _cachedLanguage!;
    String languageCodeLocal = PlatformDispatcher.instance.locale.languageCode;
    if (languageCodeLocal.contains("zh")) {
      languageCodeLocal = "zh-CN";
    }
    _cachedLanguage = languageCodeLocal;
    return languageCodeLocal;
  }

  static set visitorData(String? currentValue) {
    _cachedVisitorToken = currentValue;
    SharedPreferences.getInstance().then((spInputArg) async {
      if (currentValue != null) {
        await spInputArg.setString(
          UserPreferenceKeys.catalogVisitorToken,
          currentValue,
        );
      } else {
        await spInputArg.remove(UserPreferenceKeys.catalogVisitorToken);
      }
    });
  }

  static Future<String?> get visitorData async {
    if (_cachedVisitorToken != null) {
      return _cachedVisitorToken;
    }
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    _cachedVisitorToken = spLocal.getString(
      UserPreferenceKeys.catalogVisitorToken,
    );
    return _cachedVisitorToken;
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
        resourceUrl = musicApiRoot + resourceUrl;
      } else {
        resourceUrl = videoApiRoot + resourceUrl;
      }
    }

    Map postPramsLocal = {};
    if (isAppArg == true) {
      postPramsLocal.addAll(mobileAppContext);
    } else {
      if (isMusicArg) {
        postPramsLocal.addAll(musicWebContext);
      } else {
        postPramsLocal.addAll(videoWebContext);
      }
    }

    Map? specialLocal = endpointOverrides[resourceUrl];
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
