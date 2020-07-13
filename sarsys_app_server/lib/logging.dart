import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:sentry/sentry.dart';

import 'config.dart';

class RemoteLogger {
  factory RemoteLogger(SarSysConfig config) {
    return _singleton ??= RemoteLogger._internal(config);
  }
  RemoteLogger._internal(SarSysConfig config)
      : _config = config,
        _level = LoggerConfig.toLevel(
          config.logging.sentry.level,
          defaultLevel: Level.SEVERE,
        ),
        _client = SentryClient(
          dsn: config.logging.sentry.dsn,
        );

  static RemoteLogger _singleton;

  SarSysConfig get config => _config;
  final SarSysConfig _config;

  SentryClient get client => _client;
  final SentryClient _client;

  Level get level => _level;
  final Level _level;

  void log(
    LogRecord record, {
    String transaction,
    List<Breadcrumb> breadcrumbs,
  }) {
    if (record.level >= _level) {
      final Event event = Event(
        message: record.message,
        exception: record.error,
        stackTrace: record.stackTrace,
        level: _toSeverityLevel(record),
        release: Platform.environment["IMAGE"],
        serverName: Platform.environment["NODE_NAME"],
        environment: Platform.environment["POD_NAMESPACE"] ?? _config.tenant,
        transaction: transaction,
        extra: Platform.environment,
        breadcrumbs: breadcrumbs,
      );
      try {
        _client.capture(event: event);
      } on Exception catch (e) {
        print(
          'Sentry failed to capture event: $event with error: $e',
        );
      }
    }
  }

  SeverityLevel _toSeverityLevel(LogRecord record) {
    if (Level.SEVERE == record.level) {
      return SeverityLevel.fatal;
    } else if (Level.WARNING == record.level) {
      return SeverityLevel.warning;
    } else if (Level.INFO == record.level) {
      return SeverityLevel.info;
    }
    return SeverityLevel.debug;
  }
}
