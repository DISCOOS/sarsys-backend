import 'package:grpc/grpc.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'generated/sarsys_tracking_service.pbgrpc.dart';

class SarSysTrackingGrpcService extends SarSysTrackingServiceBase {
  @override
  Future<MetaResponse> getMeta(ServiceCall call, MetaRequest request) async {
    return MetaResponse()..count = 0;
  }
}
