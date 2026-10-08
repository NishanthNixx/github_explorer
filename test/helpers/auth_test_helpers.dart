import 'package:flutter_riverpod/misc.dart';
import 'package:github_explorer_starter/features/auth/data/auth_repository_impl.dart';
import 'package:github_explorer_starter/features/auth/data/mock_auth_server.dart';
import 'package:github_explorer_starter/features/auth/data/token_store.dart';

const Duration testTokenLifetime = Duration(minutes: 5);

MockAuthServer buildTestAuthServer({Duration lifetime = testTokenLifetime}) =>
    MockAuthServer(tokenLifetime: lifetime, latency: Duration.zero);

List<Override> authOverrides({
  required MockAuthServer server,
  required TokenStore tokenStore,
}) {
  return [
    mockAuthServerProvider.overrideWithValue(server),
    tokenStoreProvider.overrideWithValue(tokenStore),
  ];
}
