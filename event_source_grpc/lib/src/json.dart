import 'dart:typed_data';

export 'package:strings/strings.dart';
import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:event_source_grpc/src/generated/json.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class JsonValueWrapper implements JsonValue {
  JsonValueWrapper._(this._value);

  static final BuilderInfo _i = BuilderInfo(
      const bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'JsonValue',
      package: const PackageName(bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.io'),
      createEmptyInstance: () => JsonValueWrapper(),
      fromProto3Json: _fromProto3Json)
    ..e<JsonDataCompression>(
        1, const bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'compression', PbFieldType.OE,
        defaultOrMaker: JsonDataCompression.JSON_DATA_COMPRESSION_NONE,
        valueOf: JsonDataCompression.valueOf,
        enumValues: JsonDataCompression.values)
    ..a<List<int>>(2, const bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', PbFieldType.OY)
    ..hasRequiredFields = false;

  final JsonValue _value;

  @override
  BuilderInfo get info_ => _i;

  factory JsonValueWrapper() => JsonValueWrapper._(JsonValue.create());

  @override
  JsonValueWrapper createEmptyInstance() => JsonValueWrapper._(
        _value.createEmptyInstance(),
      );

  // JsonValue fields

  @override
  JsonDataCompression get compression => _value.compression;

  @override
  set compression(JsonDataCompression v) => _value.compression = v;

  @override
  List<int> get data => _value.data;

  @override
  set data(List<int> v) => _value.data = v;

  // Proto3 json conversions

  @override
  Object toProto3Json({TypeRegistry typeRegistry = const TypeRegistry.empty()}) => {
        'compression': _value.compression.name,
        'data': fromJsonValue(_value),
      };

  static void _fromProto3Json(GeneratedMessage message, Object json, TypeRegistry typeRegistry, Object context) {
    if (message is! JsonValueWrapper) {
      throw TypeError();
    }
    final value = message as JsonValueWrapper;
    if (json is! Map) {
      throw TypeError();
    }
    final map = Map<String, dynamic>.from(json);
    if (map.containsKey('compression')) {
      value.compression = JsonDataCompression.values.firstWhere(
        (e) => e.name == map['compression'],
      );
    }
    if (map.containsKey('data')) {
      value.data = toJsonValueBytes(
        map['data'],
        value.compression,
      );
    }
  }

  @override
  void mergeFromProto3Json(Object json,
      {TypeRegistry typeRegistry = const TypeRegistry.empty(),
      bool ignoreUnknownFields = false,
      bool supportNamesWithUnderscores = true,
      bool permissiveEnums = false}) {
    _fromProto3Json(this, json, typeRegistry, null);
  }

  // GeneratedMessage wrapper

  @override
  T $_ensure<T>(int index) => _value.$_ensure(index);

  @override
  T $_get<T>(int index, T defaultValue) => _value.$_get(index, defaultValue);

  @override
  bool $_getB(int index, bool defaultValue) => _value.$_getB(index, defaultValue);

  @override
  bool $_getBF(int index) => _value.$_getBF(index);

  @override
  int $_getI(int index, int defaultValue) => _value.$_getI(index, defaultValue);

  @override
  Int64 $_getI64(int index) => _value.$_getI64(index);

  @override
  int $_getIZ(int index) => _value.$_getIZ(index);

  @override
  List<T> $_getList<T>(int index) => _value.$_getList(index);

  @override
  Map<K, V> $_getMap<K, V>(int index) => _value.$_getMap(index);

  @override
  T $_getN<T>(int index) => _value.$_getN(index);

  @override
  String $_getS(int index, String defaultValue) => _value.$_getS(index, defaultValue);

  @override
  String $_getSZ(int index) => _value.$_getSZ(index);

  @override
  bool $_has(int index) => _value.$_has(index);

  @override
  void $_setBool(int index, bool value) => _value.$_setBool(index, value);

  @override
  void $_setBytes(int index, List<int> value) => _value.$_setBytes(index, value);

  @override
  void $_setDouble(int index, double value) => _value.$_setDouble(index, value);

  @override
  void $_setFloat(int index, double value) => _value.$_setFloat(index, value);

  @override
  void $_setInt64(int index, Int64 value) => _value.$_setInt64(index, value);

  @override
  void $_setSignedInt32(int index, int value) => _value.$_setSignedInt32(index, value);

  @override
  void $_setString(int index, String value) => _value.$_setString(index, value);

  @override
  void $_setUnsignedInt32(int index, int value) => _value.$_setUnsignedInt32(index, value);

  @override
  int $_whichOneof(int oneofIndex) => _value.$_whichOneof(oneofIndex);

  @override
  void addExtension(Extension extension, dynamic value) => _value.addExtension(extension, value);

  @override
  void check() => _value.check();

  @override
  void clear() => _value.clear();

  @override
  void clearCompression() => _value.clearCompression();

  @override
  void clearData() => _value.clearData();

  @override
  void clearExtension(Extension extension) => _value.clearExtension(extension);

  @override
  void clearField(int tagNumber) => _value.clearField(tagNumber);

  @override
  @deprecated
  JsonValueWrapper clone() => _value.clone();

  @override
  @deprecated
  JsonValueWrapper copyWith(void Function(JsonValueWrapper p1) updates) => _value.copyWith(updates);

  @override
  Map<K, V> createMapField<K, V>(int tagNumber, MapFieldInfo<K, V> fi) => _value.createMapField<K, V>(tagNumber, fi);

  @override
  List<T> createRepeatedField<T>(int tagNumber, FieldInfo<T> fi) => _value.createRepeatedField<T>(tagNumber, fi);

  @override
  // TODO: implement eventPlugin
  EventPlugin get eventPlugin => _value.eventPlugin;

  @override
  bool extensionsAreInitialized() => _value.extensionsAreInitialized();

  @override
  GeneratedMessage freeze() => _value.freeze();
  @override
  dynamic getDefaultForField(int tagNumber) => _value.getDefaultForField(tagNumber);

  @override
  dynamic getExtension(Extension extension) => _value.getExtension(extension);

  @override
  dynamic getField(int tagNumber) => _value.getField(tagNumber);

  @override
  dynamic getFieldOrNull(int tagNumber) => _value.getFieldOrNull(tagNumber);

  @override
  int getTagNumber(String fieldName) => _value.getTagNumber(fieldName);

  @override
  bool hasCompression() => _value.hasCompression();

  @override
  bool hasData() => _value.hasData();

  @override
  bool hasExtension(Extension extension) => _value.hasExtension(extension);

  @override
  bool hasField(int tagNumber) => _value.hasField(tagNumber);

  @override
  bool hasRequiredFields() => _value.hasRequiredFields();

  @override
  // TODO: implement isFrozen
  bool get isFrozen => _value.isFrozen;

  @override
  bool isInitialized() => _value.isInitialized();

  @override
  void mergeFromBuffer(
    List<int> input, [
    ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY,
  ]) =>
      _value.mergeFromBuffer(input, extensionRegistry);

  @override
  void mergeFromCodedBufferReader(CodedBufferReader input,
          [ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY]) =>
      _value.mergeFromCodedBufferReader(input, extensionRegistry);

  @override
  void mergeFromJson(String data, [ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY]) =>
      _value.mergeFromJson(data, extensionRegistry);

  @override
  void mergeFromJsonMap(Map<String, dynamic> json, [ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY]) =>
      _value.mergeFromJsonMap(json, extensionRegistry);

  @override
  void mergeFromMessage(GeneratedMessage other) => _value.mergeFromMessage(other);

  @override
  void mergeUnknownFields(UnknownFieldSet unknownFieldSet) => _value.mergeUnknownFields(unknownFieldSet);

  @override
  void setExtension(Extension extension, dynamic value) => _value.setExtension(extension, value);

  @override
  void setField(int tagNumber, dynamic value) => _value.setField(tagNumber, value);

  @override
  GeneratedMessage toBuilder() => _value.toBuilder();

  @override
  String toDebugString() => _value.toDebugString();

  @override
  // TODO: implement unknownFields
  UnknownFieldSet get unknownFields => _value.unknownFields;

  @override
  Uint8List writeToBuffer() => _value.writeToBuffer();

  @override
  void writeToCodedBufferWriter(CodedBufferWriter output) => _value.writeToCodedBufferWriter(output);

  @override
  String writeToJson() => _value.writeToJson();

  @override
  Map<String, dynamic> writeToJsonMap() => _value.writeToJsonMap();
}
