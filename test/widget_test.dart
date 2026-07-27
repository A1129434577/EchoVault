import 'dart:async';

import 'package:echo_vault/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads the offline library and imports tracks', (tester) async {
    final service = FakeAudioService();

    await tester.pumpWidget(EchoVaultApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('NocturneBox'), findsOneWidget);
    expect(find.text('Midnight Cache'), findsOneWidget);
    expect(find.text('1 track'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    expect(find.text('Signal Bloom'), findsOneWidget);
    expect(find.text('2 tracks'), findsOneWidget);
  });
}

class FakeAudioService implements AudioService {
  final StreamController<PlaybackSnapshot> _events =
      StreamController<PlaybackSnapshot>.broadcast();

  List<Track> _tracks = [
    Track(
      id: 'track-1',
      title: 'Midnight Cache',
      artist: 'Local Archive',
      album: 'Offline Imports',
      duration: 186,
      path: 'midnight-cache.mp3',
      importedAt: DateTime(2026, 7, 14),
      isFavorite: false,
    ),
  ];

  @override
  Stream<PlaybackSnapshot> get playbackEvents => _events.stream;

  @override
  Future<List<Track>> loadLibrary() async => _tracks;

  @override
  Future<List<Track>> importAudio() async {
    _tracks = [
      ..._tracks,
      Track(
        id: 'track-2',
        title: 'Signal Bloom',
        artist: 'Local Archive',
        album: 'Offline Imports',
        duration: 241,
        path: 'signal-bloom.m4a',
        importedAt: DateTime(2026, 7, 14, 1),
        isFavorite: false,
      ),
    ];
    return _tracks;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(String id) async {
    _events.add(
      PlaybackSnapshot(
        trackId: id,
        position: 0,
        duration: _tracks.firstWhere((track) => track.id == id).duration,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(double seconds) async {}

  @override
  Future<bool> deleteTrack(String id) async {
    _tracks = _tracks.where((track) => track.id != id).toList();
    return true;
  }

  @override
  Future<Track?> toggleFavorite(String id) async {
    _tracks = _tracks.map((track) {
      return track.id == id
          ? track.copyWith(isFavorite: !track.isFavorite)
          : track;
    }).toList();
    return _tracks.firstWhere((track) => track.id == id);
  }
}
