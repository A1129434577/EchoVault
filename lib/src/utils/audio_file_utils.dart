import 'package:echo_vault/src/models/track_model.dart';

Map<String, dynamic> stringMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

String fallbackText(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String titleFromFileName(String fileName) {
  final clean = fileName.split('/').last.split('\\').last;
  final dot = clean.lastIndexOf('.');
  final title = dot > 0 ? clean.substring(0, dot) : clean;
  return title.trim().isEmpty ? 'Untitled Track' : title.trim();
}

String extensionFor(String fileName, {String? fallbackPath}) {
  final clean = fileName.trim().isEmpty
      ? (fallbackPath ?? '').split('/').last.split('\\').last
      : fileName.split('/').last.split('\\').last;
  final dot = clean.lastIndexOf('.');
  if (dot == -1 || dot == clean.length - 1) {
    return 'audio';
  }
  return clean.substring(dot + 1).toLowerCase();
}

List<TrackModel> sortTracks(List<TrackModel> tracks) {
  final sorted = tracks.toList();
  sorted.sort((a, b) => b.importedAt.compareTo(a.importedAt));
  return sorted;
}

String formatDuration(double seconds) {
  final value = seconds.isFinite ? seconds.round() : 0;
  final minutes = value ~/ 60;
  final remaining = value % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

String countLabel(int count, String noun) {
  return '$count $noun${count == 1 ? '' : 's'}';
}
