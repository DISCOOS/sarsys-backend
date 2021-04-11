import 'dart:convert';

import 'package:http/http.dart';
import 'package:jose/jose.dart';
import 'package:meta/meta.dart';

import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct/aqueduct.dart' as aq;
import 'package:collection_x/collection_x.dart';
import 'package:event_source/event_source.dart';

import 'auth/auth.dart';
import 'config.dart';
import 'schemas.dart';

/// Simple base implementation of http server using aqueduct.
abstract class SarSysServerChannelBase extends ApplicationChannel {
  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  @mustCallSuper
  void documentComponents(APIDocumentContext context) {
    documentSchemas(context);
    documentResponses(context);
    documentSecuritySchemas(context);
    super.documentComponents(context);
  }

  void documentSecuritySchemas(APIDocumentContext context) => context.securitySchemes
    ..register(
        'OpenId Connect',
        APISecurityScheme.openID(
          Uri.parse(
            'https://id.discoos.io/auth/realms/DISCOOS/.well-known/openid-configuration',
          ),
        ));

  @mustCallSuper
  void documentSchemas(APIDocumentContext context) => context.schema
    ..register('ID', documentID())
    ..register('UUID', documentUUID())
    ..register('AggregateResponse', documentAggregateResponse(context))
    ..register('AggregatePageResponse', documentAggregatePageResponse(context))
    ..register('EntityResponse', documentEntityResponse(context))
    ..register('EntityPageResponse', documentEntityPageResponse(context))
    ..register('ValueResponse', documentValueResponse(context))
    ..register('ValuePageResponse', documentValuePageResponse(context))
    ..register('AggregateRef', documentAggregateRef(context))
    ..register('AggregateList', documentAggregateList(context));

  APIComponentCollection<APIResponse> documentResponses(APIDocumentContext registry) {
    return registry.responses
      ..register(
          '200',
          APIResponse(
            'OK. Indicates that the request has succeeded. A 200 response is cacheable by default. '
            'The meaning of a success depends on the HTTP request method.',
          ))
      ..register(
          '201',
          APIResponse(
            'Created. The POST-ed resource was created.',
          ))
      ..register(
          '204',
          APIResponse(
            'No Content. The resource was updated.',
          ))
      ..register(
          '400',
          APIResponse(
            'Bad request. Request contains wrong or is missing required data',
          ))
      ..register(
          '401',
          APIResponse(
            'Unauthorized. The client must authenticate itself to get the requested response.',
          ))
      ..register(
          '403',
          APIResponse(
            'Forbidden. The client does not have access rights to the content.',
          ))
      ..register(
          '404',
          APIResponse(
            'Not found. The requested resource does not exist in server.',
          ))
      ..register(
          '405',
          APIResponse(
            'Method Not Allowed. The request method is known by the server but has been disabled and cannot be used.',
          ))
      ..register(
          '409',
          APIResponse(
            'Conflict. This response is sent when a request conflicts with the current state of the server.',
          ))
      ..register(
          '416',
          APIResponse(
            'Range Not Satisfiable. Indicates that a server cannot serve the requested ranges. '
            "The most likely reason is that the document doesn't contain such ranges, "
            "or that the Range header value, though syntactically correct, doesn't make sense.",
          ))
      ..register(
          '426',
          APIResponse(
            'Source or destination resource of a method is locked. Indicates that resource is read-only.',
          ))
      ..register(
          '429',
          APIResponse(
            'Too Many Requests. Indicates the user has sent too many requests in a given amount of time '
            "('rate limiting'). A Retry-After header might be included to this response indicating "
            'how long to wait before making a new request.',
          ))
      ..register(
          '500',
          APIResponse(
            'Internal Server Error. indicates that the server encountered an unexpected condition '
            "that prevented it from fulfilling the request. This error response is a generic 'catch-all' response",
          ))
      ..register(
          '503',
          APIResponse(
            'Service unavailable. The server is currently unable to handle the request due to a temporary '
            'overloading or maintenance of the server. The implication is that this is a temporary '
            'condition which will be alleviated after some delay. If known, the length of the delay MAY be '
            'indicated in a Retry-After header.',
          ))
      ..register(
          '504',
          APIResponse(
            'Gateway Timeout server. Indicates that the server, while acting as a gateway or proxy, '
            'did not get a response in time from the upstream server that it needed in order to complete the request.',
          ));
  }
}

class RequestContext {
  const RequestContext({
    @required this.correlationId,
    @required this.transactionId,
    @required this.inStickySession,
  });

  /// Get current correlation. A correlation id
  /// is created if header 'x-correlation-id'
  /// was missing.
  final String correlationId;

  /// Check if current request is in a sticky session
  final bool inStickySession;

  /// Get transaction id sticky session
  final String transactionId;
}

class SecureRouter extends Router {
  SecureRouter(this.config, this.scopes) : keyStore = JsonWebKeyStore();
  final AuthConfig config;
  final List<String> scopes;
  final JsonWebKeyStore keyStore;
  static final Map<RequestOrResponse, RequestContext> _contexts = {};

  static Map<String, RequestContext> getContexts() => Map.unmodifiable(_contexts);
  static RequestContext getContext(RequestOrResponse lookup) => _contexts[lookup];
  static bool hasContext(RequestOrResponse lookup) => _contexts.containsKey(lookup);

  Future<RequestOrResponse> setRequest(aq.Request request) async {
    final correlationId = request.raw.headers.value('x-correlation-id') ?? randomAlpha(16);
    final transactionId = request.raw.cookies
        // Find cookie for sticky session
        .where((c) => c.name == 'x-transaction-id')
        // Get transaction id
        .map((c) => c.value)
        .firstOrNull;
    final inStickySession = transactionId != null;
    request.addResponseModifier((r) {
      r.headers['x-correlation-id'] = correlationId;
      r.headers['x-transaction-id'] = transactionId;
      _contexts.remove(request);
    });
    _contexts[request] = RequestContext(
      correlationId: correlationId,
      transactionId: transactionId,
      inStickySession: inStickySession,
    );
    return request;
  }

  Future prepare() async {
    if (config.enabled) {
      final response = await get('${config.baseUrl}/.well-known/openid-configuration');
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body is Map<String, dynamic>) {
        if (body.containsKey('jwks_uri')) {
          keyStore.addKeySetUrl(Uri.parse(body['jwks_uri'] as String));
          return;
        }
      }
      throw 'Unexpected response from OpenID Connect Provider ${config.baseUrl}: $body';
    }
  }

  void secure(String pattern, Controller Function() creator) {
    super.route(pattern).linkFunction(setRequest).link(authorizer).link(creator);
  }

  Controller authorizer() {
    if (config.enabled) {
      return Authorizer.bearer(
        AccessTokenValidator(
          keyStore,
          config,
        ),
        scopes: config.required,
      );
    }
    return AnyAuthorizer(config.required, scopes);
  }
}
