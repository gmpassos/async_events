import 'dart:math' as math;

import 'package:async_extension/async_extension.dart';
import 'package:logging/logging.dart' as logging;

import 'async_call.dart';
import 'async_events_base.dart';

final _log = logging.Logger('AsyncEventStorage');

abstract class AsyncEventStorage {
  final String name;

  final Duration epochPeriod;

  AsyncEventStorage(this.name, {this.epochPeriod = const Duration(days: 1)}) {
    if (epochPeriod.inSeconds < 1) {
      throw ArgumentError("epochPeriod < 1s: $epochPeriod");
    }
  }

  DateTime get currentTime => DateTime.now().toUtc();

  FutureOr<int> get epoch;

  final Map<String, AsyncEventID> _channelsMaxIDs = <String, AsyncEventID>{};

  /// Returns: nextID -> prevID?
  FutureOr<MapEntry<AsyncEventID, AsyncEventID?>> _nextEventID(
      String channelName) {
    return lastID(channelName)
        .resolveOther<MapEntry<AsyncEventID, AsyncEventID?>, int>(epoch,
            (lastEventID, epoch) {
      int serial;
      if (lastEventID == null) {
        serial = 1;
      } else if (lastEventID.epoch == epoch) {
        serial = lastEventID.serial + 1;
      } else if (lastEventID.epoch < epoch) {
        serial = 1;
      } else {
        throw StateError(
            "Epoch out of sync> epoch: $epoch ; lastEventID: $lastEventID");
      }

      var eventID = AsyncEventID(epoch, serial);
      var maxID = _channelsMaxIDs[channelName];

      var cmp = maxID == null ? -1 : maxID.compareTo(eventID);

      if (cmp < 0) {
        _channelsMaxIDs[channelName] = eventID;
        return MapEntry(eventID, lastEventID);
      }

      AsyncEventID eventID2;

      if (maxID!.epoch > epoch) {
        eventID2 = AsyncEventID(maxID.epoch, maxID.serial + 1);
      } else if (maxID.epoch == epoch) {
        eventID2 =
            AsyncEventID(maxID.epoch, math.max(maxID.serial + 1, serial));
      } else {
        eventID2 = AsyncEventID(epoch, math.max(1, serial));
      }

      _channelsMaxIDs[channelName] = eventID2;
      return MapEntry(eventID2, lastEventID);
    });
  }

  FutureOr<AsyncEvent> _nextEvent(
      String channelName, String type, Map<String, dynamic> payload,
      {DateTime? time}) {
    return _nextEventID(channelName).resolveMapped((nextID) {
      var id = nextID.key;
      var prevID = nextID.value;

      var timeResolved = _resolveNewEventTime(channelName, time);

      var event = AsyncEvent(channelName, id, timeResolved, type, payload);

      if (id.serial == 1) {
        return _newEpochEvent(channelName, id.epoch, prevID, timeResolved)
            .resolveWith(() => event);
      } else {
        return event;
      }
    });
  }

  final Map<String, DateTime> _channelsMaxTime = <String, DateTime>{};

  DateTime _resolveNewEventTime(String channelName, DateTime? time) {
    if (time == null) {
      time = currentTime;
      _channelsMaxTime[channelName] = time;
      return time;
    }

    var maxTime = _channelsMaxTime[channelName];

    if (maxTime != null && time.compareTo(maxTime) < 0) {
      time = maxTime;
    } else {
      _channelsMaxTime[channelName] = time;
    }

    return time;
  }

  FutureOr<AsyncEvent?> newEvent(
      String channelName, String type, Map<String, dynamic> payload,
      {DateTime? time}) {
    return _nextEvent(channelName, type, payload, time: time)
        .resolveMapped((event) {
      return store(channelName, event).resolveMapped((ok) {
        if (!ok) {
          _log.warning("Error storing event: $event");
          return null;
        }
        _notifyNewEvent(channelName, event);
        return event;
      });
    });
  }

  FutureOr<AsyncEvent?> _newEpochEvent(
      String channelName, int epoch, AsyncEventID? previousID, DateTime? time) {
    var id = AsyncEventID(epoch, 0);

    var timeResolved = _resolveNewEventTime(channelName, time);

    var event = AsyncEvent(
        channelName, id, timeResolved, 'new_epoch', <String, dynamic>{
      if (previousID != null) 'previousID': previousID.toString()
    });

    return store(channelName, event).resolveMapped((ok) {
      if (!ok) {
        _log.warning("Error storing new epoch event: $event");
        return null;
      }
      _notifyNewEvent(channelName, event);
      return event;
    });
  }

  final Map<String, List<AsyncEventListener>> _eventListeners =
      <String, List<AsyncEventListener>>{};

  void listenEvents(String channelName, AsyncEventListener listener) {
    var list =
        _eventListeners.putIfAbsent(channelName, () => <AsyncEventListener>[]);
    list.add(listener);
  }

  void _notifyNewEvent(String channelName, AsyncEvent event) {
    var list = _eventListeners[channelName];
    if (list == null) return;

    for (var e in list) {
      try {
        e(event);
      } catch (e, s) {
        _log.severe("Error notifying event: $event", e, s);
      }
    }
  }

  void _notifyNewEvents(String channelName, Iterable<AsyncEvent> events) {
    var list = _eventListeners[channelName];
    if (list == null) return;

    for (var event in events) {
      for (var e in list) {
        try {
          e(event);
        } catch (e, s) {
          _log.severe("Error notifying event: $event", e, s);
        }
      }
    }
  }

  FutureOr<bool> store(String channelName, AsyncEvent event);

  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID,
      {int? limit});

  FutureOr<AsyncEvent?> last(String channelName);

  FutureOr<AsyncEventID?> lastID(String channelName) =>
      last(channelName).resolveMapped((event) => event?.id);

  FutureOr<int> purgeEpochs(int untilEpoch);

  FutureOr<int> purgeEvents(String channelName,
      {AsyncEventID? untilID, DateTime? before, bool all = false});

  FutureOr<int> pull(String channelName, AsyncEventID? fromID);

  void cancelChannelCalls(String channelName);
}

/// Wraps [AsyncEventStorage]'s calls returning JSON values.
/// Useful to implement a [storage] server.
mixin AsyncEventStorageAsJSON {
  /// The [AsyncEventStorage] to wrap.
  AsyncEventStorage get storage;

  /// Alias to [storage.epoch].
  FutureOr<int> get epoch => storage.epoch;

  /// Alias to [storage.newEvent].
  FutureOr<Map<String, dynamic>?> newEvent(
          String channelName, String type, Map<String, dynamic> payload,
          {DateTime? time}) =>
      storage
          .newEvent(channelName, type, payload, time: time)
          .resolveMapped((event) => event?.toJson());

  /// Alias to [storage.fetch].
  FutureOr<List<Map<String, dynamic>>> fetch(
      String channelName, AsyncEventID fromID,
      {int? limit}) {
    return storage
        .fetch(channelName, fromID, limit: limit)
        .resolveMapped((l) => l.map((e) => e.toJson()).toList());
  }

  /// Alias to [storage.lastID].
  FutureOr<Map<String, dynamic>?> lastID(String channelName) =>
      storage.lastID(channelName).resolveMapped((id) => id?.toJson());

  /// Alias to [storage.last].
  FutureOr<Map<String, dynamic>?> last(String channelName) =>
      storage.last(channelName).resolveMapped((event) => event?.toJson());

  /// Alias to [storage.purgeEpochs].
  FutureOr<int> purgeEpochs(int untilEpoch) => storage.purgeEpochs(untilEpoch);

  /// Alias to [storage.purgeEvents].
  FutureOr<int> purgeEvents(String channelName,
          {AsyncEventID? untilID, DateTime? before, bool all = false}) =>
      storage.purgeEvents(channelName,
          untilID: untilID, before: before, all: all);
}

/// Wraps an [AsyncEventStorageAsJSON] instance converting JSON results int objects.
/// Useful to implement a [storage] client.
mixin AsyncEventStorageFromJSON {
  AsyncEventStorageAsJSON get storageAsJSON;

  /// Calls [storageAsJSON.epoch].
  FutureOr<int> get epoch => storageAsJSON.epoch;

  /// Calls [storageAsJSON.newEvent].
  FutureOr<AsyncEvent?> newEvent(
          String channelName, String type, Map<String, dynamic> payload,
          {DateTime? time}) =>
      storageAsJSON
          .newEvent(channelName, type, payload, time: time)
          .resolveMapped(
              (json) => json == null ? null : AsyncEvent.fromJson(json));

  /// Calls [storageAsJSON.fetch].
  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID,
          {int? limit}) =>
      storageAsJSON.fetch(channelName, fromID, limit: limit).resolveMapped(
          (l) => l.map((json) => AsyncEvent.fromJson(json)).toList());

  /// Calls [storageAsJSON.lastID].
  FutureOr<AsyncEventID?> lastID(String channelName) =>
      storageAsJSON.lastID(channelName).resolveMapped(
          (json) => json == null ? null : AsyncEventID.fromJson(json));

  /// Calls [storageAsJSON.last].
  FutureOr<AsyncEvent?> last(String channelName) => storageAsJSON
      .last(channelName)
      .resolveMapped((json) => json == null ? null : AsyncEvent.fromJson(json));

  /// Calls [storageAsJSON.purgeEpochs].
  FutureOr<int> purgeEpochs(int untilEpoch) =>
      storageAsJSON.purgeEpochs(untilEpoch);

  /// Calls [storageAsJSON.purgeEvents].
  FutureOr<int> purgeEvents(String channelName,
          {AsyncEventID? untilID, DateTime? before, bool all = false}) =>
      storageAsJSON.purgeEvents(channelName,
          untilID: untilID, before: before, all: all);
}

final _logMemory = logging.Logger('AsyncEventStorageMemory');

/// An in-memory [AsyncEventStorage].
class AsyncEventStorageMemory extends AsyncEventStorage {
  AsyncEventStorageMemory(super.name, {super.epochPeriod});

  final Map<String, List<AsyncEvent>> _channelsEvents =
      <String, List<AsyncEvent>>{};

  final DateTime initTime = DateTime.now();

  @override
  int get epoch {
    var elapsedTime = DateTime.now().difference(initTime);
    var epoch = elapsedTime.inSeconds ~/ epochPeriod.inSeconds;
    return epoch;
  }

  @override
  bool store(String channelName, AsyncEvent event) {
    var list = _channelsEvents.putIfAbsent(channelName, () => <AsyncEvent>[]);

    var stored = list.insertSorted(event);

    if (stored) {
      _logMemory.info("CHANNEL[$channelName] Stored event> $event");
      return true;
    } else {
      return false;
    }
  }

  @override
  List<AsyncEvent> fetch(String channelName, AsyncEventID fromID,
      {int? limit}) {
    var list = _channelsEvents[channelName];
    if (list == null || list.isEmpty) return <AsyncEvent>[];

    var sel = list.where((e) => e.id >= fromID).toList();

    if (limit != null && limit > 0 && sel.length > limit) {
      sel = sel.sublist(sel.length - limit);

      var nextEvent = sel.first;

      var limitEvent = AsyncEvent(
        channelName,
        AsyncEventID.any(),
        DateTime.now(),
        'limit',
        {'nextID': nextEvent.id.toString()},
      );

      sel.insert(0, limitEvent);
    }

    _logMemory.info(
        "CHANNEL[$channelName] Fetch events> fromID: $fromID ; limit: $limit >> events: ${sel.length}");

    return sel;
  }

  @override
  AsyncEvent? last(String channelName) {
    var list = _channelsEvents[channelName];
    if (list == null || list.isEmpty) return null;

    var last = list.last;

    _logMemory.info("CHANNEL[$channelName] Last event> $last");

    return last;
  }

  @override
  int purgeEpochs(int untilEpoch) =>
      _purgeImpl((e) => e.id.epoch <= untilEpoch);

  @override
  FutureOr<int> purgeEvents(String channelName,
      {AsyncEventID? untilID, DateTime? before, bool all = false}) {
    if (all) {
      return lastID(channelName).resolveMapped((lastID) {
        if (lastID == null || lastID.serial == 0) return 0;

        return _newEpochEvent(channelName, lastID.epoch + 1, lastID, null)
            .resolveMapped((epochEvent) {
          if (epochEvent == null) return 0;
          return purgeEpochs(epochEvent.id.epoch - 1);
        });
      });
    }

    if (untilID != null) {
      if (untilID.serial == 0) {
        final previousEpoch = untilID.epoch - 1;

        return _purgeImpl(
          channelName: channelName,
          (e) => e.id.epoch <= previousEpoch,
          insertPurgeEvent: true,
          desc: ' < `$untilID`',
        );
      }

      return _purgeImpl(
        channelName: channelName,
        (e) => e.id.compareTo(untilID) < 0,
        insertPurgeEvent: true,
        desc: ' < `$untilID`',
      );
    } else if (before != null) {
      return _purgeImpl(
        channelName: channelName,
        (e) => e.time.compareTo(before) < 0,
        insertPurgeEvent: true,
        desc: ' < `$before`',
      );
    } else {
      return 0;
    }
  }

  int _purgeImpl(bool Function(AsyncEvent event) remove,
      {String? channelName, String desc = '', bool insertPurgeEvent = false}) {
    var totalDel = 0;

    if (channelName != null) {
      var l = _channelsEvents[channelName];
      if (l != null) {
        var del = _purgeChannelImpl(
          channelName,
          l,
          remove,
          desc,
          insertPurgeEvent,
        );

        totalDel += del;
      }
    } else {
      for (var e in _channelsEvents.entries) {
        var c = e.key;
        var l = e.value;

        var del = _purgeChannelImpl(
          c,
          l,
          remove,
          desc,
          insertPurgeEvent,
        );

        totalDel += del;
      }
    }

    _logMemory.info("Purge> total removed events$desc: $totalDel");

    return totalDel;
  }

  int _purgeChannelImpl(
      String channelName,
      List<AsyncEvent> channelEvents,
      bool Function(AsyncEvent event) remove,
      String desc,
      bool insertPurgeEvent) {
    var lastEvent = channelEvents.isNotEmpty ? channelEvents.last : null;

    var sz = channelEvents.length;

    channelEvents.removeWhere(remove);

    // Can't fully clean the channel to avoid serial sequence issues:
    if (channelEvents.isEmpty && lastEvent != null) {
      channelEvents.add(lastEvent);
    }

    var del = sz - channelEvents.length;

    _logMemory.info("CHANNEL[$channelName] Purge> removed events$desc: $del");

    if (insertPurgeEvent && del > 0 && channelEvents.isNotEmpty) {
      var nextEvent = channelEvents.first;
      var nextEventID = nextEvent.id;

      var purgeEvent = AsyncEvent(
        nextEvent.channelName,
        AsyncEventID(nextEventID.epoch, 0),
        nextEvent.time,
        'purge',
        {'nextID': nextEventID.toString()},
      );

      channelEvents.insert(0, purgeEvent);
    }

    return del;
  }

  @override
  int pull(String channelName, AsyncEventID? fromID) {
    fromID ??= AsyncEventID.zero();

    var events = fetch(channelName, fromID);

    _notifyNewEvents(channelName, events);
    return events.length;
  }

  @override
  void cancelChannelCalls(String channelName) {}

  @override
  String toString() {
    return 'AsyncEventStorageMemory{initTime: $initTime, channelsEvents: ${_channelsEvents.map((key, value) => MapEntry(key, value.length))}';
  }
}

/// A remote [AsyncEventStorage].
class AsyncEventStorageRemote extends AsyncEventStorage with AsyncCaller {
  /// The client that access the real storage.
  final AsyncEventStorageClient client;

  @override
  final Duration retryInterval;

  AsyncEventStorageRemote(super.name, this.client,
      {this.retryInterval = const Duration(seconds: 1)});

  @override
  FutureOr<int> get epoch =>
      call(() => client.epoch, methodName: 'epoch', maxRetries: 5);

  @override
  FutureOr<AsyncEvent?> newEvent(
          String channelName, String type, Map<String, dynamic> payload,
          {DateTime? time}) =>
      call(() => client.newEvent(channelName, type, payload, time: time),
          methodName: '$channelName/newEvent', nullErrorValue: true);

  @override
  @Deprecated(
      "Should not be called in a remote storage instance. Use `newEvent`")
  FutureOr<bool> store(String channelName, AsyncEvent event) {
    throw UnsupportedError("Not supported for remote storage. Use `newEvent`");
  }

  @override
  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID,
          {int? limit}) =>
      call(() => client.fetch(channelName, fromID, limit: limit),
          methodName: '$channelName/fetch',
          maxRetries: 5,
          errorValue: <AsyncEvent>[]);

  @override
  FutureOr<AsyncEventID?> lastID(String channelName) =>
      call(() => client.lastID(channelName),
          methodName: '$channelName/lastID', maxRetries: 5);

  @override
  FutureOr<AsyncEvent?> last(String channelName) =>
      call(() => client.last(channelName),
          methodName: '$channelName/last', maxRetries: 5);

  @override
  FutureOr<int> purgeEpochs(int untilEpoch) =>
      call(() => client.purgeEpochs(untilEpoch),
          methodName: 'purgeEpochs', maxRetries: 5);

  @override
  FutureOr<int> purgeEvents(String channelName,
          {AsyncEventID? untilID, DateTime? before, bool all = false}) =>
      call(
          () => client.purgeEvents(channelName,
              untilID: untilID, before: before, all: all),
          methodName: '$channelName/purgeEvents',
          maxRetries: 5);

  @override
  FutureOr<int> pull(String channelName, AsyncEventID? fromID) {
    fromID ??= AsyncEventID.zero();

    return fetch(channelName, fromID).resolveMapped((events) {
      _notifyNewEvents(channelName, events);
      return events.length;
    });
  }

  Iterable<AsyncCall> channelCalls(String channelName) {
    var prefix = '$channelName/';
    return calls.where((call) => call.methodName.startsWith(prefix));
  }

  @override
  void cancelChannelCalls(String channelName) {
    var calls = channelCalls(channelName).toList();

    for (var call in calls) {
      call.cancel();
    }
  }

  @override
  String toString() {
    return 'AsyncEventStorageRemote{client: $client}';
  }
}

/// Interface for an [AsyncEventStorageRemote] client.
abstract class AsyncEventStorageClient {
  /// Calls [AsyncEventStorage.epoch].
  FutureOr<int> get epoch;

  /// Calls [AsyncEventStorage.newEvent].
  FutureOr<AsyncEvent?> newEvent(
      String channelName, String type, Map<String, dynamic> payload,
      {DateTime? time});

  /// Calls [AsyncEventStorage.fetch].
  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID,
      {int? limit});

  /// Calls [AsyncEventStorage.lastID].
  FutureOr<AsyncEventID?> lastID(String channelName);

  /// Calls [AsyncEventStorage.last].
  FutureOr<AsyncEvent?> last(String channelName);

  /// Calls [AsyncEventStorage.purge].
  FutureOr<int> purgeEpochs(int untilEpoch);

  /// Calls [AsyncEventStorage.purge].
  FutureOr<int> purgeEvents(String channelName,
      {AsyncEventID? untilID, DateTime? before, bool all = false});
}
