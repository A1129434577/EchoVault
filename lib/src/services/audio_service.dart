import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ad/ad.dart';
import 'package:echo_vault/src/models/track_model.dart';
import 'package:echo_vault/src/utils/audio_file_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

abstract class AppAudioService {
  Stream<PlaybackSnapshot> get playbackEvents;

  Future<List<TrackModel>> loadLibrary();
  Future<List<TrackModel>> importAudio();
  Future<void> play(String id);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(double seconds);
  Future<TrackModel?> toggleFavorite(String id);
  Future<bool> deleteTrack(String id);
}

class FlutterAudioService implements AppAudioService {
  FlutterAudioService() {
    Timer.periodic(const Duration(milliseconds: 500), (_) => _emitPlayback());
    _player.playerStateStream.listen(_handlePlayerState);
    _player.durationStream.listen((_) => _emitPlayback());
  }

  static const String _libraryKey = 'echoVault.library.v2';
  static const Set<String> _supportedAudioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'adts',
    'wav',
    'aif',
    'aiff',
    'aifc',
    'caf',
    'flac',
    'alac',
    'mp4',
    'm4b',
    'm4p',
    'm4r',
    '3gp',
    '3g2',
    'amr',
    'awb',
    'ogg',
    'oga',
    'opus',
    'webm',
    'weba',
    'wma',
    'ape',
    'mka',
    'ac3',
    'eac3',
    'dts',
    'au',
    'snd',
    'ra',
    'ram',
    'spx',
    'mid',
    'midi',
  };
  static final String _supportedAudioExtensionText = _supportedAudioExtensions
      .join(', ');

  final AudioPlayer _player = AudioPlayer();
  final StreamController<PlaybackSnapshot> _events =
      StreamController<PlaybackSnapshot>.broadcast();
  final List<TrackModel> _library = [];
  String? _currentTrackId;

  @override
  Stream<PlaybackSnapshot> get playbackEvents => _events.stream;

  @override
  Future<List<TrackModel>> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_libraryKey);
    final directory = await _musicDirectory();
    _library
      ..clear()
      ..addAll(_decodeTracks(raw));

    final existing = <TrackModel>[];
    for (final track in _library) {
      final file = await _resolveTrackFile(track, directory);
      if (await file.exists()) {
        existing.add(track.copyWith(path: file.path));
      }
    }

    _library
      ..clear()
      ..addAll(existing);
    await _saveLibrary();

    return List.unmodifiable(_library);
  }

  @override
  Future<List<TrackModel>> importAudio() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _supportedAudioExtensions.toList(),
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return List.unmodifiable(_library);
    }

    final directory = await _musicDirectory();
    var importedCount = 0;
    var skippedCount = 0;

    for (final picked in result.files) {
      final sourcePath = picked.path;
      if (sourcePath == null) {
        skippedCount += 1;
        continue;
      }

      final source = File(sourcePath);
      if (!await source.exists()) {
        skippedCount += 1;
        continue;
      }

      final extension = extensionFor(picked.name, fallbackPath: sourcePath);
      if (!_supportedAudioExtensions.contains(extension)) {
        skippedCount += 1;
        continue;
      }

      final title = titleFromFileName(picked.name);
      final destination = File(
        '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.$extension',
      );

      try {
        await source.copy(destination.path);
        final duration = await _probeDuration(destination.path);
        if (duration == null || duration <= 0) {
          await destination.delete();
          skippedCount += 1;
          continue;
        }
        _library.add(
          TrackModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            artist: 'Local File',
            album: 'Offline Imports',
            duration: duration,
            path: destination.path,
            importedAt: DateTime.now(),
            isFavorite: false,
          ),
        );
        importedCount += 1;
      } on FileSystemException catch (error) {
        throw PlatformException(code: 'copy_failed', message: error.message);
      }
    }

    if (importedCount == 0 && skippedCount > 0) {
      throw PlatformException(
        code: 'unsupported_file',
        message:
            'Choose a supported audio file: $_supportedAudioExtensionText.',
      );
    }

    await _saveLibrary();
    return List.unmodifiable(_library);
  }

  @override
  Future<void> play(String id) async {
    final track = _library.where((item) => item.id == id).firstOrNull;
    if (track == null) {
      throw PlatformException(code: 'not_found', message: 'Track not found.');
    }

    final file = await _resolveTrackFile(track);
    if (!await file.exists()) {
      throw PlatformException(
        code: 'missing_file',
        message: 'The imported audio file is missing.',
      );
    }

    try {
      _currentTrackId = id;
      await _player.setFilePath(file.path);
      await _player.play();
      _emitPlayback();
    } on PlayerException catch (error) {
      _currentTrackId = null;
      _emitPlayback();
      throw PlatformException(
        code: error.code.toString(),
        message: error.message ?? 'This audio file could not be played.',
      );
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _emitPlayback();
  }

  @override
  Future<void> resume() async {
    await _player.play();
    _emitPlayback();
  }

  @override
  Future<void> seek(double seconds) async {
    await _player.seek(Duration(milliseconds: (seconds * 1000).round()));
    _emitPlayback();
  }

  @override
  Future<TrackModel?> toggleFavorite(String id) async {
    final index = _library.indexWhere((track) => track.id == id);
    if (index == -1) {
      return null;
    }
    final updated = _library[index].copyWith(
      isFavorite: !_library[index].isFavorite,
    );
    _library[index] = updated;
    await _saveLibrary();
    return updated;
  }

  @override
  Future<bool> deleteTrack(String id) async {
    final index = _library.indexWhere((track) => track.id == id);
    if (index == -1) {
      return false;
    }

    final track = _library.removeAt(index);
    if (_currentTrackId == track.id) {
      await _player.stop();
      _currentTrackId = null;
      _emitPlayback();
    }

    final file = await _resolveTrackFile(track);
    if (await file.exists()) {
      await file.delete();
    }
    await _saveLibrary();
    return true;
  }

  Future<Directory> _musicDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/NocturneBox/Music');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<double?> _probeDuration(String path) async {
    final probe = AudioPlayer();
    try {
      final duration = await probe.setFilePath(path);
      return (duration?.inMilliseconds ?? 0) / 1000;
    } catch (_) {
      return null;
    } finally {
      await probe.dispose();
    }
  }

  Future<void> _saveLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _library.map((track) {
        final map = track.toMap();
        map['path'] = _fileName(track.path);
        return map;
      }).toList(),
    );
    await prefs.setString(_libraryKey, encoded);
  }

  Future<File> _resolveTrackFile(
    TrackModel track, [
    Directory? musicDirectory,
  ]) async {
    final storedFile = File(track.path);
    if (storedFile.isAbsolute && await storedFile.exists()) {
      return storedFile;
    }

    final directory = musicDirectory ?? await _musicDirectory();
    return File('${directory.path}/${_fileName(track.path)}');
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  List<TrackModel> _decodeTracks(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => TrackModel.fromMap(stringMap(item)))
        .toList(growable: false);
  }

  void _emitPlayback() {
    if (_events.isClosed) {
      return;
    }
    final duration = (_player.duration?.inMilliseconds ?? 0) > 0
        ? _player.duration!.inMilliseconds / 1000
        : _library
                  .where((track) => track.id == _currentTrackId)
                  .firstOrNull
                  ?.duration ??
              0;
    _events.add(
      PlaybackSnapshot(
        trackId: _currentTrackId,
        position: _player.position.inMilliseconds / 1000,
        duration: duration,
        isPlaying: _player.playing,
      ),
    );
  }

  void _handlePlayerState(PlayerState state) {
    if (state.processingState == ProcessingState.completed &&
        _library.isNotEmpty &&
        _currentTrackId != null) {
      final currentIndex = _library.indexWhere(
        (track) => track.id == _currentTrackId,
      );
      if (currentIndex != -1) {
        final nextIndex = (currentIndex + 1) % _library.length;
        unawaited(play(_library[nextIndex].id));
        return;
      }
    }
    _emitPlayback();
  }
}
