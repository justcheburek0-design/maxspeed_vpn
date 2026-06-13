/// Shared update info model — used by both native and stub.
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime publishedAt;
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
  });
}
