import 'package:meta/meta.dart';

abstract class Event {
  String type;
  Map<String, dynamic> data;
}

class WriteEvent extends Event {
  WriteEvent({
    @required this.type,
    @required this.data,
  });
  @override
  final String type;
  @override
  final Map<String, dynamic> data;
}
