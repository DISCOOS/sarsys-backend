import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

import 'foo.dart';

class Bar extends AggregateRoot<BarCreated, BarDeleted> {
  Bar(
    String uuid,
    Map<String, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}

class BarRepository extends Repository<BarCommand, Bar> {
  BarRepository(EventStore store, this.instance, this.foos)
      : super(store: store, processors: {
          BarCreated: (event) => BarCreated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
                local: event.local,
              ),
          BarUpdated: (event) => BarUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          BarDeleted: (event) => BarDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  final int instance;
  final FooRepository foos;

  @override
  Bar create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Bar(
        uuid,
        processors,
        data: data,
      );

  @override
  void willStartProcessingEvents() {
    rule<BarCreated>(newUpdateFooRule);
    super.willStartProcessingEvents();
  }

  /// Will update [Foo] that
  /// matches path 'foo/uuid'
  /// in [Bar.data]
  AggregateRule newUpdateFooRule(_) => AssociationRule(
        (source, target) => UpdateFoo(
          {'uuid': target, 'updated': 'value'},
        ),
        target: foos,
        targetField: 'uuid',
        sourceField: 'foo/uuid',
        intent: Action.update,
      );

  @override
  String toString() {
    return '$runtimeType{instance: $instance, aggregates: ${count()}}';
  }
}

abstract class BarCommand<T extends DomainEvent> extends Command<T> {
  BarCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

class CreateBar extends BarCommand<BarCreated> {
  CreateBar(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateBar extends BarCommand<BarUpdated> {
  UpdateBar(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteBar extends BarCommand<BarDeleted> {
  DeleteBar(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}

class BarCreated extends DomainEvent {
  BarCreated({
    @required bool local,
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$BarCreated',
          created: created,
          data: data,
        );

  int get index => changed.elementAt('index');
}

class BarUpdated extends DomainEvent {
  BarUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$BarUpdated',
          created: created,
          data: data,
        );
}

class BarDeleted extends DomainEvent {
  BarDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$BarDeleted',
          created: created,
          data: data,
        );
}
