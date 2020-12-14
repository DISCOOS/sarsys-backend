import 'package:event_source/event_source.dart';

class Foo extends AggregateRoot<FooCreated, FooDeleted> {
  Foo(
    String uuid,
    Map<String, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}

class FooRepository extends Repository<FooCommand, Foo> {
  FooRepository(EventStore store, this.instance)
      : super(store: store, processors: {
          FooCreated: (event) => FooCreated(event),
          FooUpdated: (event) => FooUpdated(event),
          FooDeleted: (event) => FooDeleted(event),
        });

  final int instance;

  @override
  Foo create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Foo(
        uuid,
        processors,
        data: data,
      );

  @override
  String toString() {
    return '$runtimeType{instance: $instance, aggregates: ${count()}}';
  }
}

abstract class FooCommand<T extends DomainEvent> extends Command<T> {
  FooCommand(
    Action action, {
    String uuid,
    Map<String, dynamic> data = const {},
  }) : super(action, uuid: uuid, data: data);
}

class CreateFoo extends FooCommand<FooCreated> {
  CreateFoo(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateFoo extends FooCommand<FooUpdated> {
  UpdateFoo(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteFoo extends FooCommand<FooDeleted> {
  DeleteFoo(
    Map<String, dynamic> data,
  ) : super(Action.delete, data: data);
}

class FooCreated extends DomainEvent {
  FooCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$FooCreated',
        );

  // int get index => changed.elementAt('index');
}

class FooUpdated extends DomainEvent {
  FooUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$FooUpdated',
        );
}

class FooDeleted extends DomainEvent {
  FooDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: '$FooDeleted',
        );
}
