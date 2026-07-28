part of '../../main.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.path,
    required this.importedAt,
    required this.isFavorite,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final double duration;
  final String path;
  final DateTime importedAt;
  final bool isFavorite;

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: (map['id'] ?? '').toString(),
      title: _fallbackText(map['title'], 'Untitled Track'),
      artist: _fallbackText(map['artist'], 'Unknown Artist'),
      album: _fallbackText(map['album'], 'Offline Imports'),
      duration: _asDouble(map['duration']),
      path: (map['path'] ?? '').toString(),
      importedAt:
          DateTime.tryParse((map['importedAt'] ?? '').toString()) ??
          DateTime.now(),
      isFavorite: map['isFavorite'] == true,
    );
  }

  Track copyWith({String? path, bool? isFavorite}) {
    return Track(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      path: path ?? this.path,
      importedAt: importedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'path': path,
      'importedAt': importedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }
}

class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.trackId,
    required this.position,
    required this.duration,
    required this.isPlaying,
  });

  const PlaybackSnapshot.idle()
    : trackId = null,
      position = 0,
      duration = 0,
      isPlaying = false;

  final String? trackId;
  final double position;
  final double duration;
  final bool isPlaying;

  factory PlaybackSnapshot.fromMap(Map<String, dynamic> map) {
    return PlaybackSnapshot(
      trackId: map['trackId']?.toString(),
      position: _asDouble(map['position']),
      duration: _asDouble(map['duration']),
      isPlaying: map['isPlaying'] == true,
    );
  }
}
