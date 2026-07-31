import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/preferences/preference_list_view.dart';
import 'package:echo_vault/shared/widgets/navigation_bar_views.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final PreferenceState _settingController = PreferenceState();

  @override
  void initState() {
    super.initState();
    _settingController.getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundSurface(
      child: Scaffold(
        appBar: AppBar(
          leading: AppRouteObserver.observer.routeStackList.length > 1
              ? AppBlackBackButton()
              : null,
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
              Assets.images.brand.appLogo.image(height: 56),
              SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: _settingController.version,
                builder: (BuildContext context, String version, Widget? child) {
                  return Text(
                    'v$version',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff121212).withAlpha((255 * 0.5).round()),
                    ),
                  );
                },
              ),
              SizedBox(height: 46),
              PreferenceListView(controller: _settingController),
            ],
          ),
        ),
      ),
    );
  }
}
