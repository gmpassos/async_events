import 'dart:math' as math;

import 'package:async_events/async_events.dart';
import 'package:async_extension/async_extension.dart';
import 'package:logging/logging.dart' as logging;

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

  FutureOr<AsyncEventID> _nextEventID(String channelName) {
    return lastID(channelName).resolveOther<AsyncEventID, int>(epoch,
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
        return eventID;
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
      return eventID2;
    });
  }

  FutureOr<AsyncEvent> _nextEvent(
      String channelName, String type, Map<String, dynamic> payload) {
    return _nextEventID(channelName).resolveMapped((id) {
      return AsyncEvent(id, currentTime, type, payload);
    });
  }

  FutureOr<AsyncEvent?> newEvent(
      String channelName, String type, Map<String, dynamic> payload) {
    return _nextEvent(channelName, type, payload).resolveMapped((event) {
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

  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID);

  FutureOr<AsyncEvent?> last(String channelName);

  FutureOr<AsyncEventID?> lastID(String channelName) =>
      last(channelName).resolveMapped((event) => event?.id);

  FutureOr<int> purge(int untilEpoch);

  FutureOr<bool> pull(String channelName, AsyncEventID? fromID);
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
          String channelName, String type, Map<String, dynamic> payload) =>
      storage
          .newEvent(channelName, type, payload)
          .resolveMapped((event) => event?.toJson());

  /// Alias to [storage.fetch].
  FutureOr<List<Map<String, dynamic>>> fetch(
      String channelName, AsyncEventID fromID) {
    return storage
        .fetch(channelName, fromID)
        .resolveMapped((l) => l.map((e) => e.toJson()).toList());
  }

  /// Alias to [storage.lastID].
  FutureOr<Map<String, dynamic>?> lastID(String channelName) =>
      storage.lastID(channelName).resolveMapped((id) => id?.toJson());

  /// Alias to [storage.last].
  FutureOr<Map<String, dynamic>?> last(String channelName) =>
      storage.last(channelName).resolveMapped((event) => event?.toJson());

  /// Alias to [storage.purge].
  FutureOr<int> purge(int untilEpoch) => storage.purge(untilEpoch);
}

/// Wraps an [AsyncEventStorageAsJSON] instance converting JSON results int objects.
/// Useful to implement a [storage] client.
mixin AsyncEventStorageFromJSON {
  AsyncEventStorageAsJSON get storageAsJSON;

  /// Calls [storageAsJSON.epoch].
  FutureOr<int> get epoch => storageAsJSON.epoch;

  /// Calls [storageAsJSON.newEvent].
  FutureOr<AsyncEvent?> newEvent(
          String channelName, String type, Map<String, dynamic> payload) =>
      storageAsJSON.newEvent(channelName, type, payload).resolveMapped(
          (json) => json == null ? null : AsyncEvent.fromJson(json));

  /// Calls [storageAsJSON.fetch].
  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID) =>
      storageAsJSON.fetch(channelName, fromID).resolveMapped(
          (l) => l.map((json) => AsyncEvent.fromJson(json)).toList());

  /// Calls [storageAsJSON.lastID].
  FutureOr<AsyncEventID?> lastID(String channelName) =>
      storageAsJSON.lastID(channelName).resolveMapped(
          (json) => json == null ? null : AsyncEventID.fromJson(json));

  /// Calls [storageAsJSON.last].
  FutureOr<AsyncEvent?> last(String channelName) => storageAsJSON
      .last(channelName)
      .resolveMapped((json) => json == null ? null : AsyncEvent.fromJson(json));

  /// Calls [storageAsJSON.purge].
  FutureOr<int> purge(int untilEpoch) => storageAsJSON.purge(untilEpoch);
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
    list.add(event);

    _logMemory.info("CHANNEL[$channelName] Stored event> $event");

    return true;
  }

  @override
  List<AsyncEvent> fetch(String channelName, AsyncEventID fromID) {
    var list = _channelsEvents[channelName];
    if (list == null || list.isEmpty) return <AsyncEvent>[];

    var sel = list.where((e) => e.id >= fromID).toList();

    _logMemory.info(
        "CHANNEL[$channelName] Fetch events> fromID: $fromID >> events: ${sel.length}");

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
  int purge(int untilEpoch) {
    var totalDel = 0;

    for (var e in _channelsEvents.entries) {
      var c = e.key;
      var l = e.value;
      var sz = l.length;
      l.removeWhere((e) => e.id.epoch <= untilEpoch);
      var del = l.length - sz;
      totalDel += del;

      _logMemory.info("CHANNEL[$c] Purge> removed events: $del");
    }

    _logMemory.info("Purge> total removed events: $totalDel");

    return totalDel;
  }

  @override
  FutureOr<bool> pull(String channelName, AsyncEventID? fromID) {
    fromID ??= AsyncEventID.zero();

    return fetch(channelName, fromID).resolveMapped((events) {
      _notifyNewEvents(channelName, events);
      return true;
    });
  }
}

/// A remote [AsyncEventStorage].
class AsyncEventStorageRemote extends AsyncEventStorage {
  /// The client that access the real storage.
  final AsyncEventStorageClient client;

  AsyncEventStorageRemote(super.name, this.client);

  @override
  FutureOr<int> get epoch => client.epoch;

  @override
  FutureOr<AsyncEvent?> newEvent(
          String channelName, String type, Map<String, dynamic> payload) =>
      client.newEvent(channelName, type, payload);

  @override
  @Deprecated(
      "Should not be called in a remote storage instance. Use `newEvent`")
  FutureOr<bool> store(String channelName, AsyncEvent event) {
    throw UnsupportedError("Not supported for remote storage. Use `newEvent`");
  }

  @override
  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID) =>
      client.fetch(channelName, fromID);

  @override
  FutureOr<AsyncEventID?> lastID(String channelName) =>
      client.lastID(channelName);

  @override
  FutureOr<AsyncEvent?> last(String channelName) => client.last(channelName);

  @override
  FutureOr<int> purge(int untilEpoch) => client.purge(untilEpoch);

  @override
  FutureOr<bool> pull(String channelName, AsyncEventID? fromID) {
    fromID ??= AsyncEventID.zero();

    return fetch(channelName, fromID).resolveMapped((events) {
      _notifyNewEvents(channelName, events);
      return true;
    });
  }
}

/// Interface for an [AsyncEventStorageRemote] client.
abstract class AsyncEventStorageClient {
  /// Calls [AsyncEventStorage.epoch].
  FutureOr<int> get epoch;

  /// Calls [AsyncEventStorage.newEvent].
  FutureOr<AsyncEvent?> newEvent(
      String channelName, String type, Map<String, dynamic> payload);

  /// Calls [AsyncEventStorage.fetch].
  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID);

  /// Calls [AsyncEventStorage.lastID].
  FutureOr<AsyncEventID?> lastID(String channelName);

  /// Calls [AsyncEventStorage.last].
  FutureOr<AsyncEvent?> last(String channelName);

  /// Calls [AsyncEventStorage.purge].
  FutureOr<int> purge(int untilEpoch);
}
