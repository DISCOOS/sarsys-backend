import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';
import 'package:uuid/uuid.dart';

class AppConfigRepository extends Repository<AppConfigCommand, AppConfig> {
  AppConfigRepository(EventStore store) : super(store: store);

  @override
  DomainEvent toDomainEvent(Event event) {
    switch (event.type) {
      case "AppConfigCreated":
        return AppConfigCreated(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
      case 'AppConfigUpdated':
        return AppConfigUpdated(
          uuid: event.uuid,
          data: event.data,
          created: event.created,
        );
    }
    throw InvalidOperation("Event type ${event.type} not recognized");
  }

  @override
  AppConfig create(String uuid, Map<String, dynamic> data) => AppConfig(uuid, data: data);
}

class AppConfig extends AggregateRoot {
  AppConfig(
    String uuid, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, data);

  @override
  DomainEvent created(
    Map<String, dynamic> data, {
    String type,
    DateTime timestamp,
  }) =>
      AppConfigCreated(
        uuid: Uuid().v4(),
        data: data,
        created: timestamp,
      );

  @override
  DomainEvent updated(
    Map<String, dynamic> data, {
    String type,
    bool command,
    DateTime timestamp,
  }) =>
      AppConfigUpdated(
        uuid: Uuid().v4(),
        data: data,
        created: timestamp,
      );
}

//////////////////////////////////////
// AppConfig Commands
//////////////////////////////////////

abstract class AppConfigCommand extends Command {
  AppConfigCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
}

class CreateAppConfig extends AppConfigCommand {
  CreateAppConfig(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateAppConfig extends AppConfigCommand {
  UpdateAppConfig(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

//////////////////////////////////////
// AppConfig Domain Events
//////////////////////////////////////

class AppConfigCreated extends DomainEvent {
  AppConfigCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$AppConfigCreated",
          created: created,
          data: data,
        );
}

class AppConfigUpdated extends DomainEvent {
  AppConfigUpdated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$AppConfigUpdated",
          created: created,
          data: data,
        );
}
