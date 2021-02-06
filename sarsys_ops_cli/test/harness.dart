import 'package:event_source/event_source.dart';
import 'package:sarsys_ops_cli/src/core.dart';
import 'package:sarsys_ops_server_test/sarsys_ops_server_test.dart';

class SarSysCliHarness extends SarSysOpsHarness {
  Map<String, dynamic> writeOpsConfig({
    String scheme = 'http',
    String host = 'localhost',
    int port,
  }) {
    final file = defaultConfigFile;
    final config = ensureConfig(file);
    final ops = config.mapAt('ops');
    final baseURL = Uri.parse(agent.baseURL);
    ops['host'] = host ?? baseURL.host;
    ops['port'] = port ?? baseURL.port;
    ops['scheme'] = scheme ?? baseURL.scheme;
    config['ops'] = ops;
    writeConfig(file, config);
    return Map.from(ops);
  }
}
