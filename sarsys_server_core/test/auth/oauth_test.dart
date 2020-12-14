import 'package:test/test.dart';
import 'package:sarsys_server_core/sarsys_server_core.dart';

import 'harness.dart';

Future main() async {
  final harness = AuthHarness()..install();

  test('AccessTokenValidator SHOULD verify WITHOUT roles claims', () {
    // Arrange
    final validator = AccessTokenValidator(harness.keyStore, harness.config);
    final accessToken = harness.accessToken;

    // Act
    validator.verify(accessToken);
  });

  test('AccessTokenValidator SHOULD verify WITH roles claims', () async {
    // Arrange
    final validator = AccessTokenValidator(harness.keyStore, harness.config);
    final accessToken = harness.newAccessToken(roles: {
      'roles': [
        'personnel',
        'commander',
      ],
      'realm_access_roles': [
        'unit_leader',
        'admin',
        'uma_authorization',
      ],
    });
    const parser = AuthorizationBearerParser();

    // Act
    final request = validator.validate(parser, accessToken);

    // Act and assert
    await expectLater(await request, isA<Authorization>());
  });

  test('AccessTokenValidator SHOULD accept any roles claims', () async {
    // Arrange
    final validator = AccessTokenValidator(harness.keyStore, harness.config);
    final accessToken = harness.newAccessToken(roles: {
      'roles': [
        'personnel',
        'commander',
      ],
      'realm_access_roles': [
        'admin',
        'unit_leader',
        'uma_authorization',
      ],
    });
    const parser = AuthorizationBearerParser();

    // Act
    final request = validator.validate(parser, accessToken);

    // Act and assert
    await expectLater(await request, isA<Authorization>());
  });

  test('AccessTokenValidator SHOULD accepts required roles claims', () async {
    // Arrange
    final validator = AccessTokenValidator(harness.keyStore, harness.config);
    final accessToken = harness.newAccessToken(roles: {
      'roles': [
        'personnel',
        'unit_personnel',
      ],
      'realm_access_roles': [
        'oversight',
        'commander',
      ],
    });
    const parser = AuthorizationBearerParser();

    // Act
    final request = validator.validate(parser, accessToken, requiredScope: [
      AuthScope('roles:personnel'),
      AuthScope('roles:commander'),
    ]);

    // Act and assert
    await expectLater(await request, isA<Authorization>());
  });

  test('AccessTokenValidator SHOULD rejects when required roles claims are missing', () async {
    // Arrange
    final validator = AccessTokenValidator(harness.keyStore, harness.config);
    final accessToken = harness.newAccessToken(roles: {
      'roles': [
        'unit_personnel',
      ],
      'realm_access_roles': [
        'oversight',
      ],
    });
    const parser = AuthorizationBearerParser();

    // Act
    final request = validator.validate(parser, accessToken, requiredScope: [
      AuthScope('roles:personnel'),
      AuthScope('roles:commander'),
    ]);

    // Act and assert
    await expectLater(
        () => request,
        throwsA(isA<AuthServerException>().having(
          (e) => e.reason,
          'Reason SHOULD BE invalid scope',
          AuthRequestError.invalidScope,
        )));
  });
}
