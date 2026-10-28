import 'package:async_events/async_events.dart';
import 'package:async_extension/async_extension.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncEventID', () {
    test('constructors, previous / next', () {
      expect(AsyncEventID.zero(), equals(AsyncEventID(0, 0)));
      expect(AsyncEventID.any(), equals(AsyncEventID(0, -1)));

      var id = AsyncEventID(2, 5);
      expect(id.previous, equals(AsyncEventID(2, 4)));
      expect(id.next, equals(AsyncEventID(2, 6)));
      expect(AsyncEventID(2, 0).previous, isNull);

      expect(id.toString(), equals('2#5'));
      expect(id.hashCode, equals(AsyncEventID(2, 5).hashCode));
    });

    test('compare', () {
      var a = AsyncEventID(1, 9);
      var b = AsyncEventID(2, 0);
      var c = AsyncEventID(2, 1);

      expect(a.compareTo(b), lessThan(0));
      expect(c.compareTo(b), greaterThan(0));
      expect(b.compareTo(AsyncEventID(2, 0)), equals(0));

      expect(a < b, isTrue);
      expect(b <= b, isTrue);
      expect(c > b, isTrue);
      expect(c >= c, isTrue);
      expect([c, a, b]..sort(), equals([a, b, c]));
    });

    test('from / parse / JSON', () {
      var id = AsyncEventID(3, 4);

      expect(AsyncEventID.from(id), same(id));
      expect(AsyncEventID.from('3#4'), equals(id));
      expect(AsyncEventID.from({'epoch': 3, 'serial': 4}), equals(id));

      expect(AsyncEventID.fromJson(id.toJson()), equals(id));
      expect(AsyncEventID.fromJson({'id': '3#4'}), equals(id));
      expect(() => AsyncEventID.fromJson({'epoch': '3'}), throwsArgumentError);

      expect(AsyncEventID.parse(' 3#4 '), equals(id));
      expect(() => AsyncEventID.parse('#4'), throwsFormatException);
      expect(() => AsyncEventID.parse('3-4'), throwsFormatException);
      expect(() => AsyncEventID.parse('a#4'), throwsFormatException);

      expect(AsyncEventID.tryParse('3#4'), equals(id));
      expect(AsyncEventID.tryParse(null), isNull);
      expect(AsyncEventID.tryParse(' '), isNull);
      expect(AsyncEventID.tryParse('#4'), isNull);
      expect(AsyncEventID.tryParse('3#x'), isNull);
    });
  });

  group('AsyncEventPullingConfig', () {
    test('defaults, limits and JSON', () {
      var config = AsyncEventPullingConfig();
      expect(config.period, equals(Duration(seconds: 10)));
      expect(config.minInterval, equals(Duration(seconds: 1)));

      // `minInterval` at most the `period`:
      var config2 = AsyncEventPullingConfig(
        period: Duration(milliseconds: 100),
        minInterval: Duration(seconds: 1),
      );
      expect(config2.minInterval, equals(Duration(milliseconds: 100)));

      expect(
        () => AsyncEventPullingConfig(period: Duration(milliseconds: 5)),
        throwsArgumentError,
      );

      expect(AsyncEventPullingConfig.fromJson(config.toJson()), equals(config));
      expect(config.hashCode, equals(AsyncEventPullingConfig().hashCode));
      expect(config, isNot(equals(config2)));
      expect(config.toString(), contains('period'));
    });
  });

  test('AsyncEvent', () {
    var time = DateTime.utc(2026, 1, 2, 3, 4, 5);
    var e1 = AsyncEvent('c', AsyncEventID(0, 1), time, 't', {'a': 1});
    var e2 = AsyncEvent('c', '0#2', time, 't', {'a': 2});

    expect(e2.id, equals(AsyncEventID(0, 2)));
    expect(e1.compareTo(e2), lessThan(0));
    expect(e1.toJson(withChannelName: false).containsKey('channel'), isFalse);
    expect(e1.toString(), contains('0#1'));
  });

  group('remote storage (integration)', () {
    late AsyncEventStorageMemory serverStorage;
    late _Server server;
    late AsyncEventHub serverHub;
    late AsyncEventHub clientHub;

    setUp(() {
      serverStorage = AsyncEventStorageMemory('server');
      server = _Server(serverStorage);
      // The server side: submits the events.
      serverHub = AsyncEventHub('server', serverStorage);
      // The client side: gets them through the remote storage.
      clientHub = AsyncEventHub(
        'client',
        AsyncEventStorageRemote(
          'client',
          _Client(server),
          retryInterval: Duration(milliseconds: 50),
        ),
      );
    });

    const period = Duration(milliseconds: 200);

    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 100 && !condition(); ++i) {
        await Future.delayed(Duration(milliseconds: 20));
      }
      expect(condition(), isTrue);
    }

    test('events submitted on the server are pulled by the client', () async {
      var received = <String>[];

      var channel = clientHub.channel('c1');
      await channel.subscribe((e) => received.add('${e.payload['n']}'));

      var pulling = channel.pulling(period: period);

      await serverHub.channel('c1').submit('t', {'n': 1});
      await serverHub.channel('c1').submit('t', {'n': 2});

      await waitFor(() => received.length == 2);
      expect(received, equals(['1', '2']));

      pulling.stop();
    });

    test('pulling restarted right after a stop keeps receiving', () async {
      var received = <String>[];

      var channel = clientHub.channel('c2');
      await channel.subscribe((e) => received.add('${e.payload['n']}'));

      var pulling = channel.pulling(period: period);

      await serverHub.channel('c2').submit('t', {'n': 1});
      await waitFor(() => received.length == 1);

      // A logout and a login (the same shared pulling):
      pulling.stop(cancelChannelCalls: true);
      expect(channel.pulling(period: period), same(pulling));

      await serverHub.channel('c2').submit('t', {'n': 2});
      await serverHub.channel('c2').submit('t', {'n': 3});

      await waitFor(() => received.length == 3);
      expect(received, equals(['1', '2', '3']));

      pulling.stop();
    });

    test('a retried lastID / last of an empty channel: null', () async {
      server.failNextCalls = 1;

      var storage = clientHub.storage;
      expect(await storage.lastID('empty'), isNull);
      expect(server.failedCalls, equals(1));

      server.failNextCalls = 1;
      expect(await storage.last('empty'), isNull);
      expect(server.failedCalls, equals(2));
    });

    test('waitNewEvent / fetchDelayed', () async {
      var channel = clientHub.channel('c3');

      // No event: the timeout.
      expect(await channel.waitNewEvent(Duration(milliseconds: 50)), isNull);
      expect(
        await channel.fetchDelayed(
          AsyncEventID.zero(),
          timeout: Duration(milliseconds: 50),
        ),
        isEmpty,
      );

      var submitted = await clientHub.channel('c3').submit('t', {'n': 1});
      expect(submitted, isNotNull);

      var events = await channel.fetchDelayed(AsyncEventID.zero());
      expect(events.where((e) => e.type == 't'), hasLength(1));

      expect(await clientHub.storage.lastID('c3'), equals(submitted!.id));
    });

    test('subscriptions: fromBegin, fromEpochBegin, cancel', () async {
      var serverChannel = serverHub.channel('c4');
      await serverChannel.submit('t', {'n': 1});
      await serverChannel.submit('t', {'n': 2});

      var channel = clientHub.channel('c4');

      var fromBegin = <AsyncEvent>[];
      var sub1 = await channel.subscribe(fromBegin.add, fromBegin: true);
      await sub1.pull();
      expect(fromBegin.where((e) => e.type == 't'), hasLength(2));

      var fromEpoch = <AsyncEvent>[];
      var sub2 = await channel.subscribe(fromEpoch.add, fromEpochBegin: true);
      await sub2.pull();
      expect(fromEpoch.where((e) => e.type == 't'), hasLength(2));

      expect(sub1.isSubscribed, isTrue);
      sub1.cancel();
      expect(sub1.isSubscribed, isFalse);
      sub2.cancel();
    });

    test('purge', () async {
      var channel = clientHub.channel('c5');
      for (var n = 1; n <= 3; ++n) {
        await channel.submit('t', {'n': n});
      }

      expect(await channel.purge(all: true), greaterThan(0));
      expect(
        (await channel.fetch(AsyncEventID.any())).where((e) => e.type == 't'),
        isEmpty,
      );

      expect(await clientHub.storage.purgeEpochs(0), greaterThanOrEqualTo(0));
    });
  });
}

/// The server side of [AsyncEventStorageRemote]: fails the next
/// [failNextCalls] `lastID` / `last` calls.
class _Server with AsyncEventStorageAsJSON {
  @override
  final AsyncEventStorage storage;

  _Server(this.storage);

  int failNextCalls = 0;
  int failedCalls = 0;

  void _checkFail() {
    if (failNextCalls > 0) {
      --failNextCalls;
      ++failedCalls;
      throw StateError('Forced error');
    }
  }

  @override
  FutureOr<Map<String, dynamic>?> lastID(String channelName) {
    _checkFail();
    return super.lastID(channelName).asFuture;
  }

  @override
  FutureOr<Map<String, dynamic>?> last(String channelName) {
    _checkFail();
    return super.last(channelName).asFuture;
  }
}

class _Client extends AsyncEventStorageClient with AsyncEventStorageFromJSON {
  final _Server server;

  @override
  AsyncEventStorageAsJSON get storageAsJSON => server;

  _Client(this.server);
}
