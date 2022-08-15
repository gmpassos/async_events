import 'dart:async';

import 'package:async_events/async_events.dart';
import 'package:logging/logging.dart' as logging;
import 'package:test/test.dart';

void main() {
  logging.Logger.root.level = logging.Level.ALL;
  logging.Logger.root.onRecord
      .listen((event) => print('${DateTime.now()}\t$event'));

  final log = logging.Logger('test');

  group('AsyncEvent', () {
    test('basic', () async {
      var storage = AsyncEventStorageMemory('test');
      var hub = AsyncEventHub('test', storage);

      await _doTestBasic(hub, log, storage);
    });

    test('remote', () async {
      var server = _MyAsyncEventStorageServer('test');
      var client = _MyAsyncEventStorageClient(server);

      var storage = AsyncEventStorageRemote('test', client);
      var hub = AsyncEventHub('test', storage);

      await _doTestBasic(hub, log, storage);
    });
  });
}

Future<void> _doTestBasic(
    AsyncEventHub hub, logging.Logger log, AsyncEventStorage storage) async {
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

  var event1 = await c1.submit('t', {'name': 't1'});
  var event2 = await c2.submit('t', {'name': 't2'});

  await sub1.pull();
  await sub2.pull();

  expect(c1Events.map((e) => e.toJson()), [event1!.toJson()]);
  expect(c2Events.map((e) => e.toJson()), [event2!.toJson()]);

  var c2bEvents = <AsyncEvent>[];

  var sub2bAsync = c2.subscribe(fromBegin: true, (e) {
    c2bEvents.add(e);
    log.info('C2/b>> $e');
  });

  var event3 = await c2.submit('t', {'name': 't3'});

  var sub2b = await sub2bAsync;

  await sub2b.pull();

  expect(c2bEvents.map((e) => e.toJson()), [event2.toJson(), event3!.toJson()]);

  expect(c2Events.map((e) => e.toJson()), [event2.toJson(), event3.toJson()]);

  expect(sub1.isSubscribed, isTrue);
  sub1.cancel();
  expect(sub1.isSubscribed, isFalse);

  expect(sub2.isSubscribed, isTrue);
  sub2.cancel();
  expect(sub2.isSubscribed, isFalse);

  expect(sub2b.isSubscribed, isTrue);
  sub2b.cancel();
  expect(sub1.isSubscribed, isFalse);

  expect(await storage.last('c1'), event1);
  expect(await storage.last('c2'), event3);
}

class _MyAsyncEventStorageClient extends AsyncEventStorageClient
    with AsyncEventStorageFromJSON {
  final _MyAsyncEventStorageServer server;

  @override
  AsyncEventStorageAsJSON get storageAsJSON => server;

  _MyAsyncEventStorageClient(this.server);
}

class _MyAsyncEventStorageServer with AsyncEventStorageAsJSON {
  @override
  final AsyncEventStorage storage;

  _MyAsyncEventStorageServer(String name)
      : storage = AsyncEventStorageMemory(name);

  @override
  Future<int> get epoch => super.epoch.asFuture;

  @override
  Future<Map<String, dynamic>?> newEvent(
          String channelName, String type, Map<String, dynamic> payload) =>
      super.newEvent(channelName, type, payload).asFuture;

  @override
  Future<List<Map<String, dynamic>>> fetch(
          String channelName, AsyncEventID fromID) =>
      super.fetch(channelName, fromID).asFuture;

  @override
  Future<Map<String, dynamic>?> lastID(String channelName) =>
      super.lastID(channelName).asFuture;

  @override
  Future<Map<String, dynamic>?> last(String channelName) =>
      super.last(channelName).asFuture;

  @override
  Future<int> purge(int untilEpoch) => super.purge(untilEpoch).asFuture;
}

extension _FutureOrExtension<T> on FutureOr<T> {
  Future<T> get asFuture {
    var self = this;
    if (self is Future<T>) {
      return self;
    } else {
      return Future.delayed(Duration(milliseconds: 10), () => self);
    }
  }
}
