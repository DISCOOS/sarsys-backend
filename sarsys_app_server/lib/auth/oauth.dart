import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart' show MapX;
import 'package:jose/jose.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// Validates access tokens issued by an
/// [OAuth2 Server](https://www.oauth.com/oauth2-servers/authorization).
///
/// This validator only supports validation of access tokens passed as a
/// [Bearer token](https://swagger.io/docs/specification/authentication/bearer-authentication/) in an
/// [Authorization header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization).
class AccessTokenValidator extends AuthValidator {
  AccessTokenValidator(this.keyStore, this.config);
  final AuthConfig config;
  final JsonWebKeyStore keyStore;

  /// Returns an [Authorization] if [authorizationData] is valid.
  @override
  FutureOr<Authorization> validate<T>(
    AuthorizationParser<T> parser,
    T authorizationData, {
    List<AuthScope> requiredScope,
  }) {
    if (parser is AuthorizationBearerParser) {
      return verify(authorizationData as String, scopesRequired: requiredScope);
    }
    throw ArgumentError(
      "Invalid 'parser' for 'AccessValidator.validate'. Use 'AuthorizationBearerParser'.",
    );
  }

  /// Returns a [Authorization] for [accessToken].
  ///
  /// This method obtains an [AuthToken] for [accessToken] and then verifies that the token is valid.
  /// If the token is valid, an [Authorization] object is returned. Otherwise, an [AuthServerException] is thrown.
  Future<Authorization> verify(String accessToken, {List<AuthScope> scopesRequired}) async {
    if (accessToken == null) {
      throw AuthServerException(AuthRequestError.invalidRequest, null);
    }

    final token = await _toToken(accessToken);
    if (token == null ||
        token.isExpired ||
        !token.audience.contains(config.audience) ||
        token.issuer != Uri.parse(config.issuer)) {
      throw AuthServerException(AuthRequestError.invalidGrant, null);
    }

    if (scopesRequired != null) {
      if (!AuthScope.verify(scopesRequired, token.scopes)) {
        throw AuthServerException(AuthRequestError.invalidScope, null);
      }
    }

    return Authorization(token.clientID, token.resourceOwnerIdentifier, this, scopes: token.scopes);
  }

  Future<OAuth2Token> _toToken(String accessToken) async {
    final jwt = await JsonWebToken.decodeAndVerify(
      accessToken,
      keyStore,
      allowedArguments: [
        'RS256',
      ],
    );

    return OAuth2Token()
      ..type = 'bearer'
      ..clientID = jwt.claims.getTyped<String>('client_id')
      ..issuer = jwt.claims.issuer
      ..issueDate = jwt.claims.issuedAt
      ..audience = jwt.claims.getTypedList<String>('aud')
      ..accessToken = accessToken
      ..expirationDate = jwt.claims.expiry
      ..scopes = _toScopes({'roles': _toRoles(jwt.claims)}, []);
  }

  List<String> _toRoles(JsonWebTokenClaims claims) => List.from(
        claims.toJson().elementAt<List>(config.rolesClaim) ?? [],
      );

  List<AuthScope> _toScopes(Map<String, dynamic> claims, List<AuthScope> scopes) {
    claims.forEach((name, value) => _toScope(name, value, scopes));
    return scopes;
  }

  void _toScope(String claim, value, List<AuthScope> scopes) {
    if (value is String) {
      scopes.add(AuthScope("$claim:$value"));
    } else if (value is List) {
      scopes.addAll(value.map((value) => AuthScope("$claim:$value")));
    } else if (value == null) {
      scopes.add(AuthScope(claim));
    }
  }
}

class OAuth2Token extends AuthToken {
  Uri issuer;
  List<String> audience;
}
