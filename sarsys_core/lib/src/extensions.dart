import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

import 'sarsys_base_channel.dart';

extension RequestX on Request {
  Context toContext(Logger logger) {
    final context = SecureRouter.getContext(this);
    return Context(
      logger,
      id: context.correlationId ?? raw.headers.value('x-correlation-id'),
    );
  }
}
