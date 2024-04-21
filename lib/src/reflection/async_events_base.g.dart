//
// GENERATED CODE - DO NOT MODIFY BY HAND!
// BUILDER: reflection_factory/2.3.4
// BUILD COMMAND: dart run build_runner build
//

// coverage:ignore-file
// ignore_for_file: unused_element
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: camel_case_types
// ignore_for_file: camel_case_extensions
// ignore_for_file: unnecessary_const
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_type_check

part of '../async_events_base.dart';

typedef __TR<T> = TypeReflection<T>;
typedef __TI<T> = TypeInfo<T>;
typedef __PR = ParameterReflection;

mixin __ReflectionMixin {
  static final Version _version = Version.parse('2.3.4');

  Version get reflectionFactoryVersion => _version;

  List<Reflection> siblingsReflection() => _siblingsReflection();
}

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

class AsyncEvent$reflection extends ClassReflection<AsyncEvent>
    with __ReflectionMixin {
  static final Expando<AsyncEvent$reflection> _objectReflections = Expando();

  factory AsyncEvent$reflection([AsyncEvent? object]) {
    if (object == null) return staticInstance;
    return _objectReflections[object] ??= AsyncEvent$reflection._(object);
  }

  AsyncEvent$reflection._([AsyncEvent? object])
      : super(AsyncEvent, 'AsyncEvent', object);

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
  Version get languageVersion => Version.parse('3.0.0');

  @override
  AsyncEvent$reflection withObject([AsyncEvent? obj]) =>
      AsyncEvent$reflection(obj)..setupInternalsWith(this);

  static AsyncEvent$reflection? _withoutObjectInstance;
  @override
  AsyncEvent$reflection withoutObjectInstance() => staticInstance;

  static AsyncEvent$reflection get staticInstance =>
      _withoutObjectInstance ??= AsyncEvent$reflection._();

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

  static const List<String> _constructorsNames = const <String>['', 'fromJson'];

  @override
  List<String> get constructorsNames => _constructorsNames;

  static final Map<String, ConstructorReflection<AsyncEvent>> _constructors =
      {};

  @override
  ConstructorReflection<AsyncEvent>? constructor(String constructorName) {
    var c = _constructors[constructorName];
    if (c != null) return c;
    c = _constructorImpl(constructorName);
    if (c == null) return null;
    _constructors[constructorName] = c;
    return c;
  }

  ConstructorReflection<AsyncEvent>? _constructorImpl(String constructorName) {
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
            const <__PR>[
              __PR(__TR.tString, 'channelName', false, true),
              __PR(__TR.tObject, 'id', false, true),
              __PR(__TR<DateTime>(DateTime), 'time', false, true),
              __PR(__TR.tString, 'type', false, true),
              __PR(__TR.tMapStringDynamic, 'payload', false, true)
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
            const <__PR>[__PR(__TR.tMapStringDynamic, 'json', false, true)],
            null,
            const <String, __PR>{
              'channelName': __PR(__TR.tString, 'channelName', true, false)
            },
            null);
      default:
        return null;
    }
  }

  static const List<Object> _classAnnotations = <Object>[];

  @override
  List<Object> get classAnnotations => _classAnnotations;

  static const List<Type> _supperTypes = const <Type>[Comparable];

  @override
  List<Type> get supperTypes => _supperTypes;

  @override
  bool get hasMethodToJson => true;

  @override
  Object? callMethodToJson([AsyncEvent? obj]) {
    obj ??= object;
    return obj?.toJson();
  }

  static const List<String> _fieldsNames = const <String>[
    'channelName',
    'hashCode',
    'id',
    'payload',
    'time',
    'type'
  ];

  @override
  List<String> get fieldsNames => _fieldsNames;

  static final Map<String, FieldReflection<AsyncEvent, dynamic>>
      _fieldsNoObject = {};

  final Map<String, FieldReflection<AsyncEvent, dynamic>> _fieldsObject = {};

  @override
  FieldReflection<AsyncEvent, T>? field<T>(String fieldName,
      [AsyncEvent? obj]) {
    if (obj == null) {
      if (object != null) {
        return _fieldObjectImpl<T>(fieldName);
      } else {
        return _fieldNoObjectImpl<T>(fieldName);
      }
    } else if (identical(obj, object)) {
      return _fieldObjectImpl<T>(fieldName);
    }
    return _fieldNoObjectImpl<T>(fieldName)?.withObject(obj);
  }

  FieldReflection<AsyncEvent, T>? _fieldNoObjectImpl<T>(String fieldName) {
    final f = _fieldsNoObject[fieldName];
    if (f != null) {
      return f as FieldReflection<AsyncEvent, T>;
    }
    final f2 = _fieldImpl(fieldName, null);
    if (f2 == null) return null;
    _fieldsNoObject[fieldName] = f2;
    return f2 as FieldReflection<AsyncEvent, T>;
  }

  FieldReflection<AsyncEvent, T>? _fieldObjectImpl<T>(String fieldName) {
    final f = _fieldsObject[fieldName];
    if (f != null) {
      return f as FieldReflection<AsyncEvent, T>;
    }
    var f2 = _fieldNoObjectImpl<T>(fieldName);
    if (f2 == null) return null;
    f2 = f2.withObject(object!);
    _fieldsObject[fieldName] = f2;
    return f2;
  }

  FieldReflection<AsyncEvent, dynamic>? _fieldImpl(
      String fieldName, AsyncEvent? obj) {
    obj ??= object;

    var lc = fieldName.trim().toLowerCase();

    switch (lc) {
      case 'channelname':
        return FieldReflection<AsyncEvent, String>(
          this,
          AsyncEvent,
          __TR.tString,
          'channelName',
          false,
          (o) => () => o!.channelName,
          null,
          obj,
          true,
          const [JsonFieldAlias('channel')],
        );
      case 'id':
        return FieldReflection<AsyncEvent, AsyncEventID>(
          this,
          AsyncEvent,
          __TR<AsyncEventID>(AsyncEventID),
          'id',
          false,
          (o) => () => o!.id,
          null,
          obj,
          true,
        );
      case 'time':
        return FieldReflection<AsyncEvent, DateTime>(
          this,
          AsyncEvent,
          __TR<DateTime>(DateTime),
          'time',
          false,
          (o) => () => o!.time,
          null,
          obj,
          true,
        );
      case 'type':
        return FieldReflection<AsyncEvent, String>(
          this,
          AsyncEvent,
          __TR.tString,
          'type',
          false,
          (o) => () => o!.type,
          null,
          obj,
          true,
        );
      case 'payload':
        return FieldReflection<AsyncEvent, Map<String, dynamic>>(
          this,
          AsyncEvent,
          __TR.tMapStringDynamic,
          'payload',
          false,
          (o) => () => o!.payload,
          null,
          obj,
          true,
        );
      case 'hashcode':
        return FieldReflection<AsyncEvent, int>(
          this,
          AsyncEvent,
          __TR.tInt,
          'hashCode',
          false,
          (o) => () => o!.hashCode,
          null,
          obj,
          false,
          const [override],
        );
      default:
        return null;
    }
  }

  @override
  Map<String, dynamic> getFieldsValues(AsyncEvent? obj,
      {bool withHashCode = false}) {
    obj ??= object;
    return <String, dynamic>{
      'channelName': obj?.channelName,
      'id': obj?.id,
      'time': obj?.time,
      'type': obj?.type,
      'payload': obj?.payload,
      if (withHashCode) 'hashCode': obj?.hashCode,
    };
  }

  static const List<String> _staticFieldsNames = const <String>[];

  @override
  List<String> get staticFieldsNames => _staticFieldsNames;

  @override
  StaticFieldReflection<AsyncEvent, T>? staticField<T>(String fieldName) =>
      null;

  static const List<String> _methodsNames = const <String>[
    'compareTo',
    'toJson',
    'toString'
  ];

  @override
  List<String> get methodsNames => _methodsNames;

  static final Map<String, MethodReflection<AsyncEvent, dynamic>>
      _methodsNoObject = {};

  final Map<String, MethodReflection<AsyncEvent, dynamic>> _methodsObject = {};

  @override
  MethodReflection<AsyncEvent, R>? method<R>(String methodName,
      [AsyncEvent? obj]) {
    if (obj == null) {
      if (object != null) {
        return _methodObjectImpl<R>(methodName);
      } else {
        return _methodNoObjectImpl<R>(methodName);
      }
    } else if (identical(obj, object)) {
      return _methodObjectImpl<R>(methodName);
    }
    return _methodNoObjectImpl<R>(methodName)?.withObject(obj);
  }

  MethodReflection<AsyncEvent, R>? _methodNoObjectImpl<R>(String methodName) {
    final m = _methodsNoObject[methodName];
    if (m != null) {
      return m as MethodReflection<AsyncEvent, R>;
    }
    final m2 = _methodImpl(methodName, null);
    if (m2 == null) return null;
    _methodsNoObject[methodName] = m2;
    return m2 as MethodReflection<AsyncEvent, R>;
  }

  MethodReflection<AsyncEvent, R>? _methodObjectImpl<R>(String methodName) {
    final m = _methodsObject[methodName];
    if (m != null) {
      return m as MethodReflection<AsyncEvent, R>;
    }
    var m2 = _methodNoObjectImpl<R>(methodName);
    if (m2 == null) return null;
    m2 = m2.withObject(object!);
    _methodsObject[methodName] = m2;
    return m2;
  }

  MethodReflection<AsyncEvent, dynamic>? _methodImpl(
      String methodName, AsyncEvent? obj) {
    obj ??= object;

    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'compareto':
        return MethodReflection<AsyncEvent, int>(
            this,
            AsyncEvent,
            'compareTo',
            __TR.tInt,
            false,
            (o) => o!.compareTo,
            obj,
            const <__PR>[
              __PR(__TR<AsyncEvent>(AsyncEvent), 'other', false, true)
            ],
            null,
            null,
            const [override]);
      case 'tojson':
        return MethodReflection<AsyncEvent, Map<String, dynamic>>(
            this,
            AsyncEvent,
            'toJson',
            __TR.tMapStringDynamic,
            false,
            (o) => o!.toJson,
            obj,
            null,
            null,
            const <String, __PR>{
              'withChannelName':
                  __PR(__TR.tBool, 'withChannelName', false, false, true)
            },
            null);
      case 'tostring':
        return MethodReflection<AsyncEvent, String>(
            this,
            AsyncEvent,
            'toString',
            __TR.tString,
            false,
            (o) => o!.toString,
            obj,
            null,
            null,
            null,
            const [override]);
      default:
        return null;
    }
  }

  static const List<String> _staticMethodsNames = const <String>['boot'];

  @override
  List<String> get staticMethodsNames => _staticMethodsNames;

  static final Map<String, StaticMethodReflection<AsyncEvent, dynamic>>
      _staticMethods = {};

  @override
  StaticMethodReflection<AsyncEvent, R>? staticMethod<R>(String methodName) {
    var m = _staticMethods[methodName];
    if (m != null) {
      return m as StaticMethodReflection<AsyncEvent, R>;
    }
    m = _staticMethodImpl(methodName);
    if (m == null) return null;
    _staticMethods[methodName] = m;
    return m as StaticMethodReflection<AsyncEvent, R>;
  }

  StaticMethodReflection<AsyncEvent, dynamic>? _staticMethodImpl(
      String methodName) {
    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'boot':
        return StaticMethodReflection<AsyncEvent, void>(
            this,
            AsyncEvent,
            'boot',
            __TR.tVoid,
            false,
            () => AsyncEvent.boot,
            null,
            null,
            null,
            null);
      default:
        return null;
    }
  }
}

class AsyncEventID$reflection extends ClassReflection<AsyncEventID>
    with __ReflectionMixin {
  static final Expando<AsyncEventID$reflection> _objectReflections = Expando();

  factory AsyncEventID$reflection([AsyncEventID? object]) {
    if (object == null) return staticInstance;
    return _objectReflections[object] ??= AsyncEventID$reflection._(object);
  }

  AsyncEventID$reflection._([AsyncEventID? object])
      : super(AsyncEventID, 'AsyncEventID', object);

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
  Version get languageVersion => Version.parse('3.0.0');

  @override
  AsyncEventID$reflection withObject([AsyncEventID? obj]) =>
      AsyncEventID$reflection(obj)..setupInternalsWith(this);

  static AsyncEventID$reflection? _withoutObjectInstance;
  @override
  AsyncEventID$reflection withoutObjectInstance() => staticInstance;

  static AsyncEventID$reflection get staticInstance =>
      _withoutObjectInstance ??= AsyncEventID$reflection._();

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

  static const List<String> _constructorsNames = const <String>[
    '',
    'any',
    'from',
    'fromJson',
    'parse',
    'zero'
  ];

  @override
  List<String> get constructorsNames => _constructorsNames;

  static final Map<String, ConstructorReflection<AsyncEventID>> _constructors =
      {};

  @override
  ConstructorReflection<AsyncEventID>? constructor(String constructorName) {
    var c = _constructors[constructorName];
    if (c != null) return c;
    c = _constructorImpl(constructorName);
    if (c == null) return null;
    _constructors[constructorName] = c;
    return c;
  }

  ConstructorReflection<AsyncEventID>? _constructorImpl(
      String constructorName) {
    var lc = constructorName.trim().toLowerCase();

    switch (lc) {
      case '':
        return ConstructorReflection<AsyncEventID>(
            this,
            AsyncEventID,
            '',
            () => (int epoch, int serial) => AsyncEventID(epoch, serial),
            const <__PR>[
              __PR(__TR.tInt, 'epoch', false, true),
              __PR(__TR.tInt, 'serial', false, true)
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
            const <__PR>[__PR(__TR.tObject, 'o', false, true)],
            null,
            null,
            null);
      case 'fromjson':
        return ConstructorReflection<AsyncEventID>(
            this,
            AsyncEventID,
            'fromJson',
            () => (Map<String, dynamic> json) => AsyncEventID.fromJson(json),
            const <__PR>[__PR(__TR.tMapStringDynamic, 'json', false, true)],
            null,
            null,
            null);
      case 'parse':
        return ConstructorReflection<AsyncEventID>(
            this,
            AsyncEventID,
            'parse',
            () => (String s) => AsyncEventID.parse(s),
            const <__PR>[__PR(__TR.tString, 's', false, true)],
            null,
            null,
            null);
      default:
        return null;
    }
  }

  static const List<Object> _classAnnotations = <Object>[];

  @override
  List<Object> get classAnnotations => _classAnnotations;

  static const List<Type> _supperTypes = const <Type>[Comparable];

  @override
  List<Type> get supperTypes => _supperTypes;

  @override
  bool get hasMethodToJson => true;

  @override
  Object? callMethodToJson([AsyncEventID? obj]) {
    obj ??= object;
    return obj?.toJson();
  }

  static const List<String> _fieldsNames = const <String>[
    'epoch',
    'hashCode',
    'next',
    'previous',
    'serial'
  ];

  @override
  List<String> get fieldsNames => _fieldsNames;

  static final Map<String, FieldReflection<AsyncEventID, dynamic>>
      _fieldsNoObject = {};

  final Map<String, FieldReflection<AsyncEventID, dynamic>> _fieldsObject = {};

  @override
  FieldReflection<AsyncEventID, T>? field<T>(String fieldName,
      [AsyncEventID? obj]) {
    if (obj == null) {
      if (object != null) {
        return _fieldObjectImpl<T>(fieldName);
      } else {
        return _fieldNoObjectImpl<T>(fieldName);
      }
    } else if (identical(obj, object)) {
      return _fieldObjectImpl<T>(fieldName);
    }
    return _fieldNoObjectImpl<T>(fieldName)?.withObject(obj);
  }

  FieldReflection<AsyncEventID, T>? _fieldNoObjectImpl<T>(String fieldName) {
    final f = _fieldsNoObject[fieldName];
    if (f != null) {
      return f as FieldReflection<AsyncEventID, T>;
    }
    final f2 = _fieldImpl(fieldName, null);
    if (f2 == null) return null;
    _fieldsNoObject[fieldName] = f2;
    return f2 as FieldReflection<AsyncEventID, T>;
  }

  FieldReflection<AsyncEventID, T>? _fieldObjectImpl<T>(String fieldName) {
    final f = _fieldsObject[fieldName];
    if (f != null) {
      return f as FieldReflection<AsyncEventID, T>;
    }
    var f2 = _fieldNoObjectImpl<T>(fieldName);
    if (f2 == null) return null;
    f2 = f2.withObject(object!);
    _fieldsObject[fieldName] = f2;
    return f2;
  }

  FieldReflection<AsyncEventID, dynamic>? _fieldImpl(
      String fieldName, AsyncEventID? obj) {
    obj ??= object;

    var lc = fieldName.trim().toLowerCase();

    switch (lc) {
      case 'epoch':
        return FieldReflection<AsyncEventID, int>(
          this,
          AsyncEventID,
          __TR.tInt,
          'epoch',
          false,
          (o) => () => o!.epoch,
          null,
          obj,
          true,
        );
      case 'serial':
        return FieldReflection<AsyncEventID, int>(
          this,
          AsyncEventID,
          __TR.tInt,
          'serial',
          false,
          (o) => () => o!.serial,
          null,
          obj,
          true,
        );
      case 'previous':
        return FieldReflection<AsyncEventID, AsyncEventID?>(
          this,
          AsyncEventID,
          __TR<AsyncEventID>(AsyncEventID),
          'previous',
          true,
          (o) => () => o!.previous,
          null,
          obj,
          false,
        );
      case 'next':
        return FieldReflection<AsyncEventID, AsyncEventID?>(
          this,
          AsyncEventID,
          __TR<AsyncEventID>(AsyncEventID),
          'next',
          true,
          (o) => () => o!.next,
          null,
          obj,
          false,
        );
      case 'hashcode':
        return FieldReflection<AsyncEventID, int>(
          this,
          AsyncEventID,
          __TR.tInt,
          'hashCode',
          false,
          (o) => () => o!.hashCode,
          null,
          obj,
          false,
          const [override],
        );
      default:
        return null;
    }
  }

  @override
  Map<String, dynamic> getFieldsValues(AsyncEventID? obj,
      {bool withHashCode = false}) {
    obj ??= object;
    return <String, dynamic>{
      'epoch': obj?.epoch,
      'serial': obj?.serial,
      'previous': obj?.previous,
      'next': obj?.next,
      if (withHashCode) 'hashCode': obj?.hashCode,
    };
  }

  static const List<String> _staticFieldsNames = const <String>[];

  @override
  List<String> get staticFieldsNames => _staticFieldsNames;

  @override
  StaticFieldReflection<AsyncEventID, T>? staticField<T>(String fieldName) =>
      null;

  static const List<String> _methodsNames = const <String>[
    'compareTo',
    'toJson',
    'toString'
  ];

  @override
  List<String> get methodsNames => _methodsNames;

  static final Map<String, MethodReflection<AsyncEventID, dynamic>>
      _methodsNoObject = {};

  final Map<String, MethodReflection<AsyncEventID, dynamic>> _methodsObject =
      {};

  @override
  MethodReflection<AsyncEventID, R>? method<R>(String methodName,
      [AsyncEventID? obj]) {
    if (obj == null) {
      if (object != null) {
        return _methodObjectImpl<R>(methodName);
      } else {
        return _methodNoObjectImpl<R>(methodName);
      }
    } else if (identical(obj, object)) {
      return _methodObjectImpl<R>(methodName);
    }
    return _methodNoObjectImpl<R>(methodName)?.withObject(obj);
  }

  MethodReflection<AsyncEventID, R>? _methodNoObjectImpl<R>(String methodName) {
    final m = _methodsNoObject[methodName];
    if (m != null) {
      return m as MethodReflection<AsyncEventID, R>;
    }
    final m2 = _methodImpl(methodName, null);
    if (m2 == null) return null;
    _methodsNoObject[methodName] = m2;
    return m2 as MethodReflection<AsyncEventID, R>;
  }

  MethodReflection<AsyncEventID, R>? _methodObjectImpl<R>(String methodName) {
    final m = _methodsObject[methodName];
    if (m != null) {
      return m as MethodReflection<AsyncEventID, R>;
    }
    var m2 = _methodNoObjectImpl<R>(methodName);
    if (m2 == null) return null;
    m2 = m2.withObject(object!);
    _methodsObject[methodName] = m2;
    return m2;
  }

  MethodReflection<AsyncEventID, dynamic>? _methodImpl(
      String methodName, AsyncEventID? obj) {
    obj ??= object;

    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'compareto':
        return MethodReflection<AsyncEventID, int>(
            this,
            AsyncEventID,
            'compareTo',
            __TR.tInt,
            false,
            (o) => o!.compareTo,
            obj,
            const <__PR>[
              __PR(__TR<AsyncEventID>(AsyncEventID), 'other', false, true)
            ],
            null,
            null,
            const [override]);
      case 'tojson':
        return MethodReflection<AsyncEventID, Map<String, dynamic>>(
            this,
            AsyncEventID,
            'toJson',
            __TR.tMapStringDynamic,
            false,
            (o) => o!.toJson,
            obj,
            null,
            null,
            null,
            null);
      case 'tostring':
        return MethodReflection<AsyncEventID, String>(
            this,
            AsyncEventID,
            'toString',
            __TR.tString,
            false,
            (o) => o!.toString,
            obj,
            null,
            null,
            null,
            const [override]);
      default:
        return null;
    }
  }

  static const List<String> _staticMethodsNames = const <String>['boot'];

  @override
  List<String> get staticMethodsNames => _staticMethodsNames;

  static final Map<String, StaticMethodReflection<AsyncEventID, dynamic>>
      _staticMethods = {};

  @override
  StaticMethodReflection<AsyncEventID, R>? staticMethod<R>(String methodName) {
    var m = _staticMethods[methodName];
    if (m != null) {
      return m as StaticMethodReflection<AsyncEventID, R>;
    }
    m = _staticMethodImpl(methodName);
    if (m == null) return null;
    _staticMethods[methodName] = m;
    return m as StaticMethodReflection<AsyncEventID, R>;
  }

  StaticMethodReflection<AsyncEventID, dynamic>? _staticMethodImpl(
      String methodName) {
    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'boot':
        return StaticMethodReflection<AsyncEventID, void>(
            this,
            AsyncEventID,
            'boot',
            __TR.tVoid,
            false,
            () => AsyncEventID.boot,
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
