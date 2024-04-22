import 'package:async_events/async_events.dart';
import 'package:async_extension/async_extension.dart';
import 'package:logging/logging.dart' as logging;
import 'package:reflection_factory/reflection_factory.dart';
import 'package:test/test.dart';

final log = logging.Logger('Test');

const _epochPeriod = Duration(seconds: 2);

void main() {
  logging.Logger.root.level = logging.Level.ALL;
  logging.Logger.root.onRecord
      .listen((event) => print('${DateTime.now()}\t$event'));

  group('AsyncEvent', () {
    test('insertSorted', () async {
      {
        var l0 = <AsyncEvent>[];

        l0.insertSorted(
            AsyncEvent('a', AsyncEventID(0, 2), DateTime.now(), 't', {'n': 2}));

        l0.insertSorted(
            AsyncEvent('a', AsyncEventID(0, 3), DateTime.now(), 't', {'n': 3}));

        expect(l0.map((e) => e.id.toString()), equals(['0#2', '0#3']));
      }

      {
        var l0 = <AsyncEvent>[];

        l0.insertSorted(
            AsyncEvent('a', AsyncEventID(0, 2), DateTime.now(), 't', {'n': 2}));

        l0.insertSorted(
            AsyncEvent('a', AsyncEventID(0, 1), DateTime.now(), 't', {'n': 1}));

        expect(l0.map((e) => e.id.toString()), equals(['0#1', '0#2']));
      }

      var l1 = <AsyncEvent>[
        AsyncEvent('a', AsyncEventID(0, 0), DateTime.now(), 'new_epoch', {}),
        AsyncEvent('a', AsyncEventID(0, 1), DateTime.now(), 't', {'n': 1}),
        AsyncEvent('a', AsyncEventID(0, 2), DateTime.now(), 't', {'n': 2}),
        AsyncEvent('a', AsyncEventID(0, 3), DateTime.now(), 't', {'n': 3}),
      ];

      l1.insertSorted(
          AsyncEvent('a', AsyncEventID(0, 4), DateTime.now(), 't', {'n': 4}));

      expect(l1.map((e) => e.id.toString()),
          equals(['0#0', '0#1', '0#2', '0#3', '0#4']));

      var l2 = l1.sublist(2);

      expect(l2.map((e) => e.id.toString()), equals(['0#2', '0#3', '0#4']));

      l2.insertSorted(
          AsyncEvent('a', AsyncEventID(0, 1), DateTime.now(), 't', {'n': 1}));

      expect(
          l2.map((e) => e.id.toString()), equals(['0#1', '0#2', '0#3', '0#4']));
    });

    test('json', () async {
      var now = DateTime.now();

      var event1 = AsyncEvent('foo', AsyncEventID(1, 2), now, 'test', {'a': 1});
      expect(event1.toJson(), equals(event1.toJson()));

      expect(AsyncEvent.fromJson(event1.toJson()), equals(event1));

      var classReflection =
          ReflectionFactory().getRegisterClassReflection<AsyncEvent>()!;

      expect(classReflection.fromJson(event1.toJson()), equals(event1));
    });

    test('basic', () async {
      var storage =
          AsyncEventStorageMemory('test-memory', epochPeriod: _epochPeriod);
      var hub = AsyncEventHub('test', storage);

      await _doTestBasic(hub, log, storage);
    });

    test('remote', () async {
      var server = _MyAsyncEventStorageServer(
          AsyncEventStorageMemory('test-server', epochPeriod: _epochPeriod));
      var client = _MyAsyncEventStorageClient(server);

      var storage = AsyncEventStorageRemote('test', client);
      var hub = AsyncEventHub('test', storage);

      await _doTestBasic(hub, log, storage);
    });
  });
}

Future<void> _doTestBasic(
    AsyncEventHub hub, logging.Logger log, AsyncEventStorage storage) async {
  log.info('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
  log.info("Hub: $hub");
  log.info("Storage: $storage");

  var c1 = hub.channel('c1');
  var c2 = hub.channel('c2');

  var c1Events = <AsyncEvent>[];
  var c2Events = <AsyncEvent>[];

  var sub1 = await c1.subscribe((e) {
    c1Events.add(e);
    log.info('C1>> $e');
  });

  var sub2 = await c2.subscribe((e) {
    c2Events.add(e);
    log.info('C2>> $e');
  });

  var eventC1_1 = await c1.submit('t', {'name': 't1'});
  var eventC2_1 = await c2.submit('t', {'name': 't2'});

  await sub1.pull();
  await sub2.pull();

  expect(c1Events.map((e) => e.toJson()), [eventC1_1!.toJson()]);
  expect(c2Events.map((e) => e.toJson()), [eventC2_1!.toJson()]);

  var c2bEvents = <AsyncEvent>[];

  var sub2bAsync = c2.subscribe(fromBegin: true, (e) {
    c2bEvents.add(e);
    log.info('C2/b>> $e');
  });

  var eventC2_2 = await c2.submit('t', {'name': 't3'});

  var sub2b = await sub2bAsync;

  await sub2b.pull();

  expect(c2bEvents.map((e) => e.toJson()),
      [eventC2_1.toJson(), eventC2_2!.toJson()]);

  expect(c2Events.map((e) => e.toJson()),
      [eventC2_1.toJson(), eventC2_2.toJson()]);

  var eventPulling = AsyncEventPulling(c1, period: Duration(milliseconds: 200));

  expect(eventPulling.period.inMilliseconds, equals(200));
  expect(eventPulling.minInterval.inMilliseconds, equals(20));
  expect(eventPulling.isStarted, isFalse);
  expect(eventPulling.isStopped, isFalse);
  expect(eventPulling.isScheduled, isFalse);

  eventPulling.start();
  expect(eventPulling.isStarted, isTrue);
  expect(eventPulling.isStopped, isFalse);

  AsyncEvent? waitEventResult;

  c1
      .waitNewEvent(Duration(seconds: 20))
      .then((event) => waitEventResult = event);

  var eventC1_2 = await c1.submit('t', {'name': 't4'});

  log.info("waitPulling 1> $eventPulling");
  expect(await eventPulling.waitPulling(), isTrue);

  expect(waitEventResult, isNotNull);

  expect(c1Events.map((e) => e.toJson()),
      [eventC1_1.toJson(), eventC1_2!.toJson()]);

  expect(await hub.epoch, equals(0));

  await _sleep(log, 2100);

  expect(await hub.epoch, equals(1));

  List<AsyncEvent>? fetchDelayedEvents;

  c1.fetchDelayed(eventC1_2.id, timeout: Duration(seconds: 20)).then((events) {
    return fetchDelayedEvents = events;
  });

  var eventC1_3 = await c1.submit('t', {'name': 't5'});

  log.info("waitPulling 2> $eventPulling");
  expect(await eventPulling.waitPulling(), isTrue);

  expect(fetchDelayedEvents, isNotEmpty);

  expect(c1Events.map((e) => e.toJson()),
      [eventC1_1.toJson(), eventC1_2.toJson(), eventC1_3!.toJson()]);

  expect(await storage.last('c1'), eventC1_3);

  expect((await c1.fetch(eventC1_2.id)).where((e) => e.type == 't'),
      equals([eventC1_2, eventC1_3]));

  expect((await c1.fetch(eventC1_2.id, limit: 3)).where((e) => e.type == 't'),
      equals([eventC1_2, eventC1_3]));

  expect((await c1.fetch(eventC1_2.id, limit: 2)).where((e) => e.type == 't'),
      equals([eventC1_3]));

  expect((await c1.fetch(eventC1_2.id, limit: 1)).where((e) => e.type == 't'),
      equals([eventC1_3]));

  expect(
      (await c1.fetch(AsyncEventID.any()))
          .map((e) => '${e.id}${e.payload}')
          .toList(),
      equals([
        '0#0{}',
        '0#1{name: t1}',
        '0#2{name: t4}',
        '1#0{previousID: 0#2}',
        '1#1{name: t5}'
      ]));

  expect(await c1.purge(untilID: eventC1_2.id), equals(2));

  expect(
      (await c1.fetch(AsyncEventID.any()))
          .map((e) => '${e.id}${e.payload}')
          .toList(),
      equals([
        '0#0{nextID: 0#2}',
        '0#2{name: t4}',
        '1#0{previousID: 0#2}',
        '1#1{name: t5}'
      ]));

  var submitAsync = c1.submit('t', {'name': 't6'});

  eventPulling.cancelChannelCalls();

  var eventC1_4 = await submitAsync;
  log.info("Submit canceled: $eventC1_4");

  expect(eventC1_4, submitAsync is Future ? isNull : isNotNull);

  eventPulling.stop();
  await _sleep(log, 300);

  expect(eventPulling.isStarted, isFalse);
  expect(eventPulling.isStopped, isTrue);

  expect(sub1.isSubscribed, isTrue);
  sub1.cancel();
  expect(sub1.isSubscribed, isFalse);

  expect(sub2.isSubscribed, isTrue);
  sub2.cancel();
  expect(sub2.isSubscribed, isFalse);

  expect(sub2b.isSubscribed, isTrue);
  sub2b.cancel();
  expect(sub1.isSubscribed, isFalse);

  expect(
      await storage.last('c1'),
      isA<AsyncEvent>()
          .having((evt) => evt.payload, 'payload', {'name': 't6'}));
  expect(await storage.last('c2'), eventC2_2);

  log.info("Hub: $hub");
  log.info("Storage: $storage");
  log.info('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
}

Future<dynamic> _sleep(logging.Logger log, int milliseconds) {
  log.info("Sleep: ${milliseconds}ms ...");
  return Future.delayed(Duration(milliseconds: milliseconds));
}

class _MyAsyncEventStorageClient extends AsyncEventStorageClient
    with AsyncEventStorageFromJSON {
  final _MyAsyncEventStorageServer server;

  @override
  AsyncEventStorageAsJSON get storageAsJSON => server;

  _MyAsyncEventStorageClient(this.server);

  @override
  String toString() {
    return '_MyAsyncEventStorageClient@$server';
  }
}

class _MyAsyncEventStorageServer with AsyncEventStorageAsJSON {
  @override
  final AsyncEventStorage storage;

  _MyAsyncEventStorageServer(this.storage);

  @override
  Future<int> get epoch => super.epoch.asFutureDelayed;

  @override
  Future<Map<String, dynamic>?> newEvent(
          String channelName, String type, Map<String, dynamic> payload,
          {DateTime? time}) =>
      super.newEvent(channelName, type, payload, time: time).asFutureDelayed;

  final Map<String, int> _fetchRequestCounter = <String, int>{};

  @override
  Future<List<Map<String, dynamic>>> fetch(
      String channelName, AsyncEventID fromID,
      {int? limit}) {
    var key = '$channelName>$fromID';
    var count =
        _fetchRequestCounter.update(key, (c) => c + 1, ifAbsent: () => 1);

    if (count == 2) {
      log.severe("Forcing error: $key = $count");
      throw StateError("Forcing error");
    }

    return super.fetch(channelName, fromID, limit: limit).asFutureDelayed;
  }

  @override
  Future<Map<String, dynamic>?> lastID(String channelName) =>
      super.lastID(channelName).asFutureDelayed;

  @override
  Future<Map<String, dynamic>?> last(String channelName) =>
      super.last(channelName).asFutureDelayed;

  @override
  Future<int> purgeEpochs(int untilEpoch) =>
      super.purgeEpochs(untilEpoch).asFutureDelayed;

  @override
  Future<int> purgeEvents(String channelName,
          {AsyncEventID? untilID, DateTime? before, bool all = false}) =>
      super
          .purgeEvents(channelName, untilID: untilID, before: before, all: all)
          .asFutureDelayed;

  @override
  String toString() {
    return '_MyAsyncEventStorageServer@$storage';
  }
}

extension _FutureOrExtension<T> on FutureOr<T> {
  Future<T> get asFutureDelayed {
    var self = this;
    if (self is Future<T>) {
      return self;
    } else {
      return Future.delayed(Duration(milliseconds: 10), () => self);
    }
  }
}
