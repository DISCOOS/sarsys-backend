import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

class Foo extends AggregateRoot<FooCreated, FooDeleted> {
  Foo(
    String uuid,
    Map<String, Process> processors, {
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
              ),
          FooUpdated: (event) => FooUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          FooDeleted: (event) => FooDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  Foo create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Foo(
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
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: '$FooCreated',
          created: created,
          data: data,
        );
}

class FooUpdated extends DomainEvent {
  FooUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
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
  }) : super(
          uuid: uuid,
          type: '$FooDeleted',
          created: created,
          data: data,
        );
}
