import 'dart:convert';

import 'package:aqueduct/aqueduct.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

class AccessValidator extends AuthValidator {
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

    final t = _toToken(accessToken);
    if (t == null || t.isExpired) {
      throw AuthServerException(AuthRequestError.invalidGrant, null);
    }

    if (scopesRequired != null) {
      if (!AuthScope.verify(scopesRequired, t.scopes)) {
        throw AuthServerException(AuthRequestError.invalidScope, null);
      }
    }

    return Authorization(t.clientID, t.resourceOwnerIdentifier, this, scopes: t.scopes);
  }

  AuthToken _toToken(String accessToken) {
    final jwt = JwtClaim.fromMap(_fromJWT(accessToken));
    return AuthToken()
      ..type = 'bearer'
      ..clientID = jwt.issuer
      ..issueDate = jwt.issuedAt
      ..accessToken = accessToken
      ..expirationDate = jwt.expiry
      ..scopes = (jwt['roles'] as List<String>)?.map((scope) => AuthScope(scope))?.toList();
  }

  Map<String, dynamic> _fromJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }
    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }
    return payloadMap as Map<String, dynamic>;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }
}
