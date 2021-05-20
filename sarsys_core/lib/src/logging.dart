import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:sentry/sentry.dart';
import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/src/context.dart';
import 'package:event_source/event_source.dart' show Context;
import 'package:stack_trace/stack_trace.dart';

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
        ),
        _sentryStackTraceFactory = SentryStackTraceFactory(
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

  final SentryStackTraceFactory _sentryStackTraceFactory;

  Level get level => _level;
  final Level _level;

  Future<void> init() {
    return Sentry.init(
      (options) => options
        ..dsn = _config.dsn
        ..environment = Platform.environment['POD_NAMESPACE'] ?? _tenant,
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
                    message: _limit(e.message),
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
        message: Message(_limit(record.message)),
        exception: toSentryException(record),
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

  static const int maxMessageLength = 200;

  String _limit(String message) => message.substring(
        0,
        min(maxMessageLength, message.length),
      );

  SentryException toSentryException(LogRecord record) {
    if (record.error == null) {
      return null;
    }
    return SentryException(
      value: _limit(record.error.toString()),
      type: record.error.runtimeType.toString(),
      stackTrace: SentryStackTrace(
        frames: _sentryStackTraceFactory.getStackFrames(
          record.stackTrace,
        ),
      ),
    );
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

/// converts [StackTrace] to [SentryStackFrames]
class SentryStackTraceFactory {
  SentryOptions _options;

  final _absRegex = RegExp('abs +([A-Fa-f0-9]+)');
  static const _stackTraceViolateDartStandard =
      'This VM has been configured to produce stack traces that violate the Dart standard.';

  SentryStackTraceFactory(SentryOptions options) {
    if (options == null) {
      throw ArgumentError('SentryOptions is required.');
    }
    _options = options;
  }

  /// returns the [SentryStackFrame] list from a stackTrace ([StackTrace] or [String])
  List<SentryStackFrame> getStackFrames(dynamic stackTrace) {
    if (stackTrace == null) return null;

    // TODO : fix : in release mode on Safari passing a stacktrace object fails, but works if it's passed as String
    final chain = (stackTrace is StackTrace)
        ? Chain.forTrace(stackTrace)
        : (stackTrace is String)
            ? Chain.parse(stackTrace)
            : Chain.parse('');

    final frames = <SentryStackFrame>[];
    var symbolicated = true;

    for (var t = 0; t < chain.traces.length; t += 1) {
      final trace = chain.traces[t];

      for (final frame in trace.frames) {
        // we don't want to add our own frames
        if (frame.package == 'sentry') {
          continue;
        }

        final member = frame.member;
        // ideally the language would offer us a native way of parsing it.
        if (member != null && member.contains(_stackTraceViolateDartStandard)) {
          symbolicated = false;
        }

        final stackTraceFrame = encodeStackTraceFrame(
          frame,
          symbolicated: symbolicated,
        );

        if (stackTraceFrame == null) {
          continue;
        }
        frames.add(stackTraceFrame);
      }

      // fill asynchronous gap
      if (t < chain.traces.length - 1) {
        frames.add(SentryStackFrame.asynchronousGapFrameJson);
      }
    }

    return frames.reversed.toList();
  }

  /// converts [Frame] to [SentryStackFrame]
  SentryStackFrame encodeStackTraceFrame(Frame frame, {bool symbolicated = true}) {
    final member = frame.member;

    SentryStackFrame sentryStackFrame;

    if (symbolicated) {
      final fileName = frame.uri.pathSegments.isNotEmpty ? frame.uri.pathSegments.last : null;

      final abs = '${_absolutePathForCrashReport(frame)}';

      sentryStackFrame = SentryStackFrame(
        absPath: abs,
        function: member,
        // https://docs.sentry.io/development/sdk-dev/features/#in-app-frames
        inApp: isInApp(frame),
        fileName: fileName,
        package: frame.package,
      );

      if (frame.line != null && frame.line >= 0) {
        sentryStackFrame = sentryStackFrame.copyWith(lineNo: frame.line);
      }

      if (frame.column != null && frame.column >= 0) {
        sentryStackFrame = sentryStackFrame.copyWith(colNo: frame.column);
      }
    } else {
      // if --split-debug-info is enabled, thats what we see:
      // warning:  This VM has been configured to produce stack traces that violate the Dart standard.
      // ***       *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
      // unparsed  pid: 30930, tid: 30990, name 1.ui
      // unparsed  build_id: '5346e01103ffeed44e97094ff7bfcc19'
      // unparsed  isolate_dso_base: 723d447000, vm_dso_base: 723d447000
      // unparsed  isolate_instructions: 723d452000, vm_instructions: 723d449000
      // unparsed      #00 abs 000000723d6346d7 virt 00000000001ed6d7 _kDartIsolateSnapshotInstructions+0x1e26d7
      // unparsed      #01 abs 000000723d637527 virt 00000000001f0527 _kDartIsolateSnapshotInstructions+0x1e5527
      // unparsed      #02 abs 000000723d4a41a7 virt 000000000005d1a7 _kDartIsolateSnapshotInstructions+0x521a7
      // unparsed      #03 abs 000000723d624663 virt 00000000001dd663 _kDartIsolateSnapshotInstructions+0x1d2663
      // unparsed      #04 abs 000000723d4b8c3b virt 0000000000071c3b _kDartIsolateSnapshotInstructions+0x66c3b

      // we are only interested on the #01, 02... items which contains the 'abs' addresses.
      final matches = _absRegex.allMatches(member);

      if (matches.isNotEmpty) {
        final abs = matches.elementAt(0).group(1);
        if (abs != null) {
          sentryStackFrame = SentryStackFrame(
            instructionAddr: '0x$abs',
            platform: 'native', // to trigger symbolication
          );
        }
      }
    }

    return sentryStackFrame;
  }

  /// A stack frame's code path may be one of "file:", "dart:" and "package:".
  ///
  /// Absolute file paths may contain personally identifiable information, and
  /// therefore are stripped to only send the base file name. For example,
  /// "/foo/bar/baz.dart" is reported as "baz.dart".
  ///
  /// "dart:" and "package:" imports are always relative and are OK to send in
  /// full.
  String _absolutePathForCrashReport(Frame frame) {
    if (frame.uri.scheme != 'dart' && frame.uri.scheme != 'package' && frame.uri.pathSegments.isNotEmpty) {
      return frame.uri.pathSegments.last;
    }

    return '${frame.uri}';
  }

  /// whether this frame comes from the app and not from Dart core or 3rd party librairies
  bool isInApp(Frame frame) {
    final scheme = frame.uri.scheme;

    if (scheme == null || scheme.isEmpty) {
      return true;
    }

    if (_options.inAppIncludes != null) {
      for (final include in _options.inAppIncludes) {
        if (frame.package != null && frame.package == include) {
          return true;
        }
      }
    }
    if (_options.inAppExcludes != null) {
      for (final exclude in _options.inAppExcludes) {
        if (frame.package != null && frame.package == exclude) {
          return false;
        }
      }
    }

    if (frame.isCore || (frame.uri.scheme == 'package' && frame.package == 'flutter')) {
      return false;
    }

    return true;
  }
}
