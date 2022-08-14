import 'package:async_events/async_events.dart';
import 'package:async_extension/async_extension.dart';
import 'package:logging/logging.dart' as logging;

import 'async_events_storage.dart';

final _log = logging.Logger('AsyncEvent');

/// An [AsyncEvent] ID.
class AsyncEventID implements Comparable<AsyncEventID> {
  /// The epoch of this event.
  final int epoch;

  /// The serial version of this event in the [epoch].
  final int serial;

  const AsyncEventID(this.epoch, this.serial);

  const AsyncEventID.zero() : this(0, 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncEventID &&
          runtimeType == other.runtimeType &&
          epoch == other.epoch &&
          serial == other.serial;

  @override
  int get hashCode => epoch.hashCode ^ serial.hashCode;

  @override
  int compareTo(AsyncEventID other) {
    var cmp = epoch.compareTo(other.epoch);

    if (cmp == 0) {
      cmp = serial.compareTo(other.serial);
    }

    return cmp;
  }

  factory AsyncEventID.fromJson(Map<String, dynamic> json) {
    return AsyncEventID(json['epoch'], json['serial']);
  }

  Map<String, dynamic> toJson() => {
        'epoch': epoch,
        'serial': serial,
      };

  @override
  String toString() {
    return '$epoch#$serial';
  }

  bool operator <(AsyncEventID other) => compareTo(other) < 0;

  bool operator <=(AsyncEventID other) => compareTo(other) <= 0;

  bool operator >(AsyncEventID other) => compareTo(other) > 0;

  bool operator >=(AsyncEventID other) => compareTo(other) >= 0;
}

/// An [AsyncEventChannel] event.
class AsyncEvent implements Comparable<AsyncEvent> {
  /// The ID of this event.
  final AsyncEventID id;

  /// The submit time of this event.
  final DateTime time;

  /// The type of this event.
  final String type;

  /// The payload of this event.
  final Map<String, dynamic> payload;

  AsyncEvent(this.id, this.time, this.type, this.payload);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(AsyncEvent other) => id.compareTo(other.id);

  factory AsyncEvent.fromJson(Map<String, dynamic> json) {
    return AsyncEvent(
        AsyncEventID.fromJson(json),
        DateTime.fromMillisecondsSinceEpoch(json['time']),
        json['type'],
        json['payload']);
  }

  Map<String, dynamic> toJson() => {
        ...id.toJson(),
        'time': time.toUtc().millisecondsSinceEpoch,
        'type': type,
        'payload': payload,
      };

  @override
  String toString() {
    return 'AsyncEvent[$id@${time.toIso8601String()}]<$type>$payload';
  }
}

typedef AsyncEventMatcher = bool Function(AsyncEvent event);

/// An [AsyncEvent] hub.
class AsyncEventHub {
  /// The name of this event hub.
  final String name;

  /// The storage of [AsyncEvent].
  final AsyncEventStorage storage;

  AsyncEventHub(this.name, this.storage);

  final Map<String, AsyncEventChannel> _channels =
      <String, AsyncEventChannel>{};

  /// Returns an [AsyncEventChannel] with [name].
  AsyncEventChannel channel(String name) =>
      _channels.putIfAbsent(name, () => AsyncEventChannel(this, name));

  /// The current epoch of the [storage].
  FutureOr<int> get epoch => storage.epoch;

  FutureOr<AsyncEvent?> _submit(
      AsyncEventChannel channel, String type, Map<String, dynamic> payload) {
    return storage
        .nextEvent(channel.name, type, payload)
        .resolveMapped((event) {
      return storage.store(channel.name, event).resolveMapped((ok) {
        if (!ok) {
          _log.warning("Error storing event: $event");
          return null;
        }

        channel._processEvent(event);
        return event;
      });
    });
  }
}

typedef AsyncEventListener = FutureOr<dynamic> Function(AsyncEvent event);

mixin WithLastEventID {
  AsyncEventID? _lastEventID;

  bool isAfterLastEventID(AsyncEventID? eventID) {
    if (eventID == null) return false;

    var last = _lastEventID;

    var cmp = last == null ? -1 : last.compareTo(eventID);
    return cmp <= 0;
  }

  AsyncEventID? get lastEventID => _lastEventID;

  set lastEventID(AsyncEventID? value) {
    if (value == null) return;
    var last = _lastEventID;

    var cmp = last == null ? -1 : last.compareTo(value);
    if (cmp <= 0) {
      _lastEventID = value;
    }
  }
}

/// An [AsyncEventHub] channel.
class AsyncEventChannel with WithLastEventID {
  /// The event hub of this channel.
  final AsyncEventHub hub;

  /// This channel name.
  final String name;

  AsyncEventChannel(this.hub, this.name);

  final List<AsyncEventSubscription> _subscriptions =
      <AsyncEventSubscription>[];

  /// Subscribe to events of this channel.
  FutureOr<AsyncEventSubscription> subscribe(AsyncEventListener listener,
      {AsyncEventID? fromID,
      bool fromBegin = false,
      bool fromEpochBegin = false}) {
    if (fromID == null) {
      if (fromBegin) {
        fromID = AsyncEventID.zero();
      } else if (fromEpochBegin) {
        return hub.epoch.resolveMapped((epoch) {
          return _subscribeImpl(listener, AsyncEventID(epoch, 0));
        });
      }
    }

    return _subscribeImpl(listener, fromID);
  }

  FutureOr<AsyncEventSubscription> _subscribeImpl(
      AsyncEventListener listener, AsyncEventID? fromID) {
    var subscription = AsyncEventSubscription(this, listener, fromID: fromID);
    _subscriptions.add(subscription);

    subscription._doSync();

    return subscription.ensureSynchronized().resolveWithValue(subscription);
  }

  /// Cancels a [subscription].
  bool cancel(AsyncEventSubscription subscription) =>
      _subscriptions.remove(subscription);

  /// Returns `true` if [subscription] is subscribed to this channel.
  bool isSubscribed(AsyncEventSubscription subscription) =>
      _subscriptions.contains(subscription);

  /// Submits and broadcast an event to this channel.
  FutureOr<AsyncEvent?> submit(String type, Map<String, dynamic> payload) =>
      hub._submit(this, type, payload);

  void _processEvent(AsyncEvent event) {
    _lastEventID = event.id;

    for (var e in _subscriptions) {
      e._processEvent(event);
    }
  }

  @override
  String toString() {
    return 'AsyncEventChannel[$name]';
  }
}

/// An [AsyncEventChannel] event subscription.
class AsyncEventSubscription with WithLastEventID {
  /// The [AsyncEventChannel] of this subscription.
  final AsyncEventChannel channel;

  /// The listener [Function] of events of this subscription.
  final AsyncEventListener listener;

  /// If provided, will receive events starting [fromID].
  final AsyncEventID? fromID;

  AsyncEventSubscription(this.channel, this.listener, {this.fromID});

  /// Cancels this subscriptiont to [channel].
  void cancel() => channel.cancel(this);

  /// Returns `true` if this [AsyncEventSubscription] instance is
  /// subscribed to [channel].
  bool get isSubscribed => channel.isSubscribed(this);

  List<AsyncEvent>? _unflushedEvents;

  FutureOr<int> _flushEvents() {
    var unflushedEvents = _unflushedEvents;
    if (unflushedEvents == null || unflushedEvents.isEmpty) {
      return 0;
    }

    unflushedEvents.sort();

    AsyncEvent? prev;

    var asyncLoop =
        AsyncLoop<int>(0, (i) => i < unflushedEvents.length, (i) => i + 1, (i) {
      var e = unflushedEvents[i];
      if (prev?.id == e.id) {
        return true;
      }

      return _processEventImpl(e).resolveMapped((_) {
        prev = e;
        return true;
      });
    });

    return asyncLoop.run();
  }

  FutureOr<bool> _processEvent(AsyncEvent event) {
    if (!_sync) {
      var unflushedEvents = _unflushedEvents ??= <AsyncEvent>[];
      unflushedEvents.add(event);
      return false;
    }

    return _processEventImpl(event);
  }

  FutureOr<bool> _processEventImpl(AsyncEvent event) {
    if (!isAfterLastEventID(event.id)) {
      return false;
    }

    lastEventID = event.id;

    return asyncTry<Object?>(() => listener(event),
        then: (_) => true,
        onError: (e, s) {
          _log.severe("$channel Error processing event: $event", e, s);
          return false;
        }).resolveMapped((val) => val is bool ? val : false);
  }

  bool _sync = false;

  void _doSync() {
    var fromID = this.fromID;
    if (fromID == null) {
      _finishSync();
      return;
    }

    channel.hub.storage
        .fetch(channel.name, fromID)
        .resolveMapped((sel) => _onSyncEvents(sel));
  }

  void _onSyncEvents(List<AsyncEvent> syncEvents) {
    syncEvents.sort();

    var unflushedEvents = _unflushedEvents ??= <AsyncEvent>[];
    unflushedEvents.addAll(syncEvents);

    _flushEvents().resolveWith(_finishSync);
  }

  void _finishSync() {
    var syncWaiting = _syncWaiting;
    _sync = true;

    if (syncWaiting != null) {
      syncWaiting.complete(true);
      _syncWaiting = null;
    }
  }

  Completer<bool>? _syncWaiting;

  /// Ensures that this subscription is synchronized with the channel.
  FutureOr<bool> ensureSynchronized() {
    if (_sync) return true;

    var syncWaiting = _syncWaiting ??= Completer<bool>();
    return syncWaiting.future;
  }
}
