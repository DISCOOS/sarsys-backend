import 'package:meta/meta.dart';
import 'package:collection_x/collection_x.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

class AppConfigRepository extends Repository<AppConfigCommand, AppConfig> {
  AppConfigRepository(
    EventStore store, {
    @required this.devices,
  }) : super(store: store, processors: {
          AppConfigCreated: (event) => AppConfigCreated(event),
          AppConfigUpdated: (event) => AppConfigUpdated(event),
          AppConfigDeleted: (event) => AppConfigDeleted(event),
        });

  final DeviceRepository devices;

  @override
  void willStartProcessingEvents() {
    // Co-create Device with AppConfig
    rule<AppConfigCreated>(newCreateRule);
    rule<AppConfigUpdated>(newCreateRule);

    // Co-delete Device with AppConfig
    rule<AppConfigDeleted>(newDeleteRule);

    super.willStartProcessingEvents();
  }

  @override
  AppConfig create(
    Map<String, ProcessCallback> processors,
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
        (source, udid) => DeleteDevice(
          {uuidFieldName: udid},
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
    Map<String, ProcessCallback> processors, {
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
  AppConfigCreated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: "$AppConfigCreated",
        );
}

class AppConfigUpdated extends DomainEvent {
  AppConfigUpdated(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: "$AppConfigUpdated",
        );
}

class AppConfigDeleted extends DomainEvent {
  AppConfigDeleted(Message message)
      : super(
          uuid: message.uuid,
          local: message.local,
          data: message.data,
          created: message.created,
          type: "$AppConfigDeleted",
        );
}
