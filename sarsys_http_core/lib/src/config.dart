import 'dart:io';

import 'package:aqueduct/aqueduct.dart';

abstract class SarSysModuleConfig extends Configuration {
  SarSysModuleConfig();
  SarSysModuleConfig.fromFile(String path) : super.fromFile(File(path));

  /// Module URI as string
  String get url => '$scheme://$host';

  /// Module URI scheme
  ///
  /// Optional configuration
  @optionalConfiguration
  String scheme = 'http';

  /// Module host
  ///
  /// Optional configuration
  @optionalConfiguration
  String host;

  /// Module logging config
  @optionalConfiguration
  LoggerConfig logging = LoggerConfig();

  /// Module prefix
  @optionalConfiguration
  String prefix;

  /// Module tenant name
  @optionalConfiguration
  String tenant;

  /// Module authorization config
  @optionalConfiguration
  AuthConfig auth = AuthConfig();

  /// Module data config
  @optionalConfiguration
  DataConfig data = DataConfig();

  /// [EventStore](www.eventstore.org) config values
  @optionalConfiguration
  EvenStoreConfig eventstore;

  /// Debug flag.
  ///
  /// Adds headers 'x-node-name' and 'x-pod-name' to
  /// responses from environment variables 'NODE_NAME',
  /// 'POD_NAME', and 'POD_NAMESPACE', see k8s/server.yaml
  @optionalConfiguration
  bool debug = false;
}

class LoggerConfig extends Configuration {
  LoggerConfig();

  /// Logging print to stdout
  @optionalConfiguration
  bool stdout = true;

  /// Log level
  @optionalConfiguration
  String level = Level.INFO.name;

  /// Sentry.io config
  @optionalConfiguration
  SentryConfig sentry;

  static Level toLevel(
    String name, {
    Level defaultLevel = Level.INFO,
  }) {
    return Level.LEVELS.firstWhere(
      (level) => level.name.toUpperCase() == name.toUpperCase(),
      orElse: () => defaultLevel,
    );
  }
}

class SentryConfig extends Configuration {
  SentryConfig();

  /// Sentry.io DSN Uri
  String dsn;

  /// Capture all events above this level to remove logger.
  /// Use [Level.LEVELS] names
  @optionalConfiguration
  String level = Level.SEVERE.name;
}

class DataConfig extends Configuration {
  DataConfig();

  /// SARSys data path
  @optionalConfiguration
  String path;

  /// SARSys data enabled
  @optionalConfiguration
  bool enabled = false;

  /// SARSys snapshots config
  @optionalConfiguration
  SnapshotsConfig snapshots = SnapshotsConfig();
}

class SnapshotsConfig extends Configuration {
  SnapshotsConfig();

  /// SARSys snapshots enabled
  @optionalConfiguration
  bool enabled = false;

  /// SARSys automatic snapshots activated
  @optionalConfiguration
  bool automatic = true;

  /// SARSys snapshots keep number
  @optionalConfiguration
  int keep = 20;

  /// SARSys snapshots events applied threshold number
  @optionalConfiguration
  int threshold = 1000;
}

class AuthConfig extends Configuration {
  AuthConfig();

  /// Enabled flag
  ///
  /// This property is required.
  bool enabled = false;

  /// Token issuer
  ///
  @optionalConfiguration
  String issuer;

  /// Token audience
  ///
  @optionalConfiguration
  String audience;

  /// Base Server URL
  ///
  @optionalConfiguration
  String baseUrl;

  /// Path to roles claim in JWT
  ///
  @optionalConfiguration
  List<String> rolesClaims;

  /// Required scopes list
  ///
  @optionalConfiguration
  List<String> required;

  @override
  String toString() {
    return 'AuthConfig{enabled: $enabled, issuer: $issuer, audience: $audience, '
        'baseUrl: $baseUrl, rolesClaims: $rolesClaims, required: $required}';
  }
}

class EvenStoreConfig extends Configuration {
  EvenStoreConfig();

  /// The URI as string
  String get url => '$scheme://$host:$port';

  /// The URI scheme to connect with.
  ///
  /// This property is required.
  String scheme = 'http';

  /// The host of the database to connect to.
  ///
  /// This property is required.
  String host = '127.0.0.1';

  /// The port of the database to connect to.
  ///
  /// This property is required.
  int port = 2113;

  /// A username for authenticating to the database.
  ///
  /// This property is required.
  String login;

  /// A password for authenticating to the database.
  ///
  /// This property is required.
  String password;

  /// A password for authenticating to the database.
  ///
  /// This property is required.
  @optionalConfiguration
  bool requireMaster = false;
}
