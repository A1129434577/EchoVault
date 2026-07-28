
import 'dart:math';

import 'package:echo_vault/src/models/track_model.dart';
import 'package:echo_vault/src/utils/audio_file_utils.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.trackCount,
    required this.totalMinutes,
    required this.favoriteCount,
    required this.importing,
    required this.onImport,
  });

  final int trackCount;
  final int totalMinutes;
  final int favoriteCount;
  final bool importing;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NocturneBox',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Offline music, privately stored',
                      style: TextStyle(
                        color: Color(0xFFB8C2BE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: importing ? null : onImport,
                icon: importing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_upload_outlined),
                label: Text(importing ? 'Importing' : 'Import'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricPill(
                icon: Icons.library_music_outlined,
                label: countLabel(trackCount, 'track'),
                tint: const Color(0xFF5DE2C5),
              ),
              MetricPill(
                icon: Icons.timer_outlined,
                label: '$totalMinutes min',
                tint: const Color(0xFFFFB454),
              ),
              MetricPill(
                icon: Icons.favorite_border,
                label: '$favoriteCount saved',
                tint: const Color(0xFFFF6B6B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF171A1D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF5DE2C5).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(Icons.graphic_eq_rounded, color: Color(0xFF5DE2C5)),
        ],
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tint, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search title, artist, album',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFF171A1D),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
    );
  }
}

class TabStrip extends StatelessWidget {
  const TabStrip({super.key, required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const tabs = [
    (Icons.music_note_outlined, 'Library'),
    (Icons.favorite_border, 'Saved'),
    (Icons.auto_awesome_mosaic_outlined, 'Crates'),
    (Icons.bedtime_outlined, 'Sleep'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final active = selected == index;
          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            avatar: Icon(tab.$1, size: 18),
            label: Text(tab.$2),
            onSelected: (_) => onChanged(index),
            selectedColor: const Color(0xFF5DE2C5),
            labelStyle: TextStyle(
              color: active ? const Color(0xFF07100E) : Colors.white,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            backgroundColor: const Color(0xFF171A1D),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: tabs.length,
      ),
    );
  }
}

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB454).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFB454).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFFFB454)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class LibraryView extends StatelessWidget {
  const LibraryView({
    super.key,
    required this.loading,
    required this.tracks,
    required this.emptyTitle,
    required this.emptyAction,
    required this.currentTrackId,
    required this.onImport,
    required this.onPlay,
    required this.onFavorite,
    required this.onDelete,
  });

  final bool loading;
  final List<TrackModel> tracks;
  final String emptyTitle;
  final String emptyAction;
  final String? currentTrackId;
  final VoidCallback onImport;
  final ValueChanged<TrackModel> onPlay;
  final ValueChanged<TrackModel> onFavorite;
  final ValueChanged<TrackModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tracks.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        action: emptyAction,
        onAction: onImport,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return TrackTile(
          track: track,
          isCurrent: track.id == currentTrackId,
          onPlay: () => onPlay(track),
          onFavorite: () => onFavorite(track),
          onDelete: () => onDelete(track),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF5DE2C5).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: Color(0xFF5DE2C5),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add local audio files from Files and keep playback available offline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.isCurrent,
    required this.onPlay,
    required this.onFavorite,
    required this.onDelete,
  });

  final TrackModel track;
  final bool isCurrent;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(track.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF6B6B),
        ),
      ),
      child: Material(
        color: isCurrent ? const Color(0xFF21342F) : const Color(0xFF171A1D),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AlbumGlyph(track: track, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${track.artist} - ${track.album}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDuration(track.duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    track.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: track.isFavorite
                        ? const Color(0xFFFF6B6B)
                        : Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlbumGlyph extends StatelessWidget {
  const AlbumGlyph({super.key, required this.track, required this.size});

  final TrackModel track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(track.id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(max(8, size * 0.18)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.album_rounded, size: size * 0.55, color: color),
          Positioned(
            right: size * 0.16,
            bottom: size * 0.15,
            child: Icon(
              Icons.offline_bolt_rounded,
              size: size * 0.18,
              color: const Color(0xFFFFB454),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String seed) {
    final palette = [
      const Color(0xFF5DE2C5),
      const Color(0xFFFFB454),
      const Color(0xFFFF6B6B),
      const Color(0xFF9ECAFF),
      const Color(0xFFE7F56D),
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }
}

class CratesView extends StatelessWidget {
  const CratesView({super.key, required this.tracks, required this.onPlay});

  final List<TrackModel> tracks;
  final ValueChanged<TrackModel> onPlay;

  @override
  Widget build(BuildContext context) {
    final crates = [
      SmartCrate(
        icon: Icons.bolt_outlined,
        title: 'Quick Hits',
        subtitle: 'Short tracks under four minutes',
        tint: const Color(0xFFFFB454),
        tracks: tracks.where((track) => track.duration < 240).toList(),
      ),
      SmartCrate(
        icon: Icons.nightlight_outlined,
        title: 'Long Ride',
        subtitle: 'Deep cuts for uninterrupted listening',
        tint: const Color(0xFF9ECAFF),
        tracks: tracks.where((track) => track.duration >= 240).toList(),
      ),
      SmartCrate(
        icon: Icons.favorite_border,
        title: 'Saved Signal',
        subtitle: 'Everything you marked as worth keeping close',
        tint: const Color(0xFFFF6B6B),
        tracks: tracks.where((track) => track.isFavorite).toList(),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      itemBuilder: (context, index) {
        final crate = crates[index];
        return CrateTile(
          crate: crate,
          onPlayFirst: crate.tracks.isEmpty
              ? null
              : () => onPlay(crate.tracks.first),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: crates.length,
    );
  }
}

class SmartCrate {
  const SmartCrate({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.tracks,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final List<TrackModel> tracks;
}

class CrateTile extends StatelessWidget {
  const CrateTile({super.key, required this.crate, required this.onPlayFirst});

  final SmartCrate crate;
  final VoidCallback? onPlayFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: crate.tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: crate.tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(crate.icon, color: crate.tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crate.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${crate.tracks.length} tracks - ${crate.subtitle}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onPlayFirst,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class SleepView extends StatelessWidget {
  const SleepView({
    super.key,
    required this.minutes,
    required this.isActive,
    required this.onChanged,
    required this.onStart,
    required this.onCancel,
  });

  final int minutes;
  final bool isActive;
  final ValueChanged<int> onChanged;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF171A1D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bedtime_outlined, color: Color(0xFF9ECAFF)),
                const SizedBox(height: 18),
                const Text(
                  'Sleep timer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isActive
                      ? 'Timer is active'
                      : 'Pause playback automatically after a quiet window.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.66)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      '$minutes min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        min: 5,
                        max: 120,
                        divisions: 23,
                        value: minutes.toDouble(),
                        onChanged: (value) => onChanged(value.round()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.timer_outlined),
                        label: const Text('Start'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: isActive ? onCancel : null,
                      icon: const Icon(Icons.stop_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({
    super.key,
    required this.track,
    required this.snapshot,
    required this.onPlayPause,
    required this.onSeek,
    required this.onOpen,
  });

  final TrackModel? track;
  final PlaybackSnapshot snapshot;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return const SizedBox.shrink();
    }
    return Material(
      color: const Color(0xFF101315),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProgressScrubber(
                  snapshot: snapshot,
                  onSeek: onSeek,
                  compact: true,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AlbumGlyph(track: track!, size: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track!.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: onPlayPause,
                      icon: Icon(
                        snapshot.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressScrubber extends StatelessWidget {
  const ProgressScrubber({
    super.key,
    required this.snapshot,
    required this.onSeek,
    this.compact = false,
  });

  final PlaybackSnapshot snapshot;
  final ValueChanged<double> onSeek;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final duration = max(snapshot.duration, 1.0);
    final position = snapshot.position.clamp(0.0, duration);
    return Column(
      children: [
        Slider(min: 0, max: duration, value: position, onChanged: onSeek),
        if (!compact)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(position),
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                formatDuration(duration),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
      ],
    );
  }
}
