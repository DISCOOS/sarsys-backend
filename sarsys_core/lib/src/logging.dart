import 'dart:collection';
import 'dart:io';

import 'package:sentry/sentry.dart';
import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/src/context.dart';
import 'package:event_source/event_source.dart' show Context;

import 'config.dart';

class RemoteLogger {
  factory RemoteLogger(SentryConfig config, String tenant) {
    return _singleton ??= RemoteLogger._internal(config, tenant);
  }

  RemoteLogger._internal(SentryConfig config, String tenant)
      : _config = config,
        _tenant = tenant,
        _level = LoggerConfig.toLevel(
          config.level,
          defaultLevel: Level.SEVERE,
        ),
        _client = SentryClient(
          SentryOptions(
            dsn: config.dsn,
          ),
        );

  static RemoteLogger _singleton;

  String get tenant => _tenant;
  String _tenant;

  SentryConfig get config => _config;
  final SentryConfig _config;

  SentryClient get client => _client;
  final SentryClient _client;

  Level get level => _level;
  final Level _level;

  Future<void> init() {
    return Sentry.init(
      (options) => options.environment = Platform.environment['POD_NAMESPACE'] ?? _tenant,
    );
  }

  void log(
    LogRecord record, {
    String transaction,
  }) async {
    if (record.level >= _level) {
      final context = record.object is Context ? record.object as Context : null;
      final breadcrumbs = context?.causes
              ?.map((e) => Breadcrumb(
                    level: toLevel(e),
                    message: e.message,
                    category: e.category,
                    timestamp: e.timestamp,
                    data: LinkedHashMap.from({'context.id': e.id})..addAll(e.data),
                  ))
              ?.toList() ??
          <Breadcrumb>[];
      breadcrumbs.sort(
        (b1, b2) => b1.timestamp.compareTo(b2.timestamp),
      );
      final event = SentryEvent(
        message: Message(record.message),
        exception: record.error,
        logger: record.loggerName,
        tags: {
          'pod_name': Platform.environment['POD_NAME'],
        },
        level: _toSeverityLevel(record),
        release: Platform.environment['IMAGE'],
        serverName: Platform.environment['NODE_NAME'],
        environment: Platform.environment['POD_NAMESPACE'] ?? _tenant,
        transaction: transaction,
        extra: Platform.environment,
        breadcrumbs: breadcrumbs,
      );
      try {
        await _client.captureEvent(
          event,
          stackTrace: record.stackTrace,
        );
      } on Exception catch (e) {
        print(
          'Sentry failed to capture event: $event with error: $e',
        );
      }
    }
  }

  static SentryLevel toLevel(ContextEvent e) {
    switch (e.level) {
      case ContextLevel.debug:
        return SentryLevel.debug;
      case ContextLevel.info:
        return SentryLevel.info;
      case ContextLevel.warning:
        return SentryLevel.warning;
      case ContextLevel.error:
        return SentryLevel.error;
      default:
        return SentryLevel.fatal;
    }
  }

  static SentryLevel _toSeverityLevel(LogRecord record) {
    if (Level.SEVERE == record.level) {
      return SentryLevel.fatal;
    } else if (Level.WARNING == record.level) {
      return SentryLevel.warning;
    } else if (Level.INFO == record.level) {
      return SentryLevel.info;
    }
    return SentryLevel.debug;
  }
}
