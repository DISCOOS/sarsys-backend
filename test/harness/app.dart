import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:aqueduct_test/aqueduct_test.dart';

import '../evenstore/mock_server.dart';

export 'package:sarsys_app_server/sarsys_app_server.dart';
export 'package:aqueduct_test/aqueduct_test.dart';
export 'package:test/test.dart';
export 'package:aqueduct/aqueduct.dart';

/// A testing harness for sarsys_app_server.
///
/// A harness for testing an aqueduct application. Example test file:
///
///         void main() {
///           Harness harness = Harness()..install();
///
///           test("GET /path returns 200", () async {
///             final response = await harness.agent.get("/path");
///             expectResponse(response, 200);
///           });
///         }
///
class Harness extends TestHarness<SarSysAppServerChannel> {
  EventStoreMockServer eventStoreMockServer;

  EventStoreMockServer withEventStoreMock() => eventStoreMockServer = EventStoreMockServer(
        'discoos',
        'test',
        4000,
      );

  @override
  Future beforeStart() async {
    if (eventStoreMockServer != null) {
      await eventStoreMockServer.open();
    }
  }

  @override
  Future onSetUp() async {
    if (eventStoreMockServer != null) {
      eventStoreMockServer.withProjection('by_category');
    }
  }

  @override
  Future onTearDown() async {
    if (eventStoreMockServer != null) {
      eventStoreMockServer.clear();
    }
  }

  @override
  Future stop() async {
    if (eventStoreMockServer != null) {
      await eventStoreMockServer.close();
    }
    return super.stop();
  }
}
