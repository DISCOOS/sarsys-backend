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
      ..addMultiOption(
        'file',
        abbr: 'f',
        help: 'Path to file with device track as json',
      );
  }

  @override
  final name = 'device';

  @override
  final description = 'is used to simulate device position';

  /*

   Future<String> executeOn(
    String type,
    String uuid,
    String instance,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthUtils.getToken(this);
    final status = await post(
      client,
      '/ops/api/services/aggregate/$type/$uuid${instance == null ? '$expand' : '/$instance$expand'}',
      args,
      (result) {
        final buffer = StringBuffer();
        toInstanceStatus(
          type,
          result['meta'],
          buffer: buffer,
          verbose: verbose,
        );
        return buffer.toString();
      },
      token: token,
      format: (result) => result,
    );
    return status;
  }


   */

  @override
  FutureOr<String> run() async {
    const max = 90;
    final tracks = <String, List<Map<String, dynamic>>>{};
    // Sanity checks
    final files = argResults['file'] as List<String>;
    if (files.isEmpty) {
      usageException(red(' File is missing'));
      return writeln(red(' File is missing'), stderr);
    }
    final offsets = <String, int>{};
    final verbose = globalResults['verbose'] as bool;
    final pps = int.parse(argResults['pps'] as String);
    final batch = int.parse(argResults['batch'] as String);
    final limit = int.parse(argResults['limit'] as String ?? '0');
    writeln(highlight('> Simulate ${files.length} devices with pps $pps'), stdout);
    var total = 0;
    for (var path in files) {
      final buffer = StringBuffer();
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
        vprint(
          'Device',
          '$uuid',
          max: max,
          buffer: buffer,
        );
        vprint(
          'Positions',
          '${track.length}',
          max: max,
          left: 14,
          indent: 4,
          buffer: buffer,
        );
      }
      offsets[uuid] = 0;
      total += tracks[uuid].length;
      writeln(buffer.toString(), stdout);
    }
    if (verbose) {
      vprint(
        '∑ positions',
        '$total',
        max: max,
        buffer: stdout,
      );
    } else {
      vprint(
        'Devices',
        '${offsets.length}',
        max: max,
        unit: '∑ $total positions',
        buffer: stdout,
      );
    }
    final completer = Completer<int>();
    final period = Duration(
      milliseconds: (batch / pps * 1000).toInt(),
    );
    sprint(max, buffer: stdout);
    writeln(
      '  Simulating ${batch * tracks.length} positions '
      'for ${tracks.length} devices every ${period.inMilliseconds}ms ($pps pps)',
      stdout,
    );

    // Ensure token is updated
    await AuthUtils.getToken(
      this,
      force: true,
    );

    Timer.periodic(period, (Timer timer) async {
      var simulated = 0;
      final results = <String, HttpResult>{};
      for (var entry in tracks.entries) {
        final uuid = entry.key;
        final track = entry.value;
        final buffer = StringBuffer();
        final offset = offsets[uuid];
        final take = offset + batch >= track.length ? track.length - offset : batch;
        results[uuid] = await _simulate(
          uuid,
          offsets[uuid],
          take,
          track,
          buffer: buffer,
          write: verbose,
        );
        if (results[uuid].isSuccess) {
          offsets[uuid] += take;
          simulated += take;
        }
        if (offset + take >= track.length) {
          timer.cancel();
          completer.complete(track.length);
        }
      }
      _progress(
        offsets,
        tracks,
        results,
        simulated,
        total,
        verbose,
      );
    });

    // Wait for cancel
    final processed = await completer.future;

    stdout.writeln();
    sprint(max, buffer: stdout);
    writeln('  Simulated $processed positions', stdout);
    return buffer.toString();
  }

  void _progress(
    Map<String, int> offsets,
    Map<String, List<Map<String, dynamic>>> tracks,
    Map<String, HttpResult> results,
    int simulated,
    int total,
    bool verbose,
  ) {
    if (verbose) {
      results.values.forEach(
        (r) {
          writeln('$r\n', stdout);
        },
      );
    } else {
      final failed = results.entries.where((e) => e.value.isFailure).map((e) => e.key);
      final processed = offsets.entries.fold(0, (prev, next) => prev + next.value);

      vprint(
        'Simulated',
        '$simulated',
        max: 90,
        unit: '$processed positions, ${(processed / total * 100).toInt()}%',
        buffer: stdout,
        newline: true,
      );
      for (var uuid in failed) {
        vprint(
          '- Failed',
          'Device ...${uuid.substring(uuid.length - 8)}',
          unit: '${red(results[uuid].toStatusText)}',
          max: 89,
          left: 15,
          indent: 3,
          buffer: stdout,
          newline: true,
        );
        vprint(
          '  Message',
          '${results[uuid].content?.replaceAll(uuid, '...${uuid.substring(uuid.length - 8)}')}',
          max: 89,
          left: 15,
          indent: 3,
          buffer: stdout,
          newline: true,
        );
        vprint(
          '  Headers',
          '${results[uuid].headers.value('x-correlation-id')}',
          unit: 'x-correlation-id',
          max: 89,
          left: 15,
          indent: 3,
          buffer: stdout,
          newline: true,
        );
        vprint(
          '  Headers',
          '${results[uuid].headers.value('x-pod-name')}',
          unit: 'x-pod-name',
          max: 89,
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
