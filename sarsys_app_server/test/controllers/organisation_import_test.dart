import 'package:event_source/event_source.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

import 'harness.dart';

Future main() async {
  final harness = SarSysHttpHarness()
    ..withEventStoreMock()
    ..install(restartForEachTest: true);

  test("PATCH /api/organisation/{uuid}/import creates divisions and departments", () async {
    await _testImport(harness);
  });

  test("Multiple PATCH /api/organisation/{uuid}/import", () async {
    await _testImport(harness);
    await _testImport(harness);
    await _testImport(harness);
  });

  test("PATCH /api/organisation/{uuid}/import updates division and department", () async {
    // Arrange
    final ouuid = await _prepare(harness);
    final divuuid = Uuid().v4();
    final depuuid = Uuid().v4();
    final dep = {
      'uuid': depuuid,
      'name': "Dep1",
      'suffix': "1",
      'active': true,
    };
    final div = {
      'uuid': divuuid,
      'name': "Div1",
      'suffix': "1",
      'active': true,
      'departments': [
        dep,
      ]
    };
    final tree = {
      'uuid': ouuid,
      'divisions': [div]
    };
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid/import", body: tree),
      200,
      body: null,
    );

    // Act
    div.addAll({'name': 'div2'});
    dep.addAll({'name': 'dep2'});
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid/import", body: tree),
      200,
      body: null,
    );

    // Assert
    final response1 = expectResponse(await harness.agent.get("/api/organisations/$ouuid"), 200);
    final actualOrg = await response1.body.decode() as Map<String, dynamic>;
    expect(
        actualOrg.elementAt('data'),
        containsPair('divisions', [
          divuuid,
        ]));
    final response2 = expectResponse(await harness.agent.get("/api/divisions/$divuuid"), 200);
    final actualDiv = await response2.body.decode() as Map<String, dynamic>;
    expect(
        actualDiv,
        containsPair(
          'data',
          div
            ..addAll({
              'departments': [
                depuuid,
              ],
              'organisation': {'uuid': ouuid}
            }),
        ));
    final response3 = expectResponse(await harness.agent.get("/api/departments/$depuuid"), 200);
    final actualDep = await response3.body.decode() as Map<String, dynamic>;
    expect(
        actualDep,
        containsPair(
          'data',
          dep
            ..addAll({
              'division': {'uuid': divuuid}
            }),
        ));
  });

  test("PATCH /api/organisation/{uuid}/import returns 409 on duplicate division names in import data", () async {
    // Arrange
    final ouuid = await _prepare(harness);
    final duuid1 = Uuid().v4();
    final duuid2 = Uuid().v4();
    final div1 = {
      'uuid': duuid1,
      'name': "Div1",
      'suffix': "1",
      'active': true,
    };
    final div2 = {
      'uuid': duuid2,
      'name': "Div1",
      'suffix': "1",
      'active': true,
    };
    final tree = {
      'uuid': ouuid,
      'divisions': [div1, div2]
    };
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid/import", body: tree),
      409,
      body: null,
    );
  });

  test("PATCH /api/organisation/{uuid}/import returns 409 on duplicate department names in import data", () async {
    // Arrange
    final ouuid = await _prepare(harness);
    final duuid1 = Uuid().v4();
    final duuid2 = Uuid().v4();
    final dep1 = {
      'uuid': duuid1,
      'name': "Dep1",
      'suffix': "1",
      'active': true,
    };
    final dep2 = {
      'uuid': duuid2,
      'name': "Dep1",
      'suffix': "1",
      'active': true,
    };
    final div = {
      'name': "Div1",
      'suffix': "1",
      'active': true,
      'departments': [
        dep1,
        dep2,
      ],
    };
    final tree = {
      'uuid': ouuid,
      'divisions': [div]
    };
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid/import", body: tree),
      409,
      body: null,
    );
  });

  test("PATCH /api/organisation/{uuid}/import returns 409 when division and department name exists", () async {
    // Arrange
    final ouuid = await _prepare(harness);
    final divuuid = Uuid().v4();
    final depuuid = Uuid().v4();
    final dep = {
      'uuid': depuuid,
      'name': "Dep1",
      'suffix': "1",
      'active': true,
    };
    final div = {
      'uuid': divuuid,
      'name': "Div1",
      'suffix': "1",
      'active': true,
      'departments': [
        dep,
      ]
    };
    final tree = {
      'uuid': ouuid,
      'divisions': [div]
    };
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid/import", body: tree),
      200,
      body: null,
    );

    // Act again with same names
    div.remove('uuid');
    dep.remove('uuid');

    // Assert
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid/import", body: tree),
      409,
      body: null,
    );
  });

  test("PATCH /api/organisation/{uuid}/import returns 409 when division belongs to other organisation", () async {
    // Arrange
    final ouuid1 = await _prepare(harness);
    final divuuid = Uuid().v4();
    final depuuid = Uuid().v4();
    final dep = {
      'uuid': depuuid,
      'name': "Dep1",
      'suffix': "1",
      'active': true,
    };
    final div = {
      'uuid': divuuid,
      'name': "Div1",
      'suffix': "1",
      'active': true,
      'departments': [
        dep,
      ]
    };
    final tree = {
      'uuid': ouuid1,
      'divisions': [div]
    };
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid1/import", body: tree),
      200,
      body: null,
    );
    final ouuid2 = Uuid().v4();
    final organisation = createOrganisation(ouuid2);
    expectResponse(await harness.agent.post("/api/organisations", body: organisation), 201, body: null);

    // Act
    final response = expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid2/import", body: tree),
      409,
    );

    // Assert
    final conflict = await response.body.decode();
    expect(conflict, {
      'error': 'Aggregates belongs to wrong parents: [Division $divuuid belongs to organisation: $ouuid1]',
      'type': 'merge',
      'code': 'merge',
      'base': {},
      'mine': [],
      'yours': [],
    });
  });

  test("PATCH /api/organisation/{uuid}/import returns 409 when department belongs to other division", () async {
    // Arrange org 1
    final ouuid1 = await _prepare(harness);
    final divuuid1 = Uuid().v4();
    final depuuid1 = Uuid().v4();
    final dep1 = {
      'uuid': depuuid1,
      'name': "Dep1",
      'suffix': "1",
      'active': true,
    };
    final div1 = {
      'uuid': divuuid1,
      'name': "Div1",
      'suffix': "1",
      'active': true,
      'departments': [
        dep1,
      ]
    };
    final tree1 = {
      'uuid': ouuid1,
      'divisions': [div1]
    };
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid1/import", body: tree1),
      200,
      body: null,
    );

    // Arrange org 2
    final ouuid2 = Uuid().v4();
    final organisation = createOrganisation(ouuid2);
    expectResponse(await harness.agent.post("/api/organisations", body: organisation), 201, body: null);
    final divuuid2 = Uuid().v4();
    final div2 = {
      'uuid': divuuid2,
      'name': "Div2",
      'suffix': "3",
      'active': true,
    };
    final tree2 = {
      'uuid': ouuid2,
      'divisions': [div2]
    };
    expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid2/import", body: tree2),
      200,
      body: null,
    );

    // Act
    div2.addAll({
      'departments': [dep1]
    });
    final response = expectResponse(
      await harness.agent.execute('patch', "/api/organisations/$ouuid2/import", body: tree2),
      409,
    );

    // Assert
    final conflict = await response.body.decode();
    expect(conflict, {
      'error': 'Aggregates belongs to wrong parents: [Department $depuuid1 belongs to division: $divuuid1]',
      'type': 'merge',
      'code': 'merge',
      'mine': [],
      'yours': [],
      'base': {},
    });
  });
}

Future _testImport(SarSysHttpHarness harness) async {
  final ouuid = await _prepare(harness);
  final divuuid1 = Uuid().v4();
  final divuuid2 = Uuid().v4();
  final depuuid1 = Uuid().v4();
  final depuuid2 = Uuid().v4();
  final depuuid3 = Uuid().v4();
  final depuuid4 = Uuid().v4();
  final dep1 = {
    'uuid': depuuid1,
    'name': "Dep1",
    'suffix': "1",
    'active': true,
  };
  final dep2 = {
    'uuid': depuuid2,
    'name': "Dep2",
    'suffix': "1",
    'active': true,
  };
  final dep3 = {
    'uuid': depuuid3,
    'name': "Dep3",
    'suffix': "1",
    'active': true,
  };
  final dep4 = {
    'uuid': depuuid4,
    'name': "Dep4",
    'suffix': "1",
    'active': true,
  };
  final div1 = {
    'uuid': divuuid1,
    'name': "Div1",
    'suffix': "1",
    'active': true,
    'departments': [
      dep1,
      dep2,
    ]
  };
  final div2 = {
    'uuid': divuuid2,
    'name': "Div2",
    'suffix': "1",
    'active': true,
    'departments': [
      dep3,
      dep4,
    ]
  };
  final tree = {
    'uuid': ouuid,
    'divisions': [div1, div2]
  };
  expectResponse(
    await harness.agent.execute('patch', "/api/organisations/$ouuid/import", body: tree),
    200,
    body: null,
  );
  final response1 = expectResponse(await harness.agent.get("/api/organisations/$ouuid"), 200);
  final actualOrg = await response1.body.decode() as Map<String, dynamic>;
  expect(
      actualOrg.elementAt('data'),
      containsPair('divisions', [
        divuuid1,
        divuuid2,
      ]));
  final response2 = expectResponse(await harness.agent.get("/api/divisions/$divuuid1"), 200);
  final actualDiv = await response2.body.decode() as Map<String, dynamic>;
  expect(
      actualDiv,
      containsPair(
        'data',
        div1
          ..addAll({
            'departments': [
              depuuid1,
              depuuid2,
            ],
            'organisation': {'uuid': ouuid}
          }),
      ));
  final response3 = expectResponse(await harness.agent.get("/api/departments/$depuuid1"), 200);
  final actualDep = await response3.body.decode() as Map<String, dynamic>;
  expect(
      actualDep,
      containsPair(
        'data',
        dep1
          ..addAll({
            'division': {'uuid': divuuid1}
          }),
      ));
}

Future<String> _prepare(SarSysHttpHarness harness) async {
  final orguuid = Uuid().v4();
  final organisation = createOrganisation(orguuid);
  expectResponse(await harness.agent.post("/api/organisations", body: organisation), 201, body: null);
  return orguuid;
}
