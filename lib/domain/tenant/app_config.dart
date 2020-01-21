import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

class AppConfigRepository extends Repository<AppConfigCommand, AppConfig> {
  AppConfigRepository(EventStore store)
      : super(store: store, processors: {
          AppConfigCreated: (event) => AppConfigCreated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          AppConfigUpdated: (event) => AppConfigUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
        });

  @override
  AppConfig create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => AppConfig(
        uuid,
        processors,
        data: data,
      );
}

class AppConfig extends AggregateRoot<AppConfigCreated, AppConfigDeleted> {
  AppConfig(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);
}

//////////////////////////////////////
// AppConfig Commands
//////////////////////////////////////

abstract class AppConfigCommand<T extends DomainEvent> extends Command<T> {
  AppConfigCommand(
    Action action, {
    Map<String, dynamic> data = const {},
  }) : super(action, data: data);
}

class CreateAppConfig extends AppConfigCommand<AppConfigCreated> {
  CreateAppConfig(
    Map<String, dynamic> data,
  ) : super(Action.create, data: data);
}

class UpdateAppConfig extends AppConfigCommand<AppConfigUpdated> {
  UpdateAppConfig(
    Map<String, dynamic> data,
  ) : super(Action.update, data: data);
}

class DeleteAppConfig extends AppConfigCommand<AppConfigDeleted> {
  DeleteAppConfig(
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

class AppConfigDeleted extends DomainEvent {
  AppConfigDeleted({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$AppConfigDeleted",
          created: created,
          data: data,
        );
}
