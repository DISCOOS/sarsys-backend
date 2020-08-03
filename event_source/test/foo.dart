import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

class Foo extends AggregateRoot<FooCreated, FooDeleted> {
  Foo(
    String uuid,
    Map<String, ProcessCallback> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}

class FooRepository extends Repository<FooCommand, Foo> {
  FooRepository(EventStore store)
      : super(store: store, processors: {
          FooCreated: (event) => FooCreated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
                local: event.local,
              ),
          FooUpdated: (event) => FooUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          FooDeleted: (event) => FooDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  @override
  Foo create(Map<String, ProcessCallback> processors, String uuid, Map<String, dynamic> data) => Foo(
        uuid,
        processors,
        data: data,
      );
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
  FooCreated({
    @required bool local,
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$FooCreated',
          created: created,
          data: data,
        );

  int get index => changed.elementAt('index');
}

class FooUpdated extends DomainEvent {
  FooUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$FooUpdated',
          created: created,
          data: data,
        );
}

class FooDeleted extends DomainEvent {
  FooDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: '$FooDeleted',
          created: created,
          data: data,
        );
}
