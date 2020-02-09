import 'dart:io';

import 'package:aqueduct/aqueduct.dart';

class SarSysConfig extends Configuration {
  SarSysConfig(String path) : super.fromFile(File(path));

  /// Tenant name
  String tenant;

  /// [EventStore](www.eventstore.org) config values
  EvenStoreConfig eventstore;

  /// EventStore prefix
  @optionalConfiguration
  String prefix;

  /// Debug flag.
  ///
  /// Adds headers 'x-node-name' and 'x-pod-name' to
  /// responses from environment variables 'NODE_NAME',
  /// 'POD_NAME', and 'POD_NAMESPACE', see k8s/sarsys.yaml
  @optionalConfiguration
  bool debug = false;

  /// Log level
  @optionalConfiguration
  String level = Level.INFO.name;
}

class TrackingConfig extends Configuration {
  TrackingConfig(String path) : super.fromFile(File(path));

  /// Tenant name
  String tenant;

  /// [EventStore](www.eventstore.org) config values
  EvenStoreConfig eventstore;

  /// EventStore prefix
  @optionalConfiguration
  String prefix;

  /// Debug flag.
  ///
  /// Adds headers 'x-node-name' and 'x-pod-name' to
  /// responses from environment variables 'NODE_NAME',
  /// 'POD_NAME', and 'POD_NAMESPACE', see k8s/sarsys.yaml
  @optionalConfiguration
  bool debug = false;

  /// Log level
  @optionalConfiguration
  String level = Level.INFO.name;
}

class EvenStoreConfig extends Configuration {
  EvenStoreConfig();

  /// The host of the database to connect to.
  ///
  /// This property is required.
  String host;

  /// The port of the database to connect to.
  ///
  /// This property is required.
  int port;

  /// A username for authenticating to the database.
  ///
  /// This property is required.
  String login;

  /// A password for authenticating to the database.
  ///
  /// This property is required.
  String password;
}
