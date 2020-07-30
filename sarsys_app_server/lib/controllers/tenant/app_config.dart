import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

class AppConfigRepository extends Repository<AppConfigCommand, AppConfig> {
  AppConfigRepository(
    EventStore store, {
    @required this.devices,
  }) : super(store: store, processors: {
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
    rule<AppConfigCreated>(newCreateRule);

    // Co-delete Device with AppConfig
    rule<AppConfigDeleted>(newDeleteRule);

    super.willStartProcessingEvents();
  }

  @override
  AppConfig create(
    Map<String, Process> processors,
    String uuid,
    Map<String, dynamic> data,
  ) =>
      AppConfig(
        uuid,
        processors,
        data: data,
      );

  AggregateRule newCreateRule(_) => AssociationRule(
        (source, udid) => CreateDevice(
          {
            "type": "app",
            "network": "sarsys",
            "status": "available",
            uuidFieldName: udid,
          },
        ),
        source: this,
        target: devices,
        sourceField: 'udid',
        intent: Action.create,
        targetField: uuidFieldName,
        //
        // Relation: 'app-configs-to-device'
        //
        // - will create device when
        //   first app-config referencing
        //   it is created
        //
        cardinality: Cardinality.m2o,
      );

  AggregateRule newDeleteRule(_) => AssociationRule(
        (source, target) => DeleteDevice(
          {uuidFieldName: target},
        ),
        source: this,
        target: devices,
        sourceField: 'udid',
        targetField: uuidFieldName,
        intent: Action.delete,
        //
        // Relation: 'app-configs-to-device'
        //
        // - will delete device when
        //   last app-config referencing
        //   it is deleted
        //
        cardinality: Cardinality.m2o,
      );
}

class AppConfig extends AggregateRoot<AppConfigCreated, AppConfigDeleted> {
  AppConfig(
    String uuid,
    Map<String, Process> processors, {
    Map<String, dynamic> data = const {},
  }) : super(uuid, processors, data);

  String get udid => data?.elementAt('udid');
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
