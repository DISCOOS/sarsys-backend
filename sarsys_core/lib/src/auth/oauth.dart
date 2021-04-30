import 'dart:async';

import 'package:aqueduct/aqueduct.dart';
import 'package:collection_x/collection_x.dart' show MapX;

import 'package:jose/jose.dart';
import 'package:sarsys_core/sarsys_core.dart';

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

  /// Logger instance
  final Logger logger = Logger('AccessTokenValidator');

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

    final token = await parseToken(accessToken);
    _verifyGrant(token);

    if (scopesRequired != null) {
      _verifyScopes(scopesRequired, token);
    }

    return Authorization(
      token.clientID,
      token.resourceOwnerIdentifier,
      this,
      scopes: token.scopes,
    );
  }

  void _verifyScopes(List<AuthScope> scopesRequired, OAuth2Token token) {
    if (!AuthScope.verify(scopesRequired, token.scopes)) {
      logger.info(
        'Invalid scope: {Token for subject ${token?.subject} contains scopes ${token?.scopes}',
      );
      throw AuthServerException(AuthRequestError.invalidScope, null);
    }
  }

  void _verifyGrant(OAuth2Token token) {
    bool isNull;
    bool isExpired;
    bool isWrongAud;
    bool isWrongIss;
    if ((isNull = token == null) ||
        (isExpired = token.isExpired) ||
        (isWrongAud = !token.audience.contains(config.audience)) ||
        (isWrongIss = token.issuer != Uri.tryParse(config.issuer))) {
      logger.info(
        'Invalid grant: Reason {isNull: $isNull, isExpired: $isExpired, '
        'isWrongAud: $isWrongAud, isWrongIss: $isWrongIss for subject: ${token?.subject}}, $token, $config',
      );
      throw AuthServerException(AuthRequestError.invalidGrant, null);
    }
  }

  Future<OAuth2Token> parseToken(String accessToken) async {
    JsonWebToken jwt;
    try {
      jwt = await JsonWebToken.decodeAndVerify(
        accessToken,
        keyStore,
      );
    } on Exception {
      logger.info('Invalid token: $accessToken');
      throw AuthServerException(AuthRequestError.invalidToken, null);
    }

    return OAuth2Token()
      ..type = 'bearer'
      ..accessToken = accessToken
      ..issuer = jwt.claims.issuer
      ..subject = jwt.claims.subject
      ..issueDate = jwt.claims.issuedAt
      ..expirationDate = jwt.claims.expiry
      ..audience = jwt.claims.getTypedList<String>('aud')
      ..clientID = jwt.claims.getTyped<String>('client_id')
      ..scopes = _toScopes({'roles': _toRoles(jwt.claims)}, []);
  }

  List<String> _toRoles(JsonWebTokenClaims claims) => config.rolesClaims.fold(
        <String>[],
        (roles, claim) => roles..addAll(List.from(claims.toJson().elementAt<List>(claim) ?? [])),
      );

  List<AuthScope> _toScopes(Map<String, dynamic> claims, List<AuthScope> scopes) {
    claims.forEach((name, value) => _toScope(name, value, scopes));
    return scopes;
  }

  void _toScope(String claim, value, List<AuthScope> scopes) {
    if (value is String) {
      scopes.add(AuthScope('$claim:$value'));
    } else if (value is List) {
      scopes.addAll(value.map((value) => AuthScope('$claim:$value')));
    } else if (value == null) {
      scopes.add(AuthScope(claim));
    }
  }
}

class OAuth2Token extends AuthToken {
  Uri issuer;
  String subject;
  List<String> audience;

  @override
  String toString() {
    return 'OAuth2Token{subject: $subject, issuer: $issuer, '
        'audience: $audience, scopes: $scopes, accessToken: $accessToken}';
  }
}
