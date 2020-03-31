import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

class AppConfigRepository extends Repository<AppConfigCommand, AppConfig> {
  AppConfigRepository(EventStore store, this.devices)
      : super(store: store, processors: {
          AppConfigCreated: (event) => AppConfigCreated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          AppConfigUpdated: (event) => AppConfigUpdated(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
          AppConfigDeleted: (event) => AppConfigDeleted(
                uuid: event.uuid,
                data: event.data,
                local: event.local,
                created: event.created,
              ),
        });

  final DeviceRepository devices;

  @override
  void willStartProcessingEvents() {
    // Co-create Device with AppConfig
    rule<AppConfigCreated>((_) => AssociationRule(
          (source, target) => CreateDevice(
            {
              "type": "app",
              "network": "sarsys",
              "status": "unavailable",
              uuidFieldName: target,
            },
          ),
          target: devices,
          intent: Action.create,
          targetField: uuidFieldName,
          cardinality: Cardinality.none,
        ));

    // Co-delete Device with AppConfig
    rule<AppConfigDeleted>((_) => AssociationRule(
          (source, target) => DeleteDevice(
            {
              uuidFieldName: target,
            },
          ),
          target: devices,
          intent: Action.delete,
          targetField: uuidFieldName,
          cardinality: Cardinality.none,
        ));

    super.willStartProcessingEvents();
  }

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
  ) : super(Action.delete, data: data);
}

//////////////////////////////////////
// AppConfig Domain Events
//////////////////////////////////////

class AppConfigCreated extends DomainEvent {
  AppConfigCreated({
    @required String uuid,
    @required DateTime created,
    @required Map<String, dynamic> data,
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
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
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
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
    @required bool local,
  }) : super(
          uuid: uuid,
          local: local,
          type: "$AppConfigDeleted",
          created: created,
          data: data,
        );
}
