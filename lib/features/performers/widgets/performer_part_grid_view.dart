import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/performer_detail_screen.dart';

class PerformerPartGridView extends StatelessWidget {
  final List<PerformerDetails> performers;
  const PerformerPartGridView({super.key, required this.performers});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidthLocal = (constraints.maxWidth - 12 * 4) / 9 * 2;
        double aspectRatioLocal = 1;
        return SizedBox(
          height: itemWidthLocal * aspectRatioLocal + 35,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 12,
              mainAxisExtent: itemWidthLocal,
              crossAxisCount: 1,
            ),
            itemCount: performers.length,
            itemBuilder: (BuildContext ctx, int index) {
              PerformerDetails performerProfile = performers[index];
              return _PerformerGridCell(performerDetails: performerProfile);
            },
          ),
        );
      },
    );
  }
}

class _PerformerGridCell extends StatelessWidget {
  final PerformerDetails performerDetails;
  const _PerformerGridCell({super.key, required this.performerDetails});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PerformerDetailScreenHelper.to(performerProfile: performerDetails);
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
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
          Text(
            performerDetails.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
