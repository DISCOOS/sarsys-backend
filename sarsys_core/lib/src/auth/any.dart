import 'dart:async';

import 'package:aqueduct/aqueduct.dart';
import 'package:uuid/uuid.dart';

class AnyAuthorizer extends Controller {
  AnyAuthorizer(this.required, List<String> scopes) : validator = AnyAuthValidator(scopes);
  final List<String> required;
  final AnyAuthValidator validator;
  final AnyAuthorizationParser parser = AnyAuthorizationParser();

  @override
  FutureOr<RequestOrResponse> handle(Request request) async {
    request.authorization = await validator.any(parser);
    return request;
  }
}

/// Validates anything as valid.
///
class AnyAuthValidator extends AuthValidator {
  AnyAuthValidator(this.scopes);
  final List<String> scopes;

  FutureOr<Authorization> any<T>(AuthorizationParser<T> parser) async =>
      validate(parser, '', requiredScope: <AuthScope>[]);

  /// Returns an [Authorization] if [authorizationData] is valid.
  @override
  FutureOr<Authorization> validate<T>(
    AuthorizationParser<T> parser,
    T authorizationData, {
    List<AuthScope> requiredScope,
  }) =>
      Authorization(
        Uuid().v4(),
        null,
        this,
        scopes: List.from(requiredScope)
          ..addAll(
            scopes.map((claim) => AuthScope(claim)),
          ),
      );
}

class AnyAuthorizationParser extends AuthorizationParser<String> {
  @override
  String parse(String authorizationHeader) {
    return authorizationHeader;
  }
}
