import 'package:sarsys_ops_server/sarsys_ops_server.dart';

Map<String, dynamic> toPodMetrics(String type, Map<String, dynamic> pod) {
  final metrics = Map<String, dynamic>.from(pod['metrics'])
    ..removeWhere((key, _) => const [
          'kind',
          'metadata',
          'apiVersion',
          'containers',
        ].contains(key));

  return metrics
    ..putIfAbsent(
      'usage',
      () => _toPodUsage(type, pod),
    )
    ..putIfAbsent(
      'limits',
      () => _toPodLimits(type, pod),
    )
    ..putIfAbsent(
      'requests',
      () => _toPodRequests(type, pod),
    );
}

Map<String, dynamic> _toPodUsage(
  String type,
  Map<String, dynamic> pod,
) {
  return pod
          .listAt<Map>(
            'metrics/containers',
            defaultList: [],
          )
          .where((c) => c['name'] == type)
          .map((c) => Map<String, dynamic>.from(c['usage']))
          .firstOrNull ??
      <String, dynamic>{};
}

Map<String, dynamic> _toPodLimits(
  String type,
  Map<String, dynamic> pod,
) {
  return pod
          .listAt<Map>(
            'spec/containers',
            defaultList: [],
          )
          .where((c) => c['name'] == type)
          .map((c) => c.mapAt<String, dynamic>('resources/limits'))
          .firstOrNull ??
      <String, dynamic>{};
}

Map<String, dynamic> _toPodRequests(
  String type,
  Map<String, dynamic> pod,
) {
  return pod
          .listAt<Map>(
            'spec/containers',
            defaultList: [],
          )
          .where((c) => c['name'] == type)
          .map((c) => c.mapAt<String, dynamic>('resources/requests'))
          .firstOrNull ??
      <String, dynamic>{};
}
