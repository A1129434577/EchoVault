
import 'package:ad/ad.dart';
import 'package:echo_vault/modules/open/open_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:player_playback/player_playback.dart';

class EchoVaultApp extends StatelessWidget {
  const EchoVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF5DE2C5),
      secondary: Color(0xFFFFB454),
      tertiary: Color(0xFFFF6B6B),
      surface: Color(0xFF171A1D),
      onSurface: Color(0xFFF7F1E8),
    );

    return GetMaterialApp(
      title: 'NocturneBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'SF Pro Display',
        splashColor: Colors.transparent, // 禁用水波纹效果
        appBarTheme: AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        sliderTheme: SliderThemeData(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          unselectedItemColor: Color(0xff888888),
          selectedItemColor: Colors.blueAccent,
          unselectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
          selectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      navigatorObservers: [FlutterSmartDialog.observer, AppRouteObserver.observer],
      builder: FlutterSmartDialog.init(
        builder: (context, child){
          return Scaffold(
            body: GestureDetector(
              onTap: () {
                // 点击空白处收起键盘
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus &&
                    currentFocus.focusedChild != null) {
                  FocusManager.instance.primaryFocus!.unfocus();
                }
              },
              child: child,
            ),
          );
        },
      ),
      home: OpenPage(),
    );
  }
}
