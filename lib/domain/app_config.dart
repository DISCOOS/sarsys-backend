import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';
import 'package:uuid/uuid.dart';

class AppConfigRepository extends Repository<AppConfig> {
  AppConfigRepository(EventStore store)
      : super(
          store: store,
        );

  @override
  DomainEvent toDomainEvent(Event event) {
    switch (event.type) {
      case "AppConfigCreated":
        return AppConfigCreated(
          uuid: event.uuid,
          data: event.data,
        );
      case 'AppConfigUpdated':
        return AppConfigUpdated(
          uuid: event.uuid,
          data: event.data,
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
  AppConfig patch(Map<String, dynamic> data) {
    this.data.addAll(data);
    changed(AppConfigUpdated(uuid: Uuid().v4(), data: data));
    return this;
  }

  @override
  DomainEvent created(Map<String, dynamic> data) => AppConfigCreated(
        uuid: Uuid().v4(),
        data: data,
      );
}

class AppConfigCreated extends DomainEvent {
  AppConfigCreated({
    @required String uuid,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$AppConfigCreated",
          data: data,
        );
}

class AppConfigUpdated extends DomainEvent {
  AppConfigUpdated({
    @required String uuid,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: "$AppConfigUpdated",
          data: data,
        );
}
