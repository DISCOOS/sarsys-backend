import 'package:jose/jose.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

class AuthHarness {
  JsonWebKey get privateKey => _privateKey;
  JsonWebKey _privateKey;

  JsonWebKey get publicKey => _publicKey;
  JsonWebKey _publicKey;

  JsonWebTokenClaims get claims => _claims;
  JsonWebKeyStore _keyStore;

  JsonWebKeyStore get keyStore => _keyStore;
  JsonWebTokenClaims _claims;

  JsonWebSignatureBuilder get builder => _builder;
  JsonWebSignatureBuilder _builder;

  JsonWebSignature get signature => _signature;
  JsonWebSignature _signature;

  String get accessToken => _signature.toCompactSerialization();

  String get iss => _iss;
  String _iss = 'https://id.discoos.io/auth/realms/DISCOOS';

  String get aud => _aud;
  String _aud = 'sarsys-app';

  List<String> get required => _required;
  List<String> _required = const ['roles:personnel'];

  List<String> get rolesClaims => _rolesClaims;
  List<String> _rolesClaims = const ['roles', 'realm_access_roles'];

  AuthConfig get config => _config;
  AuthConfig _config;

  void install() {
    // Create keys
    _publicKey = JsonWebKey.fromJson({
      'kid': 'public123',
      'kty': 'RSA',
      'use': 'enc',
      'key_ops': <String>[
        'verify',
      ],
      'n': '0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx'
          '4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMs'
          'tn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2'
          'QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbI'
          'SD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqb'
          'w0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw',
      'e': 'AQAB',
      'alg': 'RS256',
    });

    _privateKey = JsonWebKey.fromJson({
      'kid': 'private123',
      'kty': 'RSA',
      'n': '0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4'
          'cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMst'
          'n64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2Q'
          'vzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbIS'
          'D08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw'
          '0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw',
      'e': 'AQAB',
      'd': 'X4cTteJY_gn4FYPsXB8rdXix5vwsg1FLN5E3EaG6RJoVH-HLLKD9'
          'M7dx5oo7GURknchnrRweUkC7hT5fJLM0WbFAKNLWY2vv7B6NqXSzUvxT0_YSfqij'
          'wp3RTzlBaCxWp4doFk5N2o8Gy_nHNKroADIkJ46pRUohsXywbReAdYaMwFs9tv8d'
          '_cPVY3i07a3t8MN6TNwm0dSawm9v47UiCl3Sk5ZiG7xojPLu4sbg1U2jx4IBTNBz'
          'nbJSzFHK66jT8bgkuqsk0GjskDJk19Z4qwjwbsnn4j2WBii3RL-Us2lGVkY8fkFz'
          'me1z0HbIkfz0Y6mqnOYtqc0X4jfcKoAC8Q',
      'p': '83i-7IvMGXoMXCskv73TKr8637FiO7Z27zv8oj6pbWUQyLPQBQxtPV'
          'nwD20R-60eTDmD2ujnMt5PoqMrm8RfmNhVWDtjjMmCMjOpSXicFHj7XOuVIYQyqV'
          'WlWEh6dN36GVZYk93N8Bc9vY41xy8B9RzzOGVQzXvNEvn7O0nVbfs',
      'q': '3dfOR9cuYq-0S-mkFLzgItgMEfFzB2q3hWehMuG0oCuqnb3vobLyum'
          'qjVZQO1dIrdwgTnCdpYzBcOfW5r370AFXjiWft_NGEiovonizhKpo9VVS78TzFgx'
          'kIdrecRezsZ-1kYd_s1qDbxtkDEgfAITAG9LUnADun4vIcb6yelxk',
      'dp': 'G4sPXkc6Ya9y8oJW9_ILj4xuppu0lzi_H7VTkS8xj5SdX3coE0oim'
          'YwxIi2emTAue0UOa5dpgFGyBJ4c8tQ2VF402XRugKDTP8akYhFo5tAA77Qe_Nmtu'
          'YZc3C3m3I24G2GvR5sSDxUyAN2zq8Lfn9EUms6rY3Ob8YeiKkTiBj0',
      'dq': 's9lAH9fggBsoFR8Oac2R_E2gw282rT2kGOAhvIllETE1efrA6huUU'
          'vMfBcMpn8lqeW6vzznYY5SSQF7pMdC_agI3nG8Ibp1BUb0JUiraRNqUfLhcQb_d9'
          'GF4Dh7e74WbRsobRonujTYN1xCaP6TO61jvWrX-L18txXw494Q_cgk',
      'qi': 'GyM_p6JrXySiz1toFgKbWV-JdI3jQ4ypu9rbMWx3rQJBfmt0FoYzg'
          'UIZEVFEcOqwemRN81zoDAaa-Bk0KWNGDjJHZDdDmFhW3AN7lI-puxk_mHZGJ11rx'
          'yR8O55XLSe3SPmRfKwZI6yU24ZxvQKFYItdldUKGzO6Ia6zTKhAVRU',
      'alg': 'RS256',
      'use': 'sig',
      'key_ops': <String>[
        'sign',
        'verify',
      ],
    });

    // Add key to keystore
    _keyStore = JsonWebKeyStore();
    _keyStore.addKey(_publicKey);
    _keyStore.addKey(_privateKey);

    // Create mandatory claims
    _claims = JsonWebTokenClaims.fromJson({
      'exp': toSecondSinceEpoch(4),
      'iss': _iss,
      'aud': _aud,
    });

    // Create a builder, decoding the JWT in a JWS, so using a
    // JsonWebSignatureBuilder
    _builder = JsonWebSignatureBuilder();

    // set the content
    _builder.jsonContent = _claims.toJson();

    // Add a key to sign, can only add one for JWT
    _builder.addRecipient(_privateKey, algorithm: 'RS256');

    // build the jws
    _signature = _builder.build();

    // Build config
    _config = AuthConfig()
      ..issuer = _iss
      ..audience = _aud
      ..required = required
      ..rolesClaims = _rolesClaims;
  }

  int toSecondSinceEpoch(int hours) => DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch ~/ 1000;

  AuthHarness withIssuer({
    String iss = 'https://id.discoos.io/auth/realms/DISCOOS',
  }) {
    _iss = iss;
    return this;
  }

  AuthHarness withAudience({
    String aud = 'sarsys-app',
  }) {
    _aud = aud;
    return this;
  }

  AuthHarness withRequiredScopes({
    List<String> required = const ['roles:personnel'],
  }) {
    _required = required;
    return this;
  }

  AuthHarness withRolesClaims({
    List<String> rolesClaims = const [
      'roles',
      'realm_access_roles',
    ],
  }) {
    _rolesClaims = rolesClaims;
    return this;
  }

  String newAccessToken({
    String aud,
    String iss,
    Map<String, dynamic> roles,
  }) {
    final claims = JsonWebTokenClaims.fromJson({
      'exp': toSecondSinceEpoch(4),
      'iss': iss ?? _iss,
      'aud': aud ?? _aud,
    }..addAll(roles));

    // Create a builder, decoding the JWT in a JWS, so using a
    // JsonWebSignatureBuilder
    final builder = JsonWebSignatureBuilder();

    // set the content
    builder.jsonContent = claims.toJson();

    // Add a key to sign, can only add one for JWT
    builder.addRecipient(_privateKey, algorithm: 'RS256');

    // Build the jws
    final signature = builder.build();

    // Return as access token in serialized form
    return signature.toCompactSerialization();
  }
}
