import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openid_client/openid_client_io.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:openid_client/openid_client.dart';
import 'package:sarsys_ops_cli/src/core.dart';

class AuthCommand extends BaseCommand {
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

class AuthInitCommand extends BaseCommand {
  AuthInitCommand();

  @override
  final name = 'init';

  @override
  final description = 'init is used to initialize credential';

  @override
  FutureOr<String> run() async {
    writeln(highlight('> Initialize credential:'), stdout);
    final file = toConfigFile(this);
    var config = ensureConfig(file);
    config = await AuthUtils.configure(this, config);
    if (!file.existsSync()) {
      file.createSync();
    }
    file.writeAsStringSync(jsonEncode(config));

    return buffer.toString();
  }
}

class AuthUpdateCommand extends BaseCommand {
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
    final config = await AuthUtils.configure(
      this,
      Map<String, dynamic>.from(
        loadYaml(
          file.readAsStringSync(),
        ),
      ),
      force: true,
    );
    file.writeAsStringSync(jsonEncode(config));

    return buffer.toString();
  }
}

class AuthCheckCommand extends BaseCommand {
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
      var credential = AuthUtils.toCredential(auth);

      if (credential == null) {
        writeln(red('  Credential not found'), stdout);
      } else {
        // return the user info
        final info = UserInfo.fromJson(Map<String, dynamic>.from(
          config['user'],
        ));
        writeln('  User: ${green(info.name)}', stdout);

        final tokens = AuthUtils.writeExpiresIn(this, Map.from(auth['tokens']));
        if (tokens != null) {
          final json = AuthUtils.fromJWT(tokens.accessToken);
          final roles = [
            if (json.containsKey('roles')) ...json['roles'],
            if (json.containsKey('realm_access_roles')) ...json['realm_access_roles'],
          ];
          writeln('  Roles: ${green('$roles')}', stdout);
        }
      }
    } else {
      writeln(red('  Configuration not initialized'), stdout);
      writeln(red("  run 'sarsysctl auth init'"), stdout);
    }

    return buffer.toString();
  }
}

class AuthUtils {
  static Future<String> getToken(BaseCommand command) async {
    final file = toConfigFile(command);
    if (!file.existsSync()) {
      file.createSync();
    }
    final config = await configure(
      command,
      ensureConfig(file),
    );
    if (config != null) {
      writeConfig(file, config);
      final auth = config['auth'];
      final tokens = auth['tokens'];
      return tokens['access_token'];
    }
    return null;
  }

  static Future<Map<String, dynamic>> configure(
    BaseCommand command,
    Map<String, dynamic> config, {
    bool force = false,
  }) async {
    final auth = Map<String, dynamic>.from(config['auth'] ?? {});
    var tokens = Map<String, dynamic>.from(auth['tokens'] ?? {});
    var credential = toCredential(auth);
    final expired = writeExpiresIn(command, tokens) == null;
    if (force || credential == null || expired) {
      // This will open a browser
      credential = await authorize(command, auth);
      auth['credential'] = credential.toJson();
    }

    if (expired) {
      // Get user information
      command.writeln(green('  Fetching user information...'), stdout);
      final info = await credential.getUserInfo();
      command.writeln('  User: ${green(info.name)}', stdout);
      config['user'] = info.toJson();

      // Get new tokens
      final response = await credential.getTokenResponse();
      tokens = response.toJson();
      writeExpiresIn(command, tokens);
      config['auth'] = auth;
      auth['tokens'] = tokens;
    }
    return config;
  }

  static TokenResponse writeExpiresIn(BaseCommand command, Map<String, dynamic> tokens) {
    if (tokens != null) {
      final response = TokenResponse.fromJson(tokens);
      final expiresIn = response?.expiresAt?.difference(DateTime.now())?.inMinutes ?? 0;
      if (expiresIn > 0) {
        command.writeln(
          '  Access token expires in: ${green('$expiresIn min')}',
          stdout,
        );
        return response;
      }
    }
    command.writeln(red('  Access token is expired'), stdout);
    return null;
  }

  static Future<Credential> authorize(BaseCommand command, Map auth) async {
    command.writeln(green('  Authorizing...'), stdout);
    final issuer = await Issuer.discover(Uri.parse(
      auth['discovery_uri'] as String ?? 'https://id.discoos.io/auth/realms/DISCOOS',
    ));
    final client = Client(issuer, auth['client_id'] as String ?? 'sarsys-app');

    // Create an authenticator
    final authenticator = Authenticator(client);

    // Starts the authentication
    return authenticator.authorize(); // this will open a browser
  }

  static Credential toCredential(Map auth) {
    final c = auth['credential'];
    if (c == null) {
      return null;
    }
    return Credential.fromJson(
      Map<String, dynamic>.from(auth['credential']),
    );
  }

  static Map<String, dynamic> fromJWT(String token) {
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
