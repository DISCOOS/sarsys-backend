import 'dart:io';

import 'package:sarsys_ops_cli/src/run.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) async {
  try {
    stdout.write(await run(args));
    exit(0);
  } catch (e, stackTrace) {
    stderr.writeln("Failed to execute 'sarsysctl ${args.join(' ')}'");
    stderr.writeln(e);
    stderr.writeln(Trace.format(stackTrace));
    exit(2);
  }
}
