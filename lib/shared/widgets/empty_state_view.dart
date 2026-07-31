import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';

class EmptyStateView extends StatelessWidget {
  final ScrollPhysics? physics;
  final Widget? icon;
  final String? title;
  final Widget? action;
  const EmptyStateView({
    super.key,
    this.physics,
    this.icon,
    this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(flex: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon ?? Assets.images.status.emptyStateBox.image(height: 140),
          ],
        ),
        FractionallySizedBox(
          widthFactor: 0.5,
          child: Text(
            title ?? 'No content.'.translate,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
        if (action != null) Column(children: [SizedBox(height: 12), action!]),
        Spacer(flex: 2),
      ],
    );
  }
}
