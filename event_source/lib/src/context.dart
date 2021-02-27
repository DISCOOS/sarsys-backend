import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:event_source/event_source.dart';
import 'package:event_source/src/util.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:random_string/random_string.dart';
import 'package:stack_trace/stack_trace.dart';

import 'extension.dart';

/// Context class
class Context {
  Context(
    this.logger, {
    String id,
    this.previous,
    this.capacity = 20,
    this.packages = const [],
    List<ContextEvent> causes = const [],
  })  : id = id ?? randomAlpha(16),
        _causes = List.from(causes) ?? <ContextEvent>[];

  final String id;
  final int capacity;
  final Logger logger;
  final Context previous;
  final List<String> packages;
  final List<ContextEvent> _causes;

  bool get isEmpty => _causes.isEmpty;
  bool get isNotEmpty => _causes.isNotEmpty;

  int get seen => _seen + (previous?.seen ?? 0);
  int _seen = 0;

  int get length {
    if (previous == null) {
      return _causes.length;
    }
    return previous._causes.length + _causes.length;
  }

  List<ContextEvent> get causes {
    if (previous == null) {
      return List.unmodifiable(_causes);
    }
    return previous._causes + _causes;
  }

  bool isLoggable(ContextLevel level) => logger.isLoggable(toLogLevel(level));

  Context join(Context context) {
    if (context == null || context == this) {
      return this;
    }
    return Context(
      logger,
      id: context.id,
      previous: this,
      causes: _causes,
      capacity: capacity,
      packages: packages,
    );
  }

  ContextEvent debug(
    String message, {
    @required String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    return _log(
      message,
      ContextLevel.debug,
      data: data,
      error: error,
      category: category,
      timestamp: timestamp,
      stackTrace: stackTrace,
    );
  }

  ContextEvent info(
    String message, {
    @required String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    return _log(
      message,
      ContextLevel.info,
      data: data,
      error: error,
      category: category,
      timestamp: timestamp,
      stackTrace: stackTrace,
    );
  }

  ContextEvent warning(
    String message, {
    @required String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    return _log(
      message,
      ContextLevel.warning,
      data: data,
      error: error,
      category: category,
      timestamp: timestamp,
      stackTrace: stackTrace,
    );
  }

  ContextEvent error(
    String message, {
    @required String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    return _log(
      message,
      ContextLevel.error,
      data: data,
      error: error,
      category: category,
      timestamp: timestamp,
      stackTrace: stackTrace,
    );
  }

  ContextEvent fatal(
    String message, {
    @required String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    return _log(
      message,
      ContextLevel.fatal,
      data: data,
      error: error,
      category: category,
      timestamp: timestamp,
      stackTrace: stackTrace,
    );
  }

  ContextEvent log(
    ContextLevel level,
    String message, {
    @required String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    return _log(
      message,
      level,
      data: data,
      error: error,
      category: category,
      timestamp: timestamp,
      stackTrace: stackTrace,
    );
  }

  ContextEvent _log(
    String message,
    ContextLevel level, {
    String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    final event = add(
      level,
      message,
      data: data,
      error: error,
      category: category,
      timestamp: timestamp,
      stackTrace: stackTrace,
    );
    final logLevel = toLogLevel(level);
    if (logLevel == Level.SEVERE) {
      logger.network(
        _copy(this),
        error,
        stackTrace,
      );
    } else {
      logger.log(
        logLevel,
        _copy(this),
        error,
        stackTrace,
      );
    }
    return event;
  }

  ContextEvent add(
    ContextLevel level,
    String message, {
    String category,
    DateTime timestamp,
    Object error,
    StackTrace stackTrace,
    Map<String, String> data = const {},
  }) {
    ContextEvent event;
    final logLevel = toLogLevel(level);
    if (logger.isLoggable(logLevel)) {
      data = data is Map<String, String> ? LinkedHashMap.from(data) : <String, String>{};
      event = ContextEvent(
        level: level,
        message: message,
        category: category,
        id: id,
        data: sortMapKeys(data
          ..addAll({
            'context.length': '$length',
            if (previous != null) 'context.previous': '$previous',
            if (previous != null) 'context.previous.length': '${previous.length}',
            if (error != null) 'error': '$error',
            if (stackTrace != null)
              'stackTrace': formatStackTrace(
                stackTrace,
                terse: true,
                packages: packages,
              ),
          })),
        timestamp: timestamp ?? DateTime.now(),
      );

      _seen++;

      // Limit number of causes to keep
      if (_causes.length >= capacity) {
        _causes.remove(_causes.first);
      }
      _causes.add(
        event,
      );
    }
    return event;
  }

  static String formatStackTrace(
    StackTrace stackTrace, {
    List<String> packages = const [],
    int depth = 10,
    bool terse = true,
  }) {
    var i = 0;
    return Trace.format(
      Trace.from(stackTrace).foldFrames(
        (frame) =>
            // First check if frame should be folded based upon package name
            packages.isNotEmpty &&
                !packages.any(
                  (package) => frame.package?.startsWith(package) == true,
                ) ||
            // Else, increment depth and check if
            // maximum is reached (all successive
            // frames are folded)
            ++i > depth,
        terse: terse,
      ),
      terse: terse,
    );
  }

  @override
  String toString() {
    if (isEmpty) {
      return 'Empty context';
    }
    return _causes.last?.message;
  }

  static String toStackTraceString(String prefix, StackTrace stackTrace, {bool terse = true}) {
    var trace = stackTrace is Trace ? stackTrace : Trace.from(stackTrace);
    if (terse) {
      trace = trace.terse;
    }

    final frames = trace.frames;

    // Figure out the longest path so we know how much to pad.
    var longest = frames.map((frame) => frame.location.length).fold(0, max);

    // Print out the stack trace nicely formatted.
    return frames.map((frame) {
      if (frame is UnparsedFrame) return '$frame';
      return '${prefix}${frame.location.padRight(longest)}  ${frame.member}';
    }).join('\n');
  }

  static void printRecord(LogRecord record, {bool debug = false}) {
    final context = record.object is Context ? record.object as Context : null;
    final contextId = context?.id ?? '';

    // Build log-line prefix
    final buffer = StringBuffer();
    buffer.write('${record.time.toIso8601String()}: ${record.level.name}: ');
    buffer.write('${record.loggerName}: ');
    if (Platform.environment.containsKey('POD_NAME')) {
      buffer.write('${Platform.environment['POD_NAME']}: ');
    }
    if (context != null) {
      buffer.write('contextId: $contextId: ');
    }
    final prefix = buffer.toString();

    // Build log-line postfix
    final postfix = StringBuffer();
    if (context != null && debug) {
      final event = context._causes.last;
      final category = '${prefix}${event.category}';
      event.data.forEach((key, value) {
        if (!const ['error', 'stackTrace'].contains(key)) {}
        postfix.writeln('${toObject(category, ['$key: $value'])}');
      });
    }
    if (record.error != null) {
      postfix.writeln('${prefix}Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      postfix.write(
        '${Context.toStackTraceString(prefix, record.stackTrace)}',
      );
    }
    stdout.writeln('$prefix${record.message}');
    if (postfix.isNotEmpty) {
      final lines = '$postfix';
      if (lines.endsWith('\n')) {
        stdout.write(lines);
      } else {
        stdout.writeln(lines);
      }
    }
  }

  static String toMethod(String name, [List<String> args = const []]) => '$name(${args.join(',  ')})';
  static String toObject(String name, [List<String> args = const []]) => '$name: {${args.join(', ')}}';

  static Level toLogLevel(ContextLevel level) {
    switch (level) {
      case ContextLevel.debug:
        return Level.FINE;
      case ContextLevel.info:
        return Level.INFO;
      case ContextLevel.warning:
        return Level.WARNING;
      case ContextLevel.error:
        return Level.SEVERE;
      default:
        return Level.SHOUT;
    }
  }

  static Context _copy(Context context) {
    return Context(
      context.logger,
      id: context.id,
      causes: context._causes,
      packages: context.packages,
      capacity: context.capacity,
    );
  }
}

enum ContextLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class ContextEvent {
  ContextEvent({
    @required this.level,
    @required this.message,
    @required this.id,
    @required this.timestamp,
    this.category,
    this.instances = 1,
    Map<String, String> data = const {},
  }) : _data = LinkedHashMap.from(data ?? {});
  final int instances;
  final String message;
  final String category;
  final String id;
  final ContextLevel level;
  final DateTime timestamp;
  final Map<String, String> _data;

  Map<String, String> get data => Map.unmodifiable(_data);

  ContextEvent newInstance() => ContextEvent(
        data: data,
        level: level,
        message: message,
        category: category,
        timestamp: timestamp,
        id: id,
        instances: instances + 1,
      );

  @override
  String toString() {
    return '$message';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data,
        'message': message,
        'category': category,
        'instances': instances,
        'level': enumName(level),
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextEvent &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          category == other.category &&
          id == other.id &&
          level == other.level &&
          timestamp == other.timestamp &&
          data == other.data;

  @override
  int get hashCode =>
      message.hashCode ^ category.hashCode ^ id.hashCode ^ level.hashCode ^ timestamp.hashCode ^ data.hashCode;
}
