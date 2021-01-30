import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sarsys_ops_cli/src/run.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) async {
  try {
    await run(args);
    exit(0);
  } catch (e, stackTrace) {
    stderr.writeln(e);
    if (e is! UsageException) {
      stderr.writeln(Trace.format(stackTrace));
    }
    exit(2);
  }
}
