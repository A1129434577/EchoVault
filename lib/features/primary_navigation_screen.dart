import 'package:flutter/material.dart';
import 'package:player_base/utils/debounce_util.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/search/search_screen.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/features/discovery/discovery_screen.dart';
import 'package:echo_vault/features/catalog/catalog_screen.dart';

class PrimaryNavigationScreen extends StatefulWidget {
  static ValueNotifier<int> currentTabIndex = ValueNotifier(0);

  const PrimaryNavigationScreen({super.key});

  @override
  State<PrimaryNavigationScreen> createState() =>
      _PrimaryNavigationScreenState();
}

class _PrimaryNavigationScreenState extends State<PrimaryNavigationScreen> {
  List<Widget> pageList = [DiscoveryScreen(), CatalogScreen(), SearchScreen()];

  final DebounceUtil _debounce = DebounceUtil();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: PrimaryNavigationScreen.currentTabIndex,
      builder: (BuildContext context, int currentTabIndex, Widget? child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(index: currentTabIndex, children: pageList),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentTabIndex,
            selectedItemColor: Color(0xff141414),
            onTap: (index) {
              if (currentTabIndex == 0 && index == 0) {
                _debounce(Duration(milliseconds: 1500), () {
                  DiscoveryState.instance.refreshResource(
                    mediaOrigin: 'click_bottomtab',
                  );
                  DiscoveryState.instance.refreshController.callRefresh();
                });
              }
              PrimaryNavigationScreen.currentTabIndex.value = index;
            },
            items: [
              BottomNavigationBarItem(
                label: 'Home'.translate,
                icon: Assets.images.shell.tabHome.image(height: 24),
                activeIcon: Assets.images.shell.tabHomeActive.image(height: 24),
              ),
              BottomNavigationBarItem(
                label: 'Library'.translate,
                icon: Assets.images.shell.tabCollection.image(height: 24),
                activeIcon: Assets.images.shell.tabCollectionActive.image(
                  height: 24,
                ),
              ),
              BottomNavigationBarItem(
                label: 'Search'.translate,
                icon: Assets.images.shell.tabSearch.image(height: 24),
                activeIcon: Assets.images.shell.tabSearchActive.image(
                  height: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
