import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'eventstore_mock_server.dart';

typedef _Creator<T extends AggregateRoot> = Repository<Command, T> Function(EventStore store);

class Harness {
  EventStoreMockServer _server;
  EventStoreMockServer get server => _server;

  EventStoreConnection _connection;
  EventStoreConnection get connection => _connection;

  String _tenant;
  String get tenant => _tenant;
  Harness withTenant({String tenant = 'discoos'}) {
    _tenant = tenant;
    return this;
  }

  String _prefix;
  String get prefix => _prefix;
  Harness withPrefix({String prefix = 'test'}) {
    _prefix = prefix;
    return this;
  }

  String _projection;
  String get projection => _projection;
  Harness withProjection() {
    _projection = 'by_category';
    return this;
  }

  final _bus = MessageBus();
  MessageBus get bus => _bus;

  Harness withRepository<T extends AggregateRoot>(
    Repository<Command, T> create(EventStore store), {
    bool useInstanceStreams = true,
  }) {
    _builders.putIfAbsent(
      typeOf<T>(),
      () => _RepositoryBuilder<T>(
        create,
        useInstanceStreams: useInstanceStreams,
      ),
    );
    return this;
  }

  final Map<Type, _RepositoryBuilder> _builders = {};
  Repository get<T extends Repository>() => _manager.get<T>();

  RepositoryManager _manager;

  void install({
    int port = 4000,
  }) {
    _server = EventStoreMockServer(
      _tenant,
      _prefix,
      port,
    );

    setUpAll(() async {
      await _server.open();
      _connection = EventStoreConnection(
        host: 'http://localhost',
        port: port,
      );
    });

    setUp(() async {
      if (_projection?.isNotEmpty == true) {
        _server.withProjection('by_category');
      }
      _manager = RepositoryManager(
        _bus,
        _connection,
        prefix: EventStore.toCanonical([
          _tenant,
          _prefix,
        ]),
      );
      _builders.values.forEach((builder) {
        builder(_manager);
        server.withStream(builder.stream);
      });
      await _manager.build();
    });

    tearDown(() {
      _server.clear();
      _manager.dispose();
    });

    tearDownAll(() async {
      await _server.close();
      _manager.dispose();
      _connection.close();
    });
  }
}

class _RepositoryBuilder<T extends AggregateRoot> {
  _RepositoryBuilder(
    _Creator<T> create, {
    @required this.useInstanceStreams,
  }) : _create = create;
  final _Creator<T> _create;
  final bool useInstanceStreams;
  String get stream => typeOf<T>().toColonCase();

  void call(RepositoryManager manager) {
    manager.register<T>(
      _create,
      stream: stream,
      useInstanceStreams: useInstanceStreams,
    );
  }
}
