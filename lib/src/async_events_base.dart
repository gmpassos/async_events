import 'package:async_events/async_events.dart';
import 'package:async_extension/async_extension.dart';
import 'package:collection/collection.dart';
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

  const AsyncEventID.any() : this(0, -1);

  /// Returns the previous serial ID.
  AsyncEventID? get previous =>
      serial > 0 ? AsyncEventID(epoch, serial - 1) : null;

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
      _channels.putIfAbsent(name, () => _createChannel(name));

  AsyncEventChannel _createChannel(String name) {
    var channel = AsyncEventChannel(this, name);

    storage.listenEvents(name, (event) => channel._processEvent(event));

    return channel;
  }

  /// The current epoch of the [storage].
  FutureOr<int> get epoch => storage.epoch;

  FutureOr<AsyncEvent?> _submit(AsyncEventChannel channel, String type,
          Map<String, dynamic> payload) =>
      storage.newEvent(channel.name, type, payload);

  /// Pull new events from storage.
  FutureOr<bool> pull(String channelName, AsyncEventID? fromID) =>
      storage.pull(channelName, fromID);

  @override
  String toString() {
    return 'AsyncEventHub[$name]{storage: $storage, channels: ${_channels.keys.toList()}}';
  }
}

typedef AsyncEventListener = FutureOr<dynamic> Function(AsyncEvent event);

mixin WithLastEventID {
  AsyncEventID? _lastEventID;

  /// Returns `true` if [eventID] is after [lastEventID].
  bool isAfterLastEventID(AsyncEventID? eventID) {
    if (eventID == null) return false;

    var last = _lastEventID;

    var cmp = last == null ? -1 : last.compareTo(eventID);
    return cmp < 0;
  }

  bool isNextEventID(AsyncEventID? eventID) {
    if (eventID == null) return false;

    var last = _lastEventID;
    if (last == null) return false;

    if (last.epoch == eventID.epoch) {
      return last.serial + 1 == eventID.serial;
    } else if (last.epoch + 1 == eventID.epoch) {
      if (eventID.serial == 0) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  /// Returns the last [AsyncEventID] of this instance.
  AsyncEventID? get lastEventID => _lastEventID;

  /// Sets the last [AsyncEventID]. Ignores [value] if not after
  /// the current [lastEventID].
  set lastEventID(AsyncEventID? value) {
    if (value == null) return;
    var last = _lastEventID;

    var cmp = last == null ? -1 : last.compareTo(value);
    if (cmp <= 0) {
      _lastEventID = value;
    }
  }
}

final _logChannel = logging.Logger('AsyncEventChannel');

/// An [AsyncEventHub] channel.
class AsyncEventChannel with WithLastEventID {
  /// The event hub of this channel.
  final AsyncEventHub hub;

  /// This channel name.
  final String name;

  AsyncEventChannel(this.hub, this.name);

  final List<AsyncEventSubscriptionGroup> _subscriptionsGroups =
      <AsyncEventSubscriptionGroup>[];

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
    var group = AsyncEventSubscriptionGroup(this, fromID: fromID);
    var subscription = AsyncEventSubscription(group, listener, fromID: fromID);

    group.addSubscription(subscription);

    _subscriptionsGroups.add(group);

    group._doSync();

    return subscription.ensureSynchronized().resolveWithValue(subscription);
  }

  /// Cancels a [subscription].
  bool cancel(AsyncEventSubscription subscription) {
    var group = subscription.group;

    if (group.cancelSubscription(subscription)) {
      if (!group.hasSubscriptions) {
        return _subscriptionsGroups.remove(group);
      } else {
        return _subscriptionsGroups.contains(group);
      }
    } else {
      return false;
    }
  }

  /// Returns `true` if [subscription] is subscribed to this channel.
  bool isSubscribed(AsyncEventSubscription subscription) =>
      _subscriptionsGroups.any((g) => g.isSubscribed(subscription));

  /// Returns `true` if [subscriptionGroup] is subscribed to this channel.
  bool isSubscribedGroup(AsyncEventSubscriptionGroup subscriptionGroup) =>
      _subscriptionsGroups.contains(subscriptionGroup);

  /// Submits and broadcast an event to this channel.
  FutureOr<AsyncEvent?> submit(String type, Map<String, dynamic> payload) =>
      hub._submit(this, type, payload);

  void _processEvent(AsyncEvent event) {
    // Ignore old event:
    if (!isAfterLastEventID(event.id)) {
      return;
    }

    // Normal sequence:
    if (isNextEventID(event.id)) {
      _lastEventID = event.id;
    }
    // Initial ID:
    else if (_lastEventID == null || _lastEventID!.serial <= 0) {
      _lastEventID = event.id;
    }

    for (var g in _subscriptionsGroups) {
      g._processEvent(event);
    }
  }

  void _optimize() {
    var groupsByLastIDs =
        _subscriptionsGroups.groupListsBy((e) => e.lastEventID);

    for (var l in groupsByLastIDs.values) {
      if (l.length <= 1) continue;

      var main = l.first;

      for (var i = 1; i < l.length; ++i) {
        var e = l[i];

        if (main._merge(e)) {
          assert(!e.hasSubscriptions);
          _subscriptionsGroups.remove(e);

          _logChannel.info("CHANNEL[$name] Merge: $e -> $main");
        }
      }
    }
  }

  /// Checks for new events for this channel.
  FutureOr<bool> pull() => hub.pull(name, lastEventID);

  @override
  String toString() {
    return 'AsyncEventChannel[$name]';
  }
}

/// An [AsyncEventSubscription] group.
class AsyncEventSubscriptionGroup with WithLastEventID {
  /// The [AsyncEventChannel] of this subscription group.
  final AsyncEventChannel channel;

  final List<AsyncEventSubscription> _subscriptions;

  /// The [AsyncEventSubscription] of this group.
  List<AsyncEventSubscription> get subscriptions =>
      UnmodifiableListView(_subscriptions);

  /// If provided, will receive events starting [fromID].
  final AsyncEventID? fromID;

  AsyncEventSubscriptionGroup(this.channel,
      {this.fromID, Iterable<AsyncEventSubscription>? subscriptions})
      : _subscriptions = subscriptions?.toList() ?? <AsyncEventSubscription>[];

  /// Returns the size this group [subscriptions].
  int get subscriptionsSize => _subscriptions.length;

  /// Returns `true` if this group has [subscriptions].
  bool get hasSubscriptions => _subscriptions.isNotEmpty;

  /// Returns `true` if this group has the [subscription].
  bool isSubscribed(AsyncEventSubscription subscription) =>
      _subscriptions.contains(subscription);

  /// Adds [subscription] to this group.
  void addSubscription(AsyncEventSubscription subscription) =>
      _subscriptions.add(subscription);

  /// Cancels the [subscription] for [channel] in this group.
  bool cancelSubscription(AsyncEventSubscription subscription) =>
      _subscriptions.remove(subscription);

  List<AsyncEvent>? _unflushedEvents;

  /// Returns `true` if this instance has unflushed events.
  bool get hasUnflushedEvents {
    var unflushedEvents = _unflushedEvents;
    return unflushedEvents != null && unflushedEvents.isNotEmpty;
  }

  void _addToUnflushedEvents(
      {AsyncEvent? event, Iterable<AsyncEvent>? events}) {
    var unflushedEvents = _unflushedEvents ??= <AsyncEvent>[];

    var changed = false;

    if (event != null && !unflushedEvents.contains(event)) {
      unflushedEvents.add(event);
      changed = true;
    }

    if (events != null) {
      var newEvents =
          events.where((e) => !unflushedEvents.contains(e)).toList();

      unflushedEvents.addAll(newEvents);
      changed = true;
    }

    if (changed) {
      unflushedEvents.sort();
    }
  }

  bool _flushing = false;

  FutureOr<int> _flushEvents() {
    if (_flushing) {
      throw StateError("Already flushing events!");
    }

    _flushing = true;

    return _flushEventsImpl().resolveMapped((r) {
      _flushing = false;
      return r;
    });
  }

  FutureOr<int> _flushEventsImpl() {
    var unflushedEvents = _unflushedEvents;
    _unflushedEvents = null;

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

      return _processEventImpl(e).resolveMapped((ok) {
        if (ok == 1 || ok == 0) {
          prev = e;
          return true;
        } else if (ok == -1) {
          return false;
        } else {
          throw StateError("Unknown return status: $ok");
        }
      });
    });

    return asyncLoop.run().resolveMapped((i) {
      if (i < unflushedEvents.length) {
        var unflushedRest = unflushedEvents.sublist(i);
        _addToUnflushedEvents(events: unflushedRest);
        return -1;
      } else {
        return i;
      }
    });
  }

  FutureOr<bool> _processEvent(AsyncEvent event) {
    if (!_sync) {
      _addToUnflushedEvents(event: event);
      return false;
    }

    return _processEventImpl(event).resolveMapped((r) {
      if (r == 1 || r == 0) {
        return true;
      } else if (r == -1) {
        _addToUnflushedEvents(event: event);
        return false;
      } else {
        throw StateError("Unknown returned status: $r");
      }
    });
  }

  /// Returns:
  /// - `1`: successful.
  /// - `0`: ignored event.
  /// - `-1`: error (try later).
  FutureOr<int> _processEventImpl(AsyncEvent event) {
    // Ignore old event:
    if (!isAfterLastEventID(event.id)) {
      return 0;
    }

    // ID in sequence:
    if (isNextEventID(event.id)) {
      lastEventID = event.id;
    }
    // Check initial ID:
    else {
      var lastEventID = _lastEventID;

      // Not prepared to process events, will retry in the next event:
      if (lastEventID == null) {
        return -1;
      }
      // Accepts any ID as initial ID:
      else if (lastEventID.serial == -1) {
        lastEventID = event.id;
      }
      // Not prepared to process events, will retry in the next event:
      else {
        return -1;
      }
    }

    var resultsAsync =
        _subscriptions.map((e) => e._processEvent(event)).resolveAll();

    return resultsAsync
        .resolveMapped((results) => results.every((e) => e) ? 1 : -1);
  }

  bool _sync = false;

  void _doSync() {
    var fromID = this.fromID;
    if (fromID == null) {
      _onSyncEvents();
      return;
    }

    channel.hub.storage
        .fetch(channel.name, fromID)
        .resolveMapped((sel) => _onSyncEvents(sel));
  }

  void _onSyncEvents([List<AsyncEvent>? syncEvents]) {
    if (syncEvents == null || syncEvents.isEmpty) {
      _lastEventID = AsyncEventID.any();
    } else {
      syncEvents.sort();

      var firstId = syncEvents.first.id;
      var initId = firstId.previous ?? firstId;

      _lastEventID = initId;
    }

    _addToUnflushedEvents(events: syncEvents);

    _flushSync();
  }

  void _flushSync() {
    _flushEvents().resolveMapped((_) {
      if (hasUnflushedEvents) {
        _flushSync();
      } else {
        _finishSync();
      }
    });
  }

  void _finishSync() {
    var syncWaiting = _syncWaiting;
    _sync = true;

    if (syncWaiting != null) {
      syncWaiting.complete(true);
      _syncWaiting = null;
    }

    channel._optimize();
  }

  Completer<bool>? _syncWaiting;

  /// Ensures that this subscription is synchronized with the channel.
  FutureOr<bool> ensureSynchronized() {
    if (_sync) return true;

    var syncWaiting = _syncWaiting ??= Completer<bool>();
    return syncWaiting.future;
  }

  bool _merge(AsyncEventSubscriptionGroup otherGroup) {
    if (channel != otherGroup.channel) return false;
    if (lastEventID != otherGroup.lastEventID) return false;

    var subscriptions = otherGroup._subscriptions.toList();
    subscriptions.removeWhere((e) => _subscriptions.contains(e));

    _subscriptions.addAll(subscriptions);

    for (var s in subscriptions) {
      s._group = this;
    }

    otherGroup._subscriptions.clear();

    return true;
  }

  @override
  String toString() {
    return 'AsyncEventSubscriptionGroup[${channel.name}]{subscriptions: subscriptionsSize, fromID: $fromID, unflushedEvents: ${_unflushedEvents?.length}, sync: $_sync}';
  }
}

/// An [AsyncEventChannel] event subscription.
class AsyncEventSubscription {
  AsyncEventSubscriptionGroup _group;

  /// The [AsyncEventSubscriptionGroup] of this subscription.
  /// Note that the [group] instance can change due to internal optimizations
  /// with other [AsyncEventSubscriptionGroup] for the same channel.
  AsyncEventSubscriptionGroup get group => _group;

  /// The listener [Function] of events of this subscription.
  final AsyncEventListener listener;

  /// The [AsyncEventChannel] of this subscription.
  AsyncEventChannel get channel => _group.channel;

  /// If provided, will receive events starting [fromID].
  AsyncEventID? fromID;

  AsyncEventSubscription(this._group, this.listener, {this.fromID});

  AsyncEventID? get lastEventID => group.lastEventID;

  /// Cancels this subscription to [channel].
  void cancel() => channel.cancel(this);

  /// Returns `true` if this [AsyncEventSubscription] instance is
  /// subscribed to [channel].
  bool get isSubscribed =>
      group.isSubscribed(this) && channel.isSubscribedGroup(group);

  FutureOr<bool> _processEvent(AsyncEvent event) {
    return asyncTry<Object?>(() => listener(event),
        then: (_) => true,
        onError: (e, s) {
          _log.severe("$channel Error processing event: $event", e, s);
          return false;
        }).resolveMapped((val) => val is bool ? val : false);
  }

  /// Ensures that this subscription is synchronized with the channel.
  FutureOr<bool> ensureSynchronized() => group.ensureSynchronized();

  /// Checks for new events for this subscription.
  FutureOr<bool> pull() => _group.channel.pull();

  @override
  String toString() {
    return 'AsyncEventSubscription[${_group.channel.name}]{fromID: $fromID}';
  }
}
