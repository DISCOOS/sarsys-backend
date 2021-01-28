import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

extension RequestX on Request {
  Context toContext(Logger logger) {
    return Context(logger, id: raw.headers.value('x-correlation-id'));
  }
}
