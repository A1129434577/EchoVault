import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/settings/setting_list_view.dart';
import 'package:echo_vault/widgets/app_bar_widgets.dart';
import 'package:echo_vault/widgets/bg_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingController _settingController = SettingController();

  @override
  void initState() {
    super.initState();
    _settingController.getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: Scaffold(
        appBar: AppBar(
          leading: AppRouteObserver.observer.routeStackList.length>1?AppBlackBackButton():null,
        ),
        body: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Setting'.translate,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Image.asset(Assets.assetsLogo, height: 56),
              SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: _settingController.version,
                builder: (BuildContext context, String version, Widget? child) {
                  return Text(
                    'v$version',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff121212).withAlpha((255*0.5).round()),
                    ),
                  );
                },
              ),
              SizedBox(height: 46),
              SettingListView(controller: _settingController,),
            ],
          ),
        ),
      ),
    );
  }
}
