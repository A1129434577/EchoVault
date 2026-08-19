
import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/core/monetization/advertising_display_coordinator.dart';
import 'package:echo_vault/features/launch/controllers/launch_state.dart';
import 'package:echo_vault/features/primary_navigation_screen.dart';
import 'package:echo_vault/src/models/track_model.dart';
import 'package:echo_vault/src/services/audio_service.dart';
import 'package:echo_vault/src/utils/audio_file_utils.dart';
import 'package:echo_vault/src/widgets/echo_vault_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EchoVaultHome extends StatefulWidget {
  const EchoVaultHome({super.key, required this.service});

  final AppAudioService service;

  @override
  State<EchoVaultHome> createState() => _EchoVaultHomeState();
}

class _EchoVaultHomeState extends State<EchoVaultHome> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  StreamSubscription<PlaybackSnapshot>? _playbackSub;
  Timer? _sleepTimer;
  List<TrackModel> _tracks = const [];
  PlaybackSnapshot _playback = const PlaybackSnapshot.idle();
  int _tab = 0;
  int _sleepMinutes = 30;
  String _query = '';
  bool _loading = true;
  bool _importing = false;
  String? _notice;

  TrackModel? get _currentTrack {
    final id = _playback.trackId;
    if (id == null) {
      return null;
    }
    for (final track in _tracks) {
      if (track.id == id) {
        return track;
      }
    }
    return null;
  }

  List<TrackModel> get _visibleTracks {
    Iterable<TrackModel> source = _tracks;
    if (_tab == 1) {
      source = source.where((track) => track.isFavorite);
    }
    if (_query.trim().isNotEmpty) {
      final needle = _query.toLowerCase();
      source = source.where((track) {
        return track.title.toLowerCase().contains(needle) ||
            track.artist.toLowerCase().contains(needle) ||
            track.album.toLowerCase().contains(needle);
      });
    }
    return source.toList(growable: false);
  }

  int get _totalMinutes {
    final seconds = _tracks.fold<double>(
      0,
      (total, track) => total + track.duration,
    );
    return (seconds / 60).round();
  }

  late VoidCallback _isModulesListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestTrackingAuthorization());
    });
    _loadLibrary();
    _playbackSub = widget.service.playbackEvents.listen(
      (snapshot) => setState(() => _playback = snapshot),
      onError: (_) {},
    );
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });

    _isModulesListener = () async {
      if (LaunchState.instance.isModulesUsable.value == true) {
        Get.offAll(PrimaryNavigationScreen());
      }
    };
    LaunchState.instance.isModulesUsable.addListener(_isModulesListener);
  }

  Future<void> _requestTrackingAuthorization() async {
    if (!Platform.isIOS) {
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } on PlatformException {
      // Tracking authorization must never block the offline player startup.
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _playbackSub?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    LaunchState.instance.isModulesUsable.removeListener(_isModulesListener);
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() => _loading = true);
    final tracks = await widget.service.loadLibrary();
    if (!mounted) {
      return;
    }
    setState(() {
      _tracks = sortTracks(tracks);
      _loading = false;
    });
  }

  Future<void> _importAudio() async {
    if (_importing) {
      return;
    }
    setState(() {
      _importing = true;
      _notice = null;
    });
    try {
      final tracks = await widget.service.importAudio();
      if (!mounted) {
        return;
      }
      setState(() {
        _tracks = sortTracks(tracks);
        _notice =
            'Imported ${tracks.length} offline track${tracks.length == 1 ? '' : 's'}';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _notice = error.message ?? 'Import was canceled');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<void> _playTrack(TrackModel track) async {
    try {
      AdvertisingDisplayCoordinator.showScene(scene: AdvertisingScene.inApp, detailScene: AdvertisingDetailScene.play);
      await widget.service.play(track.id);
      if (mounted) {
        setState(() {
          _playback = PlaybackSnapshot(
            trackId: track.id,
            position: 0,
            duration: track.duration,
            isPlaying: true,
          );
          _notice = null;
        });
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notice = error.message ?? 'This audio file could not be played.';
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_playback.trackId == null && _tracks.isNotEmpty) {
      await _playTrack(_tracks.first);
      return;
    }
    if (_playback.isPlaying) {
      await widget.service.pause();
      setState(() {
        _playback = PlaybackSnapshot(
          trackId: _playback.trackId,
          position: _playback.position,
          duration: _playback.duration,
          isPlaying: false,
        );
      });
    } else {
      await widget.service.resume();
      setState(() {
        _playback = PlaybackSnapshot(
          trackId: _playback.trackId,
          position: _playback.position,
          duration: _playback.duration,
          isPlaying: true,
        );
      });
    }
  }

  Future<void> _seek(double value) async {
    await widget.service.seek(value);
    setState(() {
      _playback = PlaybackSnapshot(
        trackId: _playback.trackId,
        position: value,
        duration: _playback.duration,
        isPlaying: _playback.isPlaying,
      );
    });
  }

  Future<void> _toggleFavorite(TrackModel track) async {
    final updated = await widget.service.toggleFavorite(track.id);
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _tracks = _tracks
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
    });
  }

  Future<void> _deleteTrack(TrackModel track) async {
    final deleted = await widget.service.deleteTrack(track.id);
    if (!mounted || !deleted) {
      return;
    }
    setState(() {
      _tracks = _tracks.where((item) => item.id != track.id).toList();
      if (_playback.trackId == track.id) {
        _playback = const PlaybackSnapshot.idle();
      }
      _notice = 'Removed ${track.title}';
    });
  }

  void _scheduleSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(Duration(minutes: _sleepMinutes), () async {
      await widget.service.pause();
      if (mounted) {
        setState(() {
          _playback = PlaybackSnapshot(
            trackId: _playback.trackId,
            position: _playback.position,
            duration: _playback.duration,
            isPlaying: false,
          );
          _notice = 'Sleep timer finished';
        });
      }
    });
    setState(() => _notice = 'Sleep timer set for $_sleepMinutes minutes');
  }

  void _changeTab(int index) {
    setState(() => _tab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F10),
      body: SafeArea(
        child: Column(
          children: [
            Header(
              trackCount: _tracks.length,
              totalMinutes: _totalMinutes,
              favoriteCount: _tracks.where((track) => track.isFavorite).length,
              importing: _importing,
              onImport: _importAudio,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: SearchField(controller: _searchController),
            ),
            TabStrip(selected: _tab, onChanged: _changeTab),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: NoticeBanner(
                  text: _notice!,
                  onClose: () => setState(() => _notice = null),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _tab = index),
                children: [
                  LibraryView(
                    loading: _loading,
                    tracks: _visibleTracks,
                    emptyTitle: 'Your vault is empty',
                    emptyAction: 'Import audio',
                    currentTrackId: _playback.trackId,
                    onImport: _importAudio,
                    onPlay: _playTrack,
                    onFavorite: _toggleFavorite,
                    onDelete: _deleteTrack,
                  ),
                  LibraryView(
                    loading: _loading,
                    tracks: _visibleTracks,
                    emptyTitle: 'No favorites yet',
                    emptyAction: 'Browse library',
                    currentTrackId: _playback.trackId,
                    onImport: () => _changeTab(0),
                    onPlay: _playTrack,
                    onFavorite: _toggleFavorite,
                    onDelete: _deleteTrack,
                  ),
                  CratesView(tracks: _tracks, onPlay: _playTrack),
                  SleepView(
                    minutes: _sleepMinutes,
                    isActive: _sleepTimer?.isActive ?? false,
                    onChanged: (value) => setState(() => _sleepMinutes = value),
                    onStart: _scheduleSleepTimer,
                    onCancel: () {
                      _sleepTimer?.cancel();
                      setState(() => _notice = 'Sleep timer canceled');
                    },
                  ),
                ],
              ),
            ),
            NowPlayingBar(
              track: _currentTrack,
              snapshot: _playback,
              onPlayPause: _togglePlayback,
              onSeek: _seek,
              onOpen: () => _openNowPlaying(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openNowPlaying(BuildContext context) {
    final track = _currentTrack;
    if (track == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111416),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AlbumGlyph(track: track, size: 220),
                  const SizedBox(height: 26),
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 26),
                  ProgressScrubber(snapshot: _playback, onSeek: _seek),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _toggleFavorite(track),
                        icon: Icon(
                          track.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                      ),
                      const SizedBox(width: 18),
                      FilledButton(
                        onPressed: () async {
                          await _togglePlayback();
                          setSheetState(() {});
                        },
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(22),
                          backgroundColor: const Color(0xFF5DE2C5),
                          foregroundColor: const Color(0xFF07100E),
                        ),
                        child: Icon(
                          _playback.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 18),
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteTrack(track);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
