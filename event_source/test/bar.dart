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
          BarCreated: (event) => BarCreated(event),
          BarUpdated: (event) => BarUpdated(event),
          BarDeleted: (event) => BarDeleted(event),
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
        source: this,
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
  BarCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$BarCreated',
        );

  // int get index => changed.elementAt('index');
}

class BarUpdated extends DomainEvent {
  BarUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$BarUpdated',
        );
}

class BarDeleted extends DomainEvent {
  BarDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$BarDeleted',
        );
}
