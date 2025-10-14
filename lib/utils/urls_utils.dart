String? rutubeIdFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final patterns = [
    RegExp(r'rutube\.ru/(?:video|shorts)/([A-Za-z0-9_-]+)/?'),
    RegExp(r'rutube\.ru/play/embed/([A-Za-z0-9_-]+)'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(url);
    if (m != null) return m.group(1);
  }
  return null;
}