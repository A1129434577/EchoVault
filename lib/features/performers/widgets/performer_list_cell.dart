import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/performer_detail_screen.dart';
import 'package:echo_vault/features/performers/widgets/bookmark_performer_view.dart';

class PerformerListCell extends StatelessWidget {
  final PerformerDetails performerDetails;
  final Widget? action;
  const PerformerListCell({
    super.key,
    required this.performerDetails,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PerformerDetailScreenHelper.to(performerDetails: performerDetails);
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        spacing: 16,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: Assets.images.artist.profileAvatar.provider(),
                ),
              ),
              child: NetworkImageWidget(url: performerDetails.thumbnail),
            ),
          ),
          Expanded(
            child: Column(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performerDetails.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
                if (performerDetails.desc.isNotEmpty)
                  Text(
                    performerDetails.desc,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff141414).withAlpha((255 * 0.5).round()),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 24,
            child: action ?? BookmarkPerformerView(artist: performerDetails),
          ),
        ],
      ),
    );
  }
}
