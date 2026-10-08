abstract final class DeepLinks {
  static const String scheme = 'myapp';

  static final RegExp _githubLogin = RegExp(
    r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$',
  );

  static String? toLocation(
    Uri uri, {
    required String Function(String username) userLocation,
    required String favoritesLocation,
    required String fallbackLocation,
  }) {
    if (uri.scheme != scheme) return null;

    final segments = [
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
    ];

    return switch (segments) {
      ['user', final username] when _githubLogin.hasMatch(username) =>
        userLocation(username),
      ['favorites'] => favoritesLocation,
      _ => fallbackLocation,
    };
  }

  static Uri user(String username) =>
      Uri(scheme: scheme, host: 'user', path: '/$username');
}
