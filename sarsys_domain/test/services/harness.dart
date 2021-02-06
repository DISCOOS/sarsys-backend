Map<String, dynamic> createTracking(String uuid) => {
      'uuid': '$uuid',
    };

Map<String, dynamic> createSource({String uuid = 'string', String type = 'device'}) => {
      'uuid': '$uuid',
      'type': '$type',
    };

Map<String, dynamic> createTrack({String id, String uuid = 'string', String type = 'device'}) => {
      if (id != null) 'id': '$id',
      'source': createSource(
        uuid: uuid,
        type: type,
      ),
    };

Map<String, Object> createPosition({
  double lon = 1.0,
  double lat = 1.0,
  double acc = 1.0,
}) =>
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [lon, lat]
      },
      'properties': {
        'name': 'string',
        'description': 'string',
        'accuracy': acc,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'manual'
      }
    };

Map<String, dynamic> createDevice(
  String uuid, {
  Map<String, dynamic> position,
  bool trackable = true,
}) =>
    {
      'uuid': '$uuid',
      'name': 'string',
      'alias': 'string',
      'network': 'string',
      'networkId': 'string',
      'trackable': trackable,
      if (position != null) 'position': position,
    };
