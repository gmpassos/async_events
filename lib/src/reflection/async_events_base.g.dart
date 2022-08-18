//
// GENERATED CODE - DO NOT MODIFY BY HAND!
// BUILDER: reflection_factory/1.2.6
// BUILD COMMAND: dart run build_runner build
//

// coverage:ignore-file
// ignore_for_file: unnecessary_const
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_type_check

part of '../async_events_base.dart';

// ignore: non_constant_identifier_names
AsyncEvent AsyncEvent$fromJson(Map<String, Object?> map) =>
    AsyncEvent$reflection.staticInstance.fromJson(map);
// ignore: non_constant_identifier_names
AsyncEvent AsyncEvent$fromJsonEncoded(String jsonEncoded) =>
    AsyncEvent$reflection.staticInstance.fromJsonEncoded(jsonEncoded);
// ignore: non_constant_identifier_names
AsyncEventID AsyncEventID$fromJson(Map<String, Object?> map) =>
    AsyncEventID$reflection.staticInstance.fromJson(map);
// ignore: non_constant_identifier_names
AsyncEventID AsyncEventID$fromJsonEncoded(String jsonEncoded) =>
    AsyncEventID$reflection.staticInstance.fromJsonEncoded(jsonEncoded);

class AsyncEvent$reflection extends ClassReflection<AsyncEvent> {
  AsyncEvent$reflection([AsyncEvent? object]) : super(AsyncEvent, object);

  static bool _registered = false;
  @override
  void register() {
    if (!_registered) {
      _registered = true;
      super.register();
      _registerSiblingsReflection();
    }
  }

  @override
  Version get languageVersion => Version.parse('2.17.0');

  @override
  Version get reflectionFactoryVersion => Version.parse('1.2.6');

  @override
  AsyncEvent$reflection withObject([AsyncEvent? obj]) =>
      AsyncEvent$reflection(obj);

  static AsyncEvent$reflection? _withoutObjectInstance;
  @override
  AsyncEvent$reflection withoutObjectInstance() => _withoutObjectInstance ??=
      super.withoutObjectInstance() as AsyncEvent$reflection;

  static AsyncEvent$reflection get staticInstance =>
      _withoutObjectInstance ??= AsyncEvent$reflection();

  @override
  AsyncEvent$reflection getStaticInstance() => staticInstance;

  static bool _boot = false;
  static void boot() {
    if (_boot) return;
    _boot = true;
    AsyncEvent$reflection.staticInstance;
  }

  @override
  bool get hasDefaultConstructor => false;
  @override
  AsyncEvent? createInstanceWithDefaultConstructor() => null;

  @override
  bool get hasEmptyConstructor => false;
  @override
  AsyncEvent? createInstanceWithEmptyConstructor() => null;
  @override
  bool get hasNoRequiredArgsConstructor => false;
  @override
  AsyncEvent? createInstanceWithNoRequiredArgsConstructor() => null;

  @override
  List<String> get constructorsNames => const <String>['', 'fromJson'];

  @override
  ConstructorReflection<AsyncEvent>? constructor<R>(String constructorName) {
    var lc = constructorName.trim().toLowerCase();

    switch (lc) {
      case '':
        return ConstructorReflection<AsyncEvent>(
            this,
            AsyncEvent,
            '',
            () => (String channelName, Object id, DateTime time, String type,
                    Map<String, dynamic> payload) =>
                AsyncEvent(channelName, id, time, type, payload),
            const <ParameterReflection>[
              ParameterReflection(TypeReflection.tString, 'channelName', false,
                  true, null, null),
              ParameterReflection(
                  TypeReflection.tObject, 'id', false, true, null, null),
              ParameterReflection(
                  TypeReflection(DateTime), 'time', false, true, null, null),
              ParameterReflection(
                  TypeReflection.tString, 'type', false, true, null, null),
              ParameterReflection(TypeReflection.tMapStringDynamic, 'payload',
                  false, true, null, null)
            ],
            null,
            null,
            null);
      case 'fromjson':
        return ConstructorReflection<AsyncEvent>(
            this,
            AsyncEvent,
            'fromJson',
            () => (Map<String, dynamic> json, {String? channelName}) =>
                AsyncEvent.fromJson(json, channelName: channelName),
            const <ParameterReflection>[
              ParameterReflection(TypeReflection.tMapStringDynamic, 'json',
                  false, true, null, null)
            ],
            null,
            const <String, ParameterReflection>{
              'channelName': ParameterReflection(TypeReflection.tString,
                  'channelName', true, false, null, null)
            },
            null);
      default:
        return null;
    }
  }

  @override
  List<Object> get classAnnotations => List<Object>.unmodifiable(<Object>[]);

  @override
  List<ClassReflection> siblingsClassReflection() =>
      _siblingsReflection().whereType<ClassReflection>().toList();

  @override
  List<Reflection> siblingsReflection() => _siblingsReflection();

  @override
  List<Type> get supperTypes => const <Type>[Comparable];

  @override
  bool get hasMethodToJson => true;

  @override
  Object? callMethodToJson([AsyncEvent? obj]) {
    obj ??= object;
    return obj?.toJson();
  }

  @override
  List<String> get fieldsNames => const <String>[
        'channelName',
        'hashCode',
        'id',
        'payload',
        'time',
        'type'
      ];

  @override
  FieldReflection<AsyncEvent, T>? field<T>(String fieldName,
      [AsyncEvent? obj]) {
    obj ??= object;

    var lc = fieldName.trim().toLowerCase();

    switch (lc) {
      case 'channelname':
        return FieldReflection<AsyncEvent, T>(
          this,
          AsyncEvent,
          TypeReflection.tString,
          'channelName',
          false,
          (o) => () => o!.channelName as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'id':
        return FieldReflection<AsyncEvent, T>(
          this,
          AsyncEvent,
          TypeReflection(AsyncEventID),
          'id',
          false,
          (o) => () => o!.id as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'time':
        return FieldReflection<AsyncEvent, T>(
          this,
          AsyncEvent,
          TypeReflection(DateTime),
          'time',
          false,
          (o) => () => o!.time as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'type':
        return FieldReflection<AsyncEvent, T>(
          this,
          AsyncEvent,
          TypeReflection.tString,
          'type',
          false,
          (o) => () => o!.type as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'payload':
        return FieldReflection<AsyncEvent, T>(
          this,
          AsyncEvent,
          TypeReflection.tMapStringDynamic,
          'payload',
          false,
          (o) => () => o!.payload as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'hashcode':
        return FieldReflection<AsyncEvent, T>(
          this,
          AsyncEvent,
          TypeReflection.tInt,
          'hashCode',
          false,
          (o) => () => o!.hashCode as T,
          null,
          obj,
          false,
          false,
          [override],
        );
      default:
        return null;
    }
  }

  @override
  List<String> get staticFieldsNames => const <String>[];

  @override
  FieldReflection<AsyncEvent, T>? staticField<T>(String fieldName) {
    return null;
  }

  @override
  List<String> get methodsNames =>
      const <String>['compareTo', 'toJson', 'toString'];

  @override
  MethodReflection<AsyncEvent, R>? method<R>(String methodName,
      [AsyncEvent? obj]) {
    obj ??= object;

    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'compareto':
        return MethodReflection<AsyncEvent, R>(
            this,
            AsyncEvent,
            'compareTo',
            TypeReflection.tInt,
            false,
            (o) => o!.compareTo,
            obj,
            false,
            const <ParameterReflection>[
              ParameterReflection(
                  TypeReflection(AsyncEvent), 'other', false, true, null, null)
            ],
            null,
            null,
            [override]);
      case 'tojson':
        return MethodReflection<AsyncEvent, R>(
            this,
            AsyncEvent,
            'toJson',
            TypeReflection.tMapStringDynamic,
            false,
            (o) => o!.toJson,
            obj,
            false,
            null,
            null,
            const <String, ParameterReflection>{
              'withChannelName': ParameterReflection(TypeReflection.tBool,
                  'withChannelName', false, false, true, null)
            },
            null);
      case 'tostring':
        return MethodReflection<AsyncEvent, R>(
            this,
            AsyncEvent,
            'toString',
            TypeReflection.tString,
            false,
            (o) => o!.toString,
            obj,
            false,
            null,
            null,
            null,
            [override]);
      default:
        return null;
    }
  }

  @override
  List<String> get staticMethodsNames => const <String>['boot'];

  @override
  MethodReflection<AsyncEvent, R>? staticMethod<R>(String methodName) {
    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'boot':
        return MethodReflection<AsyncEvent, R>(
            this,
            AsyncEvent,
            'boot',
            TypeReflection.tVoid,
            false,
            (o) => AsyncEvent.boot,
            null,
            true,
            null,
            null,
            null,
            null);
      default:
        return null;
    }
  }
}

class AsyncEventID$reflection extends ClassReflection<AsyncEventID> {
  AsyncEventID$reflection([AsyncEventID? object]) : super(AsyncEventID, object);

  static bool _registered = false;
  @override
  void register() {
    if (!_registered) {
      _registered = true;
      super.register();
      _registerSiblingsReflection();
    }
  }

  @override
  Version get languageVersion => Version.parse('2.17.0');

  @override
  Version get reflectionFactoryVersion => Version.parse('1.2.6');

  @override
  AsyncEventID$reflection withObject([AsyncEventID? obj]) =>
      AsyncEventID$reflection(obj);

  static AsyncEventID$reflection? _withoutObjectInstance;
  @override
  AsyncEventID$reflection withoutObjectInstance() => _withoutObjectInstance ??=
      super.withoutObjectInstance() as AsyncEventID$reflection;

  static AsyncEventID$reflection get staticInstance =>
      _withoutObjectInstance ??= AsyncEventID$reflection();

  @override
  AsyncEventID$reflection getStaticInstance() => staticInstance;

  static bool _boot = false;
  static void boot() {
    if (_boot) return;
    _boot = true;
    AsyncEventID$reflection.staticInstance;
  }

  @override
  bool get hasDefaultConstructor => false;
  @override
  AsyncEventID? createInstanceWithDefaultConstructor() => null;

  @override
  bool get hasEmptyConstructor => true;
  @override
  AsyncEventID? createInstanceWithEmptyConstructor() => AsyncEventID.zero();
  @override
  bool get hasNoRequiredArgsConstructor => true;
  @override
  AsyncEventID? createInstanceWithNoRequiredArgsConstructor() =>
      AsyncEventID.zero();

  @override
  List<String> get constructorsNames =>
      const <String>['', 'any', 'from', 'fromJson', 'parse', 'zero'];

  @override
  ConstructorReflection<AsyncEventID>? constructor<R>(String constructorName) {
    var lc = constructorName.trim().toLowerCase();

    switch (lc) {
      case '':
        return ConstructorReflection<AsyncEventID>(
            this,
            AsyncEventID,
            '',
            () => (int epoch, int serial) => AsyncEventID(epoch, serial),
            const <ParameterReflection>[
              ParameterReflection(
                  TypeReflection.tInt, 'epoch', false, true, null, null),
              ParameterReflection(
                  TypeReflection.tInt, 'serial', false, true, null, null)
            ],
            null,
            null,
            null);
      case 'zero':
        return ConstructorReflection<AsyncEventID>(this, AsyncEventID, 'zero',
            () => () => AsyncEventID.zero(), null, null, null, null);
      case 'any':
        return ConstructorReflection<AsyncEventID>(this, AsyncEventID, 'any',
            () => () => AsyncEventID.any(), null, null, null, null);
      case 'from':
        return ConstructorReflection<AsyncEventID>(
            this,
            AsyncEventID,
            'from',
            () => (Object o) => AsyncEventID.from(o),
            const <ParameterReflection>[
              ParameterReflection(
                  TypeReflection.tObject, 'o', false, true, null, null)
            ],
            null,
            null,
            null);
      case 'fromjson':
        return ConstructorReflection<AsyncEventID>(
            this,
            AsyncEventID,
            'fromJson',
            () => (Map<String, dynamic> json) => AsyncEventID.fromJson(json),
            const <ParameterReflection>[
              ParameterReflection(TypeReflection.tMapStringDynamic, 'json',
                  false, true, null, null)
            ],
            null,
            null,
            null);
      case 'parse':
        return ConstructorReflection<AsyncEventID>(
            this,
            AsyncEventID,
            'parse',
            () => (String s) => AsyncEventID.parse(s),
            const <ParameterReflection>[
              ParameterReflection(
                  TypeReflection.tString, 's', false, true, null, null)
            ],
            null,
            null,
            null);
      default:
        return null;
    }
  }

  @override
  List<Object> get classAnnotations => List<Object>.unmodifiable(<Object>[]);

  @override
  List<ClassReflection> siblingsClassReflection() =>
      _siblingsReflection().whereType<ClassReflection>().toList();

  @override
  List<Reflection> siblingsReflection() => _siblingsReflection();

  @override
  List<Type> get supperTypes => const <Type>[Comparable];

  @override
  bool get hasMethodToJson => true;

  @override
  Object? callMethodToJson([AsyncEventID? obj]) {
    obj ??= object;
    return obj?.toJson();
  }

  @override
  List<String> get fieldsNames =>
      const <String>['epoch', 'hashCode', 'next', 'previous', 'serial'];

  @override
  FieldReflection<AsyncEventID, T>? field<T>(String fieldName,
      [AsyncEventID? obj]) {
    obj ??= object;

    var lc = fieldName.trim().toLowerCase();

    switch (lc) {
      case 'epoch':
        return FieldReflection<AsyncEventID, T>(
          this,
          AsyncEventID,
          TypeReflection.tInt,
          'epoch',
          false,
          (o) => () => o!.epoch as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'serial':
        return FieldReflection<AsyncEventID, T>(
          this,
          AsyncEventID,
          TypeReflection.tInt,
          'serial',
          false,
          (o) => () => o!.serial as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'previous':
        return FieldReflection<AsyncEventID, T>(
          this,
          AsyncEventID,
          TypeReflection(AsyncEventID),
          'previous',
          true,
          (o) => () => o!.previous as T,
          null,
          obj,
          false,
          false,
          null,
        );
      case 'next':
        return FieldReflection<AsyncEventID, T>(
          this,
          AsyncEventID,
          TypeReflection(AsyncEventID),
          'next',
          true,
          (o) => () => o!.next as T,
          null,
          obj,
          false,
          false,
          null,
        );
      case 'hashcode':
        return FieldReflection<AsyncEventID, T>(
          this,
          AsyncEventID,
          TypeReflection.tInt,
          'hashCode',
          false,
          (o) => () => o!.hashCode as T,
          null,
          obj,
          false,
          false,
          [override],
        );
      default:
        return null;
    }
  }

  @override
  List<String> get staticFieldsNames => const <String>[];

  @override
  FieldReflection<AsyncEventID, T>? staticField<T>(String fieldName) {
    return null;
  }

  @override
  List<String> get methodsNames =>
      const <String>['compareTo', 'toJson', 'toString'];

  @override
  MethodReflection<AsyncEventID, R>? method<R>(String methodName,
      [AsyncEventID? obj]) {
    obj ??= object;

    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'compareto':
        return MethodReflection<AsyncEventID, R>(
            this,
            AsyncEventID,
            'compareTo',
            TypeReflection.tInt,
            false,
            (o) => o!.compareTo,
            obj,
            false,
            const <ParameterReflection>[
              ParameterReflection(TypeReflection(AsyncEventID), 'other', false,
                  true, null, null)
            ],
            null,
            null,
            [override]);
      case 'tojson':
        return MethodReflection<AsyncEventID, R>(
            this,
            AsyncEventID,
            'toJson',
            TypeReflection.tMapStringDynamic,
            false,
            (o) => o!.toJson,
            obj,
            false,
            null,
            null,
            null,
            null);
      case 'tostring':
        return MethodReflection<AsyncEventID, R>(
            this,
            AsyncEventID,
            'toString',
            TypeReflection.tString,
            false,
            (o) => o!.toString,
            obj,
            false,
            null,
            null,
            null,
            [override]);
      default:
        return null;
    }
  }

  @override
  List<String> get staticMethodsNames => const <String>['boot'];

  @override
  MethodReflection<AsyncEventID, R>? staticMethod<R>(String methodName) {
    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'boot':
        return MethodReflection<AsyncEventID, R>(
            this,
            AsyncEventID,
            'boot',
            TypeReflection.tVoid,
            false,
            (o) => AsyncEventID.boot,
            null,
            true,
            null,
            null,
            null,
            null);
      default:
        return null;
    }
  }
}

extension AsyncEvent$reflectionExtension on AsyncEvent {
  /// Returns a [ClassReflection] for type [AsyncEvent]. (Generated by [ReflectionFactory])
  ClassReflection<AsyncEvent> get reflection => AsyncEvent$reflection(this);

  /// Returns a JSON [Map] for type [AsyncEvent]. (Generated by [ReflectionFactory])
  Map<String, dynamic>? toJsonMap({bool duplicatedEntitiesAsID = false}) =>
      reflection.toJsonMap(duplicatedEntitiesAsID: duplicatedEntitiesAsID);

  /// Returns an encoded JSON [String] for type [AsyncEvent]. (Generated by [ReflectionFactory])
  String toJsonEncoded(
          {bool pretty = false, bool duplicatedEntitiesAsID = false}) =>
      reflection.toJsonEncoded(
          pretty: pretty, duplicatedEntitiesAsID: duplicatedEntitiesAsID);

  /// Returns a JSON for type [AsyncEvent] using the class fields. (Generated by [ReflectionFactory])
  Object? toJsonFromFields({bool duplicatedEntitiesAsID = false}) => reflection
      .toJsonFromFields(duplicatedEntitiesAsID: duplicatedEntitiesAsID);
}

extension AsyncEventID$reflectionExtension on AsyncEventID {
  /// Returns a [ClassReflection] for type [AsyncEventID]. (Generated by [ReflectionFactory])
  ClassReflection<AsyncEventID> get reflection => AsyncEventID$reflection(this);

  /// Returns a JSON [Map] for type [AsyncEventID]. (Generated by [ReflectionFactory])
  Map<String, dynamic>? toJsonMap({bool duplicatedEntitiesAsID = false}) =>
      reflection.toJsonMap(duplicatedEntitiesAsID: duplicatedEntitiesAsID);

  /// Returns an encoded JSON [String] for type [AsyncEventID]. (Generated by [ReflectionFactory])
  String toJsonEncoded(
          {bool pretty = false, bool duplicatedEntitiesAsID = false}) =>
      reflection.toJsonEncoded(
          pretty: pretty, duplicatedEntitiesAsID: duplicatedEntitiesAsID);

  /// Returns a JSON for type [AsyncEventID] using the class fields. (Generated by [ReflectionFactory])
  Object? toJsonFromFields({bool duplicatedEntitiesAsID = false}) => reflection
      .toJsonFromFields(duplicatedEntitiesAsID: duplicatedEntitiesAsID);
}

List<Reflection> _listSiblingsReflection() => <Reflection>[
      AsyncEventID$reflection(),
      AsyncEvent$reflection(),
    ];

List<Reflection>? _siblingsReflectionList;
List<Reflection> _siblingsReflection() => _siblingsReflectionList ??=
    List<Reflection>.unmodifiable(_listSiblingsReflection());

bool _registerSiblingsReflectionCalled = false;
void _registerSiblingsReflection() {
  if (_registerSiblingsReflectionCalled) return;
  _registerSiblingsReflectionCalled = true;
  var length = _listSiblingsReflection().length;
  assert(length > 0);
}
