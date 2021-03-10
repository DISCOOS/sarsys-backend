import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_ops_cli/sarsys_ops_cli.dart';
import 'package:strings/strings.dart';
import 'package:timeago/timeago.dart' as tgo;

import 'core.dart';

class SimulateCommand extends BaseCommand {
  SimulateCommand() {
    addSubcommand(SimulateDeviceCommand());
  }

  @override
  final name = 'simulate';

  @override
  final description = 'is used to simulate aggregate instances';
}

class SimulateDeviceCommand extends BaseCommand {
  SimulateDeviceCommand() {
    argParser
      ..addOption(
        'batch',
        abbr: 'b',
        defaultsTo: '5',
        help: 'Number of positions in each batch',
      )
      ..addOption(
        'pps',
        defaultsTo: '20',
        help: 'Requested positions per second',
      )
      ..addOption(
        'limit',
        abbr: 'l',
        help: 'Upper limit of positions to take from file',
      )
      ..addFlag(
        'summary',
        abbr: 's',
        defaultsTo: false,
        help: 'Show summary on completion',
      )
      ..addMultiOption(
        'file',
        abbr: 'f',
        help: 'Path to file with device track as json',
      );
  }

  @override
  final name = 'device';

  @override
  final description = 'is used to simulate device position changes';

  @override
  FutureOr<String> run() async {
    const columns = 90;
    final tracks = <String, List<Map<String, dynamic>>>{};
    // Sanity checks
    final files = argResults['file'] as List<String>;
    if (files.isEmpty) {
      usageException(red(' File is missing'));
      return writeln(red(' File is missing'), stderr);
    }
    final offsets = <String, int>{};
    final numbers = <String, int>{};
    final verbose = globalResults['verbose'] as bool;
    final pps = int.parse(argResults['pps'] as String);
    final batch = int.parse(argResults['batch'] as String);
    final limit = int.parse(argResults['limit'] as String ?? '0');
    writeln(highlight('> Simulate ${files.length} devices with pps $pps'), stdout);
    var total = 0;
    for (var path in files) {
      final file = File(path);
      if (!file.existsSync()) {
        usageException(red(' Simulate data file ${file.path} does not exist'));
        return writeln(red(' Simulate data file ${file.path} does not exist'), stderr);
      }
      final data = Map.from(
        jsonDecode(file.readAsStringSync()),
      );
      final uuid = data.elementAt('source/uuid');
      final track = data.listAt<Map<String, dynamic>>('positions');
      // Limit number of positions taken from file
      tracks[uuid] = track.take(limit > 0 ? min(track.length, limit) : track.length).toList();
      if (verbose) {
        final buffer = StringBuffer();
        vprint(
          'Device',
          '$uuid',
          max: columns,
          buffer: buffer,
        );
        vprint(
          'Positions',
          '${track.length}',
          max: columns,
          left: 14,
          indent: 4,
          buffer: buffer,
        );
        writeln(buffer.toString(), stdout);
      }
      offsets[uuid] = 0;
      total += tracks[uuid].length;
      numbers[uuid] = offsets.length;
    }
    if (verbose) {
      vprint(
        '∑ positions',
        '$total',
        max: columns,
        buffer: stdout,
      );
    } else {
      vprint(
        'Devices',
        '${offsets.length}',
        max: columns,
        unit: '$total positions',
        buffer: stdout,
      );
    }

    final completer = Completer<int>();

    // Calculate period between writes to each device
    final period = Duration(
      milliseconds: (batch / pps / tracks.length * 1000).toInt(),
    );
    sprint(columns, buffer: stdout);
    writeln(
      '  Simulating $batch positions '
      'for ${tracks.length} devices every ${period.inMilliseconds}ms '
      '($pps pps/device | ${pps * tracks.length} pps/total)',
      stdout,
    );

    // Ensure token is updated
    await AuthUtils.getToken(
      this,
      force: true,
    );

    // Prepare
    var processed = 0;
    final round = <String>[];
    final completed = <String>{};
    final results = <String, HttpResult>{};

    // Write to each device with fixed period
    Timer.periodic(period, (Timer timer) async {
      // Initialize new round?
      if (round.isEmpty) {
        round
          ..addAll(tracks.keys)
          ..removeWhere(
            (uuid) => completed.contains(uuid),
          );
      }
      // Get next device to simulate
      final uuid = round.first;
      round.remove(uuid);
      final track = tracks[uuid];
      final buffer = StringBuffer();
      final offset = offsets[uuid];
      final take = offset + batch >= track.length ? track.length - offset : batch;

      // Simulate events
      results[uuid] = await _simulate(
        uuid,
        offsets[uuid],
        take,
        track,
        buffer: buffer,
        write: verbose,
      );

      // Process result
      if (results[uuid].isSuccess) {
        offsets[uuid] += take;
        processed += take;
      }
      if (offset + take >= track.length) {
        completed.add(uuid);
      }

      // Update progress
      _progress(
        uuid,
        numbers[uuid],
        offsets[uuid],
        tracks[uuid],
        results[uuid],
        take,
        processed,
        total,
        verbose,
        completed.contains(uuid),
      );

      // Stop timer when target is meet
      if (processed >= total || completed.length == offsets.length) {
        timer.cancel();
        completer.complete(processed);
      }
    });

    // Wait for cancel
    final simulated = await completer.future;

    if (verbose || argResults['summary'] as bool) {
      stdout.writeln();
      sprint(columns, buffer: stdout);
      writeln('  Last position simulated was', stdout);
      stdout.writeln();
      for (var track in tracks.entries) {
        vprint(
          'Device',
          '${track.key}',
          max: columns,
          unit: 'uuid',
          buffer: stdout,
        );
        jPrint(
          track.value.last,
          left: 2,
          buffer: stdout,
        );
        stdout.writeln();
      }
    }
    stdout.writeln();
    sprint(columns, buffer: stdout);
    writeln('  Simulated $simulated positions on ${offsets.length} devices', stdout);
    stdout.writeln();

    return buffer.toString();
  }

  void _progress(
    String uuid,
    int number,
    int offset,
    List<Map<String, dynamic>> track,
    HttpResult result,
    int simulated,
    int processed,
    int total,
    bool verbose,
    bool completed,
  ) {
    const columns = 90;
    final short = uuid.substring(uuid.length - 8);
    if (verbose) {
      writeln('$result\n', stdout);
    } else {
      sprint(columns, buffer: stdout);
      vprint(
        'Simulated',
        '$simulated positions on ...$short${completed ? ' completed [✓]' : ''}',
        max: columns,
        unit: 'device $number | $processed p. | ${(processed / total * 100).toInt()}%',
        buffer: stdout,
        newline: true,
      );
      if (result.isFailure) {
        vprint(
          '- Failed',
          'Device $uuid',
          unit: '${red(result.toStatusText)}',
          max: columns - 1,
          left: 15,
          indent: 3,
          buffer: stdout,
          newline: true,
        );
        final json = result.content is Map ? Map.from(result.content) : null;
        final message = json?.elementAt('error') ?? result.content.toString();
        vprint(
          '  Message',
          '${message.replaceAll(uuid, '...$short')}',
          max: columns - 1,
          left: 15,
          indent: 3,
          buffer: stdout,
          newline: true,
        );
        vprint(
          '  Headers',
          '${result.headers.value('x-correlation-id')}',
          unit: 'x-correlation-id',
          max: columns - 1,
          left: 15,
          indent: 3,
          buffer: stdout,
          newline: true,
        );
        vprint(
          '  Headers',
          '${result.headers.value('x-pod-name')}',
          unit: 'x-pod-name',
          max: columns - 1,
          left: 15,
          indent: 3,
          buffer: stdout,
          newline: true,
        );
      }
    }
  }

  Future<HttpResult> _simulate(
    String uuid,
    int offset,
    int batch,
    List<Map<String, dynamic>> track, {
    @override StringBuffer buffer,
    bool write,
  }) async {
    if (write) {
      vprint(
        'Device',
        '$uuid',
        max: 90,
        unit: '${((offset + batch) / track.length * 100).toInt()}%',
        buffer: buffer,
      );
    }
    final positions = track.sublist(
      offset,
      offset + batch,
    );

    if (write) {
      var i = offset;
      for (var position in positions) {
        vprint(
          'Position ${i++}',
          '$position',
          buffer: buffer,
        );
      }
    }

    final result = await postBatch(
      uuid,
      positions,
      write: write,
      buffer: buffer,
    );

    return result;
  }

  Future<HttpResult> postBatch(
    String uuid,
    List<Map<String, dynamic>> json, {
    StringSink buffer,
    bool write = true,
  }) async {
    final token = await AuthUtils.getToken(
      this,
      renew: false,
    );
    final result = await post(
      client,
      '/api/devices/$uuid/positions',
      json,
      (result) => result,
      token: token,
      newline: false,
      format: (result) => result,
    );
    if (write) {
      buffer.write(result.buffer);
    }
    return result;
  }
}
