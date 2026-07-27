part of '../../main.dart';

class EchoVaultApp extends StatelessWidget {
  const EchoVaultApp({super.key, required this.service});

  final AudioService service;

  @override
  Widget build(BuildContext context) {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF5DE2C5),
      secondary: Color(0xFFFFB454),
      tertiary: Color(0xFFFF6B6B),
      surface: Color(0xFF171A1D),
      onSurface: Color(0xFFF7F1E8),
    );

    return MaterialApp(
      title: 'NocturneBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0D0F10),
        fontFamily: 'SF Pro Display',
        sliderTheme: SliderThemeData(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: SliderComponentShape.noOverlay,
        ),
      ),
      home: EchoVaultHome(service: service),
    );
  }
}
