import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openid_client/openid_client_io.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:openid_client/openid_client.dart';
import 'package:sarsys_ops_cli/src/core.dart';

abstract class _AuthCommand extends BaseCommand {
  Future<Map<String, dynamic>> configure(Map<String, dynamic> config) async {
    final auth = Map<String, dynamic>.from(config['auth'] ?? {});
    var credential = _toCredential(auth);

    if (credential == null) {
      credential = await _authorize(auth); // this will open a browser

      // Store credential
      auth['credential'] = credential.toJson();
    }

    // return the user info
    writeln(green('  Fetching user information...'), stdout);
    final info = await credential.getUserInfo();
    writeln('  User: ${green(info.name)}', stdout);
    config['user'] = info.toJson();
    final response = await credential.getTokenResponse();
    writeln('  Access token expires in: ${green('${response.expiresIn.inMinutes} min')}', stdout);
    auth['tokens'] = response.toJson();
    config['auth'] = auth;
    return config;
  }

  Future<Credential> _authorize(Map auth) async {
    writeln(green('  Authorizing...'), stdout);
    final issuer = await Issuer.discover(Uri.parse(
      auth['discovery_uri'] as String ?? 'https://id.discoos.io/auth/realms/DISCOOS',
    ));
    final client = Client(issuer, auth['client_id'] as String ?? 'sarsys-app');

    // Create an authenticator
    final authenticator = Authenticator(client);

    // Starts the authentication
    return authenticator.authorize(); // this will open a browser
  }

  Credential _toCredential(Map auth) {
    final c = auth['credential'];
    if (c == null) {
      return null;
    }
    return Credential.fromJson(
      Map<String, dynamic>.from(auth['credential']),
    );
  }
}

class AuthCommand extends _AuthCommand {
  AuthCommand() {
    addSubcommand(AuthInitCommand());
    addSubcommand(AuthCheckCommand());
    addSubcommand(AuthUpdateCommand());
  }

  @override
  final name = 'auth';

  @override
  final description = 'auth is used to authenticate the user';
}

class AuthInitCommand extends _AuthCommand {
  AuthInitCommand();

  @override
  final name = 'init';

  @override
  final description = 'init is used to initialize credential';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Initialize credential:'), stdout);
    final file = File(globalResults['config'] ?? p.join(appDataDir, 'config.yaml'));
    final exists = file.existsSync();
    var config = <String, dynamic>{};
    if (exists) {
      config = Map<String, dynamic>.from(loadYaml(file.readAsStringSync()) ?? {});
    }
    if (config.isEmpty) {
      config = {
        'auth': {
          'client_id': 'sarsys-app',
          'discovery_uri': 'https://id.discoos.io/auth/realms/DISCOOS',
        }
      };
    }
    config = await configure(config);
    if (!exists) {
      file.createSync();
    }
    file.writeAsStringSync(jsonEncode(config));

    return buffer.toString();
  }
}

class AuthUpdateCommand extends _AuthCommand {
  AuthUpdateCommand();

  @override
  final name = 'update';

  @override
  final description = 'update is used to update credential';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Update credential:'), stdout);
    final path = globalResults['config'] ?? p.join(appDataDir, 'config.yaml');
    final file = File(path);
    final exists = file.existsSync();
    if (!exists) {
      throw StateError('configuration file $path does not exist');
    }
    final config = await configure(
      Map<String, dynamic>.from(loadYaml(
        file.readAsStringSync(),
      )),
    );
    file.writeAsStringSync(jsonEncode(config));

    return buffer.toString();
  }
}

class AuthCheckCommand extends _AuthCommand {
  AuthCheckCommand();

  @override
  final name = 'check';

  @override
  final description = 'check is used to check credential';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Check credential:'), stdout);
    final path = globalResults['config'] ?? p.join(appDataDir, 'config.yaml');
    final file = File(path);
    final exists = file.existsSync();
    if (exists) {
      final config = Map<String, dynamic>.from(loadYaml(
        file.readAsStringSync(),
      ));

      final auth = Map<String, dynamic>.from(config['auth']);
      var credential = _toCredential(auth);

      if (credential == null) {
        writeln(red('  Credential not found'), stdout);
      } else {
        // return the user info
        final info = UserInfo.fromJson(Map<String, dynamic>.from(
          config['user'],
        ));
        writeln('  User: ${green(info.name)}', stdout);

        final tokens = TokenResponse.fromJson(Map<String, dynamic>.from(
          auth['tokens'],
        ));
        writeln('  Access token expires in: ${green('${tokens.expiresIn.inMinutes} min')}', stdout);

        final json = _fromJWT(tokens.accessToken);
        final roles = [
          if (json.containsKey('roles')) ...json['roles'],
          if (json.containsKey('realm_access_roles')) ...json['realm_access_roles'],
        ];
        writeln('  Roles: ${green('$roles')}', stdout);
      }
    } else {
      writeln(red('  Configuration not initialized'), stdout);
      writeln(red("  run 'sarsysctl auth init'"), stdout);
    }

    return buffer.toString();
  }

  static Map<String, dynamic> _fromJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }
    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }
    return payloadMap;
  }

  static String _decodeBase64(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');
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
    return utf8.decode(
      base64Url.decode(output),
    );
  }
}
