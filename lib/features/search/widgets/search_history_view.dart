import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/shared/dialogs/confirmation_dialog.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/search/search_screen.dart';
import 'package:echo_vault/features/primary_navigation_screen.dart';
import 'package:echo_vault/core/persistence/user_preference_keys.dart';

class SearchHistoryState with ChangeNotifier {
  ValueNotifier<List<String>> keywordList = ValueNotifier([]);

  late final ValueNotifier<AdInfo?> searchNatoAd = ValueNotifier(
    AdHelper.adSceneCacheInfo[scene],
  );

  StreamSubscription? _adLoadSubscription;
  late VoidCallback _mainTabIndexListener;

  AdScene scene = AdvertisingScene.searchResultsNative;
  final String tag;
  SearchHistoryState({required this.tag}) {
    if (tag == SearchScreen.discoveryEntryTag) {
      scene = AdvertisingScene.searchHomeNative;
    }
    AdHelper.loadSceneAdIfNull(
      scene: scene,
      detailScene: AdvertisingDetailScene.searchResults,
    );
    _adLoadSubscription = AdHelper.adLoadStatusStream.listen((adInfoInputArg) {
      if (adInfoInputArg.scene == scene) {
        if (adInfoInputArg.loadState == AdLoadStatus.loaded) {
          searchNatoAd.value = adInfoInputArg;
          searchNatoAd.notifyListeners();
        }
      }
    });
    _mainTabIndexListener = () {
      if (PrimaryNavigationScreen.selectedSection.value == 2) {
        fetchHistoryKeywords();
        AdHelper.loadSceneAdIfNull(
          scene: scene,
          detailScene: AdvertisingDetailScene.searchResults,
        );
      }
    };
    PrimaryNavigationScreen.selectedSection.addListener(_mainTabIndexListener);
  }

  @override
  void dispose() {
    _adLoadSubscription?.cancel();
    PrimaryNavigationScreen.selectedSection.removeListener(
      _mainTabIndexListener,
    );
    super.dispose();
  }

  Future clearHistoryKeywords() async {
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    await spLocal.remove(UserPreferenceKeys.searchHistory);
    fetchHistoryKeywords();
  }

  Future<List<String>> fetchHistoryKeywords() async {
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    String? listJsonStringLocal = spLocal.getString(
      UserPreferenceKeys.searchHistory,
    );
    List<dynamic> storedKeywordsLocal = [];
    if (listJsonStringLocal != null) {
      storedKeywordsLocal = jsonDecode(listJsonStringLocal);
    }
    keywordList.value = storedKeywordsLocal.cast();
    return keywordList.value;
  }

  Future saveHistoryKeyword(String keywordArg) async {
    List<String> historyEntriesLocal = await fetchHistoryKeywords();
    if (historyEntriesLocal.contains(keywordArg)) {
      historyEntriesLocal.remove(keywordArg);
    }
    historyEntriesLocal.insert(0, keywordArg);
    if (historyEntriesLocal.length > 10) {
      historyEntriesLocal.sublist(0, 10);
    }
    keywordList.value = historyEntriesLocal;
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    await spLocal.setString(
      UserPreferenceKeys.searchHistory,
      jsonEncode(historyEntriesLocal),
    );
  }
}

class SearchHistoryView extends StatefulWidget {
  final ValueChanged<String>? onTap;
  final String tag;
  const SearchHistoryView({super.key, this.onTap, required this.tag});

  @override
  State<SearchHistoryView> createState() => _SearchHistoryViewState();
}

class _SearchHistoryViewState extends State<SearchHistoryView> {
  late final SearchHistoryState controller = Get.find<SearchHistoryState>(
    tag: widget.tag,
  );

  @override
  void initState() {
    super.initState();
    controller.fetchHistoryKeywords();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History map'.translate,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            CupertinoButton(
              onPressed: () {
                ConfirmationDialog.show(
                  displayTitle: 'Delete',
                  messageArg:
                      'Are you sure you want to clear your search history?',
                  onConfirmArg: () {
                    controller.clearHistoryKeywords();
                  },
                );
              },
              sizeStyle: CupertinoButtonSize.small,
              padding: EdgeInsets.zero,
              child: Assets.images.search.historyDelete.image(width: 24),
            ),
          ],
        ),
        Container(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(),
          padding: EdgeInsets.symmetric(vertical: 18),
          constraints: BoxConstraints(maxHeight: 35 * 3 + 16 * 2 + 18 * 2),
          child: ValueListenableBuilder(
            valueListenable: controller.keywordList,
            builder:
                (
                  BuildContext context,
                  List<String> keywordList,
                  Widget? child,
                ) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: keywordList.map((keyword) {
                      return GestureDetector(
                        onTap: () {
                          widget.onTap?.call(keyword);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            keyword,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.searchNatoAd,
          builder: (BuildContext context, AdInfo? adInfo, Widget? child) {
            if (adInfo?.ad != null || adInfo?.adView != null) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.topCenter,
                child: AspectRatio(
                  aspectRatio: 300 / 250,
                  child: NativePartAdView(
                    adInfo: adInfo!,
                    onCloseButtonClick: () {
                      controller.searchNatoAd.value = null;
                      AdHelper.loadSceneAdIfNull(
                        scene: controller.scene,
                        detailScene: AdvertisingDetailScene.searchResults,
                      );
                    },
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
