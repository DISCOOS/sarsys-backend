import 'dart:collection';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart' show Context;
import 'package:event_source/src/context.dart';
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
  }) {
    if (record.level >= _level) {
      final context = record.object is Context ? record.object as Context : null;
      final breadcrumbs = context?.causes
              ?.map((e) => Breadcrumb(
                    e.message,
                    e.timestamp,
                    level: toLevel(e),
                    category: e.category,
                    data: LinkedHashMap.from({'context.id': e.id})..addAll(e.data),
                  ))
              ?.toList() ??
          <Breadcrumb>[];
      breadcrumbs.sort(
        (b1, b2) => b1.timestamp.compareTo(b2.timestamp),
      );
      final event = Event(
        message: record.message,
        exception: record.error,
        stackTrace: record.stackTrace,
        loggerName: record.loggerName,
        tags: {
          'pod_name': Platform.environment['POD_NAME'],
        },
        level: _toSeverityLevel(record),
        release: Platform.environment['IMAGE'],
        serverName: Platform.environment['NODE_NAME'],
        environment: Platform.environment['POD_NAMESPACE'] ?? _config.tenant,
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

  static SeverityLevel toLevel(ContextEvent e) {
    switch (e.level) {
      case ContextLevel.debug:
        return SeverityLevel.debug;
      case ContextLevel.info:
        return SeverityLevel.info;
      case ContextLevel.warning:
        return SeverityLevel.warning;
      case ContextLevel.error:
        return SeverityLevel.error;
      default:
        return SeverityLevel.fatal;
    }
  }

  static SeverityLevel _toSeverityLevel(LogRecord record) {
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
