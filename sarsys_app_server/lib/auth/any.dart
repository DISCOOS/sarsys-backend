import 'package:aqueduct/aqueduct.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:uuid/uuid.dart';

class AnyAuthorizer extends Controller {
  AnyAuthorizer(this.required, List<String> scopes) : validator = AnyAuthValidator(scopes);
  final List<String> required;
  final AnyAuthValidator validator;
  final AnyAuthorizationParser parser = AnyAuthorizationParser();

  @override
  FutureOr<RequestOrResponse> handle(Request request) async {
    request.authorization = await validator.any(parser);
    return _addScopeRequirementModifier(request);
  }

  Request _addScopeRequirementModifier(Request request) {
    // If a controller returns a 403 because of invalid scope,
    // this Authorizer adds its required scope as well.
    if (required != null) {
      request.addResponseModifier((resp) {
        if (resp.statusCode == 403 && resp.body is Map) {
          final body = resp.body as Map<String, dynamic>;
          if (body.containsKey("scope")) {
            final declaredScopes = (body["scope"] as String).split(" ");
            final scopesToAdd = required.map((s) => s.toString()).where((s) => !declaredScopes.contains(s));
            body["scope"] = [scopesToAdd, declaredScopes].expand((i) => i).join(" ");
          }
        }
      });
    }
    return request;
  }
}

/// Validates anything as valid.
///
class AnyAuthValidator extends AuthValidator {
  AnyAuthValidator(this.scopes);
  final List<String> scopes;

  FutureOr<Authorization> any<T>(AuthorizationParser<T> parser) async =>
      validate(parser, "", requiredScope: <AuthScope>[]);

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
