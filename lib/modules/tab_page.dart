import 'package:flutter/material.dart';
import 'package:player_base/utils/debounce_util.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/find/find_page.dart';
import 'package:echo_vault/modules/home/controllers/home_controller.dart';
import 'package:echo_vault/modules/home/home_page.dart';
import 'package:echo_vault/modules/library/library_page.dart';

class TabPage extends StatefulWidget {
  static ValueNotifier<int> currentTabIndex = ValueNotifier(0);

  const TabPage({super.key});

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  List<Widget> pageList = [
    HomePage(),
    LibraryPage(),
    FindPage(),
  ];

  final DebounceUtil _debounce = DebounceUtil();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TabPage.currentTabIndex,
      builder: (BuildContext context, int currentTabIndex, Widget? child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(
            index: currentTabIndex,
            children: pageList,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentTabIndex,
            selectedItemColor: Color(0xff141414),
            onTap: (index) {
              if(currentTabIndex == 0 && index == 0){
                _debounce(Duration(milliseconds: 1500),(){
                  HomeController.instance.refreshResource(source: 'click_bottomtab');
                  HomeController.instance.refreshController.callRefresh();
                });
              }
              TabPage.currentTabIndex.value = index;
            },
            items: [
              BottomNavigationBarItem(
                label: 'Home'.translate,
                icon: Assets.images.shell.tabHome.image( height: 24),
                activeIcon: Assets.images.shell.tabHomeActive.image( height: 24),
              ),
              BottomNavigationBarItem(
                label: 'Library'.translate,
                icon: Assets.images.shell.tabCollection.image( height: 24),
                activeIcon: Assets.images.shell.tabCollectionActive.image( height: 24),
              ),
              BottomNavigationBarItem(
                label: 'Search'.translate,
                icon: Assets.images.shell.tabSearch.image( height: 24),
                activeIcon: Assets.images.shell.tabSearchActive.image( height: 24),
              ),
            ],
          ),
        );
      },
    );
  }
}
