import 'dart:math' as math;

import 'package:async_events/async_events.dart';
import 'package:async_extension/async_extension.dart';
import 'package:logging/logging.dart' as logging;

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

  FutureOr<AsyncEventID> nextEventID(String channelName) {
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

  FutureOr<AsyncEvent> nextEvent(
      String channelName, String type, Map<String, dynamic> payload) {
    return nextEventID(channelName).resolveMapped((id) {
      return AsyncEvent(id, currentTime, type, payload);
    });
  }

  FutureOr<bool> store(String channelName, AsyncEvent event);

  FutureOr<List<AsyncEvent>> fetch(String channelName, AsyncEventID fromID);

  FutureOr<AsyncEvent?> last(String channelName);

  FutureOr<AsyncEventID?> lastID(String channelName) =>
      last(channelName).resolveMapped((event) => event?.id);

  FutureOr<int> purge(int untilEpoch);
}

final _logMemory = logging.Logger('AsyncEventStorageMemory');

class AsyncEventStorageMemory extends AsyncEventStorage {
  AsyncEventStorageMemory(super.name, {super.epochPeriod});

  final Map<String, List<AsyncEvent>> _channelsEvents =
      <String, List<AsyncEvent>>{};

  final DateTime initTime = DateTime.now();

  @override
  FutureOr<int> get epoch {
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
  FutureOr<AsyncEvent?> last(String channelName) {
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
}
