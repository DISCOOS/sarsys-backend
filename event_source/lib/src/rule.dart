import 'dart:async';

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'core.dart';
import 'error.dart';
import 'extension.dart';
import 'domain.dart';

/// Rule (invariant) builder function for given [repository]
///
/// Should always return an [AggregateRule]
typedef RuleBuilder = AggregateRule Function(Repository repository);

/// [Command] builder function for given [AggregateRoot] and [DomainEvent]
///
/// If function returns a [Command] it must be executed. Return null if
/// nothing should be execution.
typedef CommandBuilder = Command Function(DomainEvent source, String target);

/// [AggregateRoot] target resolver function
typedef TargetResolver = Repository Function();

/// Number range class
class Range {
  const Range({this.max, this.min});

  factory Range.lower(int min) => Range(min: min);
  factory Range.upper(int max) => Range(max: max);

  static const many = Range();
  static const one = Range(min: 1, max: 1);
  static const none = Range(min: 0, max: 0);

  final int max;
  final int min;

  bool get isOne => min == 1 && max == 1;
  bool get isNone => min == 0 && max == 0;
  bool get isMany => min == null && max == null;

  bool get isBound => !isMany;
  bool get isLowerBound => min != null;
  bool get isUpperBound => max != null;

  String toUML() {
    if (isNone) {
      return '0..0';
    } else if (isMany) {
      return '1..*';
    } else if (isOne) {
      return '1';
    } else if (isLowerBound && !isUpperBound) {
      return '$min';
    } else if (isUpperBound && !isLowerBound) {
      return '0..$max';
    } else if (isUpperBound && isLowerBound) {
      return '$min..$max';
    }
    // isMany
    return '0..*';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range && runtimeType == other.runtimeType && max == other.max && min == other.min;

  @override
  int get hashCode => max.hashCode ^ min.hashCode;

  @override
  String toString() {
    return 'Range{max: $max, min: $min}';
  }
}

/// Cardinality class
/// see https://en.wikipedia.org/wiki/Cardinality_(data_modeling)
class Cardinality {
  const Cardinality({this.left = Range.many, this.right = Range.many});
  final Range left;
  final Range right;

  /// Many-to-many cardinality
  static const m2m = Cardinality();

  /// Any type of cardinality
  static const any = Cardinality(left: null, right: null);

  /// No cardinality allowed
  static const none = Cardinality(left: Range.none, right: Range.none);

  /// One-to-one cardinality
  static const o2o = Cardinality(left: Range.one, right: Range.one);

  /// one-to-many cardinality
  static const o2m = Cardinality(left: Range.one, right: Range.many);

  /// Many-to-one cardinality
  static const m2o = Cardinality(left: Range.many, right: Range.one);

  bool get isAny => this == any;
  bool get isO2O => this == o2o;
  bool get isO2M => this == o2m;
  bool get isM2O => this == m2o;
  bool get isM2M => this == m2m;
  bool get isNone => this == none;

  String toUML() => '${left.toUML()} <-> ${right.toUML()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cardinality && runtimeType == other.runtimeType && left == other.left && right == other.right;

  @override
  int get hashCode => left.hashCode ^ right.hashCode;

  @override
  String toString() => 'Cardinality{left: $left, right: $right}';
}

/// General [AggregateRule] failure
class RuleException extends Failure {
  RuleException(String message) : super(message);
}

/// [Cardinality] violation exception
class CardinalityException extends RuleException {
  CardinalityException(String message) : super(message);
}

/// Abstract class for [AggregateRoot] rule-based execution
abstract class AggregateRule {
  AggregateRule(
    this.builder,
    this.target,
    this.targetField, {
    this.local = true,
  });

  final bool local;
  final Repository target;
  final String targetField;
  final CommandBuilder builder;

  Future<Iterable<String>> evaluate(DomainEvent event);

  Future<Iterable<DomainEvent>> call(DomainEvent event) async {
    if (event.local == local) {
      final roots = await evaluate(event);
      final result = await Future.wait(roots.map(
        (target) => execute(event, target),
      ));
      return result.fold<List<DomainEvent>>(
        <DomainEvent>[],
        (events, list) => events..addAll(list),
      );
    }
    return null;
  }

  Future<Iterable<DomainEvent>> execute(DomainEvent event, String value) async {
    final command = builder(event, value);
    if (command != null) {
      return await target.execute(
        command,
      );
    }
    return [];
  }
}

/// Rule for managing a [AggregateRoot] association
/// between [source] and [target] Repository
class AssociationRule extends AggregateRule {
  AssociationRule(
    CommandBuilder builder, {
    @required Repository target,
    @required String targetField,
    @required this.intent,
    Repository source,
    String sourceField,
    bool local = true,
    this.cardinality = Cardinality.any,
  })  : source = source ?? target,
        sourceField = sourceField ?? (source ?? target).uuidFieldName,
        super(
          builder,
          target,
          targetField,
          local: local,
        );

  final Repository source;

  /// [MapX] path to field in [source] repository
  final String sourceField;

  /// Get intended action if rule applies
  final Action intent;

  /// Get expected cardinality between source and target
  final Cardinality cardinality;

  /// Check if given value is an [AggregateRoot] reference object
  bool isReference(value) => value is Map<String, dynamic> && value.hasPath('${source.uuidFieldName}');

  @override
  Future<Iterable<String>> evaluate(DomainEvent event) async {
    var aggregates = <String>[];
    final value = _toSourceValue(event);
    if (value != null) {
      aggregates = find(target, targetField, value);
    }
    switch (intent) {
      case Action.create:
        if (aggregates.isEmpty) {
          aggregates.add(
            targetField == target.uuidFieldName ? value : Uuid().v4(),
          );
        }
        break;
      case Action.delete:
      case Action.update:
        break;
    }
    return aggregates;
  }

  String _toSourceValue(DomainEvent event) {
    final uuid = source.toAggregateUuid(event);
    if (sourceField != source.uuidFieldName) {
      final value = event.previous?.elementAt(sourceField);
      if (value != null) {
        return value;
      }
      return source.get(uuid, createNew: false)?.data?.elementAt(sourceField);
    }
    return uuid;
  }

  Iterable<String> find(Repository repo, String field, String match) => repo.aggregates
      .where((aggregate) => !aggregate.isDeleted)
      .where((aggregate) => contains(aggregate, field, match))
      .map((aggregate) => aggregate.uuid)
      .toList();

  bool contains(AggregateRoot aggregate, String field, String match) {
    final value = aggregate.data[field];
    if (value is List) {
      return value.contains(match);
    } else if (value is String) {
      return value == match;
    }
    return false;
  }
}
