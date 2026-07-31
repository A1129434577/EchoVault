import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';

class SectionTitleWidget extends StatelessWidget {
  final String title;
  final double fontSize;
  final VoidCallback? onTap;
  const SectionTitleWidget({
    super.key,
    required this.title,
    this.fontSize = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 5,
                    height: 10,
                    width: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xff1D75FF).withAlpha((255*0.4).round()),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Color(0xff141414),
                    ),
                  ),
                ],
              ),
            ),
            if(onTap!=null) ...[
              Text(
                'More'.translate,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff83848A),
                ),
              ),
              Assets.other.options.image(
                width: 16,
              )
            ],
          ],
        ),
      ),
    );
  }
}