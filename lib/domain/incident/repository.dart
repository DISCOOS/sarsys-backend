import 'package:sarsys_app_server/domain/operation/operation.dart';
import 'package:sarsys_app_server/eventsource/eventsource.dart';

import 'aggregate.dart';
import 'commands.dart';
import 'events.dart';

class IncidentRepository extends Repository<IncidentCommand, Incident> implements MessageHandler<DomainEvent> {
  IncidentRepository(EventStore store)
      : super(store: store, processors: {
          IncidentRegistered: (event) => IncidentRegistered(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          IncidentInformationUpdated: (event) => IncidentInformationUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OperationAddedToIncident: (event) => OperationAddedToIncident(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          OperationRemovedFromIncident: (event) => OperationRemovedFromIncident(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          IncidentRespondedTo: (event) => IncidentRespondedTo(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          IncidentResolved: (event) => IncidentResolved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          IncidentDeleted: (event) => IncidentDeleted(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          ClueAdded: (event) => ClueAdded(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          ClueUpdated: (event) => ClueUpdated(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              ),
          ClueRemoved: (event) => ClueRemoved(
                uuid: event.uuid,
                data: event.data,
                created: event.created,
              )
        });

  @override
  Incident create(Map<String, Process> processors, String uuid, Map<String, dynamic> data) => Incident(
        uuid,
        processors,
        data: data,
      );

  @override
  void willStartProcessingEvents() {
    super.willStartProcessingEvents();
    store.bus.register<OperationDeleted>(this);
  }

  @override
  void handle(DomainEvent message) async {
    try {
      switch (message.runtimeType) {
        case OperationDeleted:
          final uuid = toIncidentUuid(message, 'operations');
          if (contains(uuid)) {
            await execute(
              RemoveOperationFromIncident(get(uuid), message.data[uuidFieldName] as String),
            );
          }
          break;
      }
    } on Exception catch (e) {
      logger.severe("Failed to process $message, failed with: $e");
    }
  }

  String toIncidentUuid(DomainEvent event, String field) {
    String uuid;
    final incident = event.data['incident'];
    if (incident is Map<String, dynamic>) {
      if (incident.containsKey('uuid')) {
        uuid = incident['uuid'] as String;
      }
    }
    if (uuid == null) {
      // TODO: Implement test that fails when number of open incidents are above threshold
      // Do a full search for foreign id. This will be efficient as long as number of incidents are reasonable low
      final foreign = event.data[uuidFieldName] as String;
      uuid = aggregates
          .where((incident) => incident.data[field] is List)
          .firstWhere(
            (test) => List<String>.unmodifiable(incident.data[field] as List).contains(foreign),
            orElse: () => null,
          )
          ?.uuid;
    }
    return uuid;
  }
}
