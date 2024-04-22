import 'dart:math' as math;

import 'package:async_events/async_events.dart';
import 'package:async_extension/async_extension.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart' as logging;
import 'package:reflection_factory/reflection_factory.dart';

import 'async_events_storage.dart';

part 'reflection/async_events_base.g.dart';

final _log = logging.Logger('AsyncEvent');
final _logAsyncEventPulling = logging.Logger('AsyncEventPulling');

/// An [AsyncEvent] ID.
@EnableReflection()
class AsyncEventID implements Comparable<AsyncEventID> {
  static bool _boot = false;

  static void boot() {
    if (_boot) return;
    _boot = true;

    AsyncEventID$reflection.boot();

    AsyncEvent.boot();
  }

  /// The epoch of this event.
  final int epoch;

  /// The serial version of this event in the [epoch].
  final int serial;

  const AsyncEventID(this.epoch, this.serial);

  const AsyncEventID.zero() : this(0, 0);

  const AsyncEventID.any() : this(0, -1);

  factory AsyncEventID.from(Object o) {
    if (o is AsyncEventID) return o;
    if (o is Map<String, Object?>) return AsyncEventID.fromJson(o);

    var s = o.toString();
    return AsyncEventID.parse(s);
  }

  /// Returns the previous serial ID in the same [epoch].
  AsyncEventID? get previous =>
      serial > 0 ? AsyncEventID(epoch, serial - 1) : null;

  /// Returns the next serial ID in the same [epoch].
  AsyncEventID? get next => AsyncEventID(epoch, serial + 1);

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
    var id = json['id'];

    if (id != null && id is String) {
      return AsyncEventID.parse(id);
    } else {
      var epoch = json['epoch'];
      var serial = json['serial'];

      if (epoch is! int || serial is! int) {
        throw ArgumentError("Invalid JSON for `AsyncEventID`: $json");
      }

      return AsyncEventID(epoch, serial);
    }
  }

  Map<String, dynamic> toJson() => {
        'epoch': epoch,
        'serial': serial,
      };

  @override
  String toString() {
    return '$epoch#$serial';
  }

  static AsyncEventID? tryParse(String? s) {
    if (s == null) return null;

    s = s.trim();
    if (s.isEmpty) return null;

    var idx = s.indexOf('#');
    if (idx <= 0) {
      return null;
    }

    var epochStr = s.substring(0, idx);
    var serialStr = s.substring(idx + 1);

    var epoch = int.tryParse(epochStr);
    var serial = int.tryParse(serialStr);

    if (epoch == null || serial == null) {
      return null;
    }

    return AsyncEventID(epoch, serial);
  }

  factory AsyncEventID.parse(String s) {
    s = s.trim();
    var idx = s.indexOf('#');
    if (idx <= 0) {
      throw FormatException("Invalid `AsyncEventID` format: $s");
    }

    var epochStr = s.substring(0, idx);
    var serialStr = s.substring(idx + 1);

    var epoch = int.tryParse(epochStr);
    var serial = int.tryParse(serialStr);

    if (epoch == null || serial == null) {
      throw FormatException("Invalid `AsyncEventID` format: $s");
    }

    return AsyncEventID(epoch, serial);
  }

  bool operator <(AsyncEventID other) => compareTo(other) < 0;

  bool operator <=(AsyncEventID other) => compareTo(other) <= 0;

  bool operator >(AsyncEventID other) => compareTo(other) > 0;

  bool operator >=(AsyncEventID other) => compareTo(other) >= 0;
}

/// An [AsyncEventChannel] event.
@EnableReflection()
class AsyncEvent implements Comparable<AsyncEvent> {
  static bool _boot = false;

  static void boot() {
    if (_boot) return;
    _boot = true;

    AsyncEvent$reflection.boot();

    AsyncEventID.boot();
  }

  /// The [AsyncEventChannel] name of this event.
  @JsonFieldAlias('channel')
  final String channelName;

  /// The ID of this event.
  final AsyncEventID id;

  /// The submission time of this event.
  final DateTime time;

  /// The type of this event.
  final String type;

  /// The payload of this event.
  final Map<String, dynamic> payload;

  AsyncEvent(this.channelName, Object id, this.time, this.type, this.payload)
      : id = AsyncEventID.from(id) {
    boot();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(AsyncEvent other) => id.compareTo(other.id);

  factory AsyncEvent.fromJson(Map<String, dynamic> json,
      {String? channelName}) {
    return AsyncEvent(
        json['channel'] ?? channelName!,
        AsyncEventID.fromJson(json),
        DateTime.fromMillisecondsSinceEpoch(json['time']),
        json['type'],
        json['payload']);
  }

  Map<String, dynamic> toJson({bool withChannelName = true}) => {
        if (withChannelName) 'channel': channelName,
        'id': id.toString(),
        'time': time.toUtc().millisecondsSinceEpoch,
        'type': type,
        'payload': payload,
      };

  @override
  String toString() {
    return 'AsyncEvent[$id@${time.toIso8601String()}]<$type>$payload';
  }
}

extension ListAsyncEventExtension on List<AsyncEvent> {
  bool insertSorted(AsyncEvent event) {
    final length = this.length;

    if (length == 0) {
      add(event);
      return true;
    } else if (length == 1) {
      final first = this.first;
      final cmp = event.compareTo(first);

      if (cmp < 0) {
        insert(0, event);
        return true;
      } else if (cmp > 0) {
        add(event);
        return true;
      } else {
        return false;
      }
    } else {
      final last = this.last;
      final cmpLast = event.compareTo(last);

      if (cmpLast == 0) {
        return false;
      } else if (cmpLast > 0) {
        add(event);
        return true;
      }

      final first = this.first;
      final cmpFirst = event.compareTo(first);

      if (cmpFirst == 0) {
        return false;
      } else if (cmpFirst < 0) {
        insert(0, event);
        return true;
      }

      var insertIdx = this.lowerBound(event, (p0, p1) => p0.compareTo(p1));

      var elem = this[insertIdx];

      if (event.compareTo(elem) != 0) {
        insert(insertIdx, event);
        return true;
      } else {
        return false;
      }
    }
  }
}

typedef AsyncEventMatcher = bool Function(AsyncEvent event);

/// An [AsyncEvent] hub.
class AsyncEventHub {
  /// The name of this event hub.
  final String name;

  /// The storage of [AsyncEvent].
  final AsyncEventStorage storage;

  AsyncEventHub(this.name, this.storage) {
    AsyncEvent.boot();
  }

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

  FutureOr<AsyncEvent?> _submit(
          AsyncEventChannel channel, String type, Map<String, dynamic> payload,
          {DateTime? time}) =>
      storage.newEvent(channel.name, type, payload, time: time);

  FutureOr<List<AsyncEvent>> _fetch(
          AsyncEventChannel channel, AsyncEventID fromID, int? limit) =>
      storage.fetch(channel.name, fromID, limit: limit);

  /// Pull new events from storage.
  FutureOr<int> pull(String channelName, AsyncEventID? fromID) =>
      storage.pull(channelName, fromID);

  /// Purge events and create a new epoch from the remaining events.
  FutureOr<int> purge(String channelName,
          {AsyncEventID? untilID, DateTime? before, bool all = false}) =>
      storage.purgeEvents(channelName,
          untilID: untilID, before: before, all: all);

  /// Cancels channel with [channelName] calls.
  void cancelChannelCalls(String channelName) =>
      storage.cancelChannelCalls(channelName);

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
  FutureOr<AsyncEvent?> submit(String type, Map<String, dynamic> payload,
          {DateTime? time}) =>
      hub._submit(this, type, payload, time: time);

  final Map<AsyncEventPullingConfig, AsyncEventPulling> _pullingByConfig =
      <AsyncEventPullingConfig, AsyncEventPulling>{};

  /// Returns a shared [AsyncEventPulling] based on the defined [AsyncEventPullingConfig].
  AsyncEventPulling pulling(
      {Duration? delay,
      Duration period = const Duration(seconds: 10),
      Duration? minInterval,
      bool started = true}) {
    var config =
        AsyncEventPullingConfig(period: period, minInterval: minInterval);

    var eventPulling = _pullingByConfig.putIfAbsent(
        config, () => AsyncEventPulling.fromConfig(this, config));

    if (started && !eventPulling.isStarted) {
      eventPulling.start(delay: delay);
    }

    return eventPulling;
  }

  FutureOr<int> purge(
          {AsyncEventID? untilID, DateTime? before, bool all = false}) =>
      hub.purge(name, untilID: untilID, before: before, all: all);

  /// Fetches events of this channel starting [fromID].
  FutureOr<List<AsyncEvent>> fetch(AsyncEventID fromID, {int? limit}) =>
      hub._fetch(this, fromID, limit);

  /// Fetches events of this channel starting [fromID] with a [timeout].
  FutureOr<List<AsyncEvent>> fetchDelayed(AsyncEventID fromID,
      {Duration timeout = const Duration(seconds: 1), int? limit}) {
    if (timeout.inMilliseconds <= 0) return fetch(fromID);

    return fetch(fromID, limit: limit).resolveMapped((events) {
      if (events.isNotEmpty) {
        return events;
      }

      return waitNewEvent(timeout).then((_) {
        // Ensure that the `fetch` happens after any
        // `Future` already scheduled that can populate
        // more events:
        return Future.microtask(() => fetch(fromID, limit: limit));
      });
    });
  }

  List<AsyncEvent>? _unflushedEvents;

  /// Returns `true` if this instance has unflushed events.
  bool get hasUnflushedEvents {
    var unflushedEvents = _unflushedEvents;
    return unflushedEvents != null && unflushedEvents.isNotEmpty;
  }

  bool _flushEvents() {
    var unflushedEvents = _unflushedEvents;
    if (unflushedEvents == null) {
      return true;
    } else if (unflushedEvents.isEmpty) {
      _unflushedEvents = null;
      return true;
    }

    unflushedEvents.sort();

    var delLength = 0;

    for (var i = 0; i < unflushedEvents.length; ++i) {
      var event = unflushedEvents[i];

      var processed = _processEvent(event, fromUnflushedEvents: true);

      if (!processed) {
        break;
      }

      delLength = i + 1;
    }

    if (delLength > 0) {
      if (delLength >= unflushedEvents.length) {
        _unflushedEvents = null;
        return true;
      } else {
        unflushedEvents.removeRange(0, delLength);
        return false;
      }
    } else {
      return false;
    }
  }

  bool _addToUnflushedEvents(AsyncEvent event) {
    var unflushedEvents = _unflushedEvents;

    if (unflushedEvents == null) {
      _unflushedEvents = [event];
      return true;
    }

    return unflushedEvents.insertSorted(event);
  }

  bool _processEvent(AsyncEvent event, {bool fromUnflushedEvents = false}) {
    if (!fromUnflushedEvents && hasUnflushedEvents) {
      if (!_flushEvents()) {
        _addToUnflushedEvents(event);
        return false;
      }
    }

    final eventID = event.id;

    // New epoch event:
    if (eventID.serial == 0) {
      var processed = _processNewEpochEvent(event, fromUnflushedEvents);

      if (processed) {
        _logChannel.info("New epoch: ${eventID.epoch} ; $event");
      }

      return processed;
    }
    // Limit cut event:
    else if (eventID.serial == -1 &&
        eventID.epoch == 0 &&
        event.type == 'limit') {
      var nextEventIDStr = event.payload['nextID'];
      var nextEventID = AsyncEventID.tryParse(nextEventIDStr);

      var previousEventID = nextEventID?.previous;

      if (previousEventID != null) {
        lastEventID = previousEventID;
      }

      return true;
    }

    // Ignore old event:
    if (!isAfterLastEventID(eventID)) {
      return true;
    }

    // Out of sync event:
    if (!isNextEventID(eventID)) {
      if (!fromUnflushedEvents) {
        _addToUnflushedEvents(event);
      }
      return false;
    }

    // Normal sequence (process it):
    _lastEventID = eventID;

    _onNewEvent(event);

    for (var g in _subscriptionsGroups) {
      g._processEvent(event);
    }

    return true;
  }

  bool _processNewEpochEvent(AsyncEvent event, bool fromUnflushedEvents) {
    var eventID = event.id;

    var previousIDStr = event.payload['previousID'];
    var previousID = AsyncEventID.tryParse(previousIDStr);

    var lastEventID = _lastEventID;

    var lastEpoch = -1;
    var lastSerial = -1;

    if (lastEventID != null) {
      lastEpoch = lastEventID.epoch;
      lastSerial = lastEventID.serial;
    }

    if (previousID == null) {
      var nextIDStr = event.payload['nextID'];
      var nextID = AsyncEventID.tryParse(nextIDStr);

      var nextPrevious = nextID?.previous;

      if (lastEpoch < eventID.epoch) {
        assert(nextPrevious == null || lastEpoch < nextPrevious.epoch);
        _lastEventID = nextPrevious ?? eventID;
        return true;
      } else if (lastEpoch == eventID.epoch) {
        assert(nextPrevious == null || lastEpoch == nextPrevious.epoch);

        if (lastSerial <= 0) {
          _lastEventID = nextPrevious ?? eventID;
        } else if (nextPrevious != null && lastSerial < nextPrevious.serial) {
          _lastEventID = nextPrevious;
        }

        return true;
      } else {
        if (nextPrevious != null) {
          _lastEventID = nextPrevious;
          return true;
        } else {
          _logChannel.warning(
              "New epoch event out of sync> lastEventID: $lastEventID ; event: $event");
          return false;
        }
      }
    } else {
      // Normal sequence:
      if (lastEventID == previousID) {
        _lastEventID = eventID;
        return true;
      }
      // Events already in future from previousID:
      else if (lastEpoch > previousID.epoch) {
        _logChannel.warning(
            "New epoch event out of sync> lastEventID: $lastEventID ; event: $event ; previousID: $previousID");
        return false;
      }
      // Out of order:
      else {
        if (!fromUnflushedEvents) {
          _addToUnflushedEvents(event);
        }
        return true;
      }
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

  Completer<AsyncEvent?>? _waitingNewEvents;

  void _onNewEvent(AsyncEvent event) {
    var waitingNewEvents = _waitingNewEvents;

    if (waitingNewEvents != null && !waitingNewEvents.isCompleted) {
      waitingNewEvents.complete(event);
    }
  }

  /// Waits for a new [AsyncEvent] with a [timeout].
  Future<AsyncEvent?> waitNewEvent(Duration timeout) {
    Future<AsyncEvent?> waitingFuture;

    var waitingNewEvents = _waitingNewEvents;

    if (waitingNewEvents != null) {
      waitingFuture = waitingNewEvents.future;
    } else {
      waitingNewEvents = _waitingNewEvents = Completer<AsyncEvent?>();

      waitingFuture = waitingNewEvents.future.then((event) {
        var prev = _waitingNewEvents;
        if (identical(prev, waitingNewEvents)) {
          _waitingNewEvents = null;
        }
        return event;
      });
    }

    return waitingFuture.timeout(timeout, onTimeout: () => null);
  }

  /// Checks for new events for this channel.
  FutureOr<int> pull() {
    var fromId = lastEventID?.next;
    return hub.pull(name, fromId);
  }

  /// Cancels current channel calls.
  void cancelCalls() => hub.cancelChannelCalls(name);

  @override
  String toString() {
    return 'AsyncEventChannel[$name]';
  }
}

/// An [AsyncEventPulling] configuration.
class AsyncEventPullingConfig {
  /// The pulling period.
  /// - Minimal: 10ms
  final Duration period;

  /// The minimal interval for consecutive [pull]s.
  final Duration minInterval;

  AsyncEventPullingConfig(
      {this.period = const Duration(seconds: 10), Duration? minInterval})
      : minInterval = _min(
            period,
            minInterval ??
                Duration(
                    milliseconds: math.max(period.inMilliseconds ~/ 10, 1))) {
    if (period.inMilliseconds < 10) {
      throw ArgumentError("period < 10ms");
    }
  }

  static Duration _min(Duration a, Duration b) => a.compareTo(b) <= 0 ? a : b;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncEventPullingConfig &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          minInterval == other.minInterval;

  @override
  int get hashCode => period.hashCode ^ minInterval.hashCode;

  factory AsyncEventPullingConfig.fromJson(Map<String, dynamic> json) =>
      AsyncEventPullingConfig(
          period: Duration(milliseconds: json['period']),
          minInterval: Duration(milliseconds: json['minInterval']));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'period': period.inMilliseconds,
        'minInterval': minInterval.inMilliseconds,
      };

  @override
  String toString() {
    return 'AsyncEventPullingConfig{period: $period, minInterval: $minInterval}';
  }
}

/// Performs a periodic pulling of [AsyncEventChannel] events.
class AsyncEventPulling {
  /// The [AsyncEventChannel] ot perform pulling of events.
  final AsyncEventChannel channel;

  final AsyncEventPullingConfig config;

  /// The pulling period.
  /// - Minimal: 10ms
  Duration get period => config.period;

  /// The minimal interval for consecutive [pull]s.
  Duration get minInterval => config.minInterval;

  AsyncEventPulling(this.channel,
      {Duration period = const Duration(seconds: 10), Duration? minInterval})
      : config =
            AsyncEventPullingConfig(period: period, minInterval: minInterval);

  AsyncEventPulling.fromConfig(this.channel, this.config);

  static Duration _min(Duration a, Duration b) => a.compareTo(b) <= 0 ? a : b;

  bool _started = false;

  bool get isStarted => _started;

  /// Starts pulling.
  void start({Duration? delay}) {
    if (_started) return;
    _started = true;
    _stopped = false;

    if (delay != null) {
      Future.delayed(delay, _autoPull);
    } else {
      _autoPull();
    }
  }

  bool _stopped = false;

  bool get isStopped => _stopped && !isScheduled;

  /// Stops pulling
  ///
  /// - If [cancelChannelCalls] is `true` it will call [cancelChannelCalls].
  ///   Any event pulling or submit in this channel will be cancelled.
  void stop({bool cancelChannelCalls = false}) {
    if (_stopped) return;
    _stopped = true;

    if (!isScheduled) {
      _started = false;
    }

    if (cancelChannelCalls) {
      this.cancelChannelCalls();
    }
  }

  void cancelChannelCalls() => channel.cancelCalls();

  int _consecutiveEmptyEventsCount = 0;
  int _lastEventsLength = 0;

  /// Returns `true` if is currently pulling.
  bool get isPulling => _pulling != null;

  FutureOr<int>? _pulling;

  /// Forces a [channel] pull.
  FutureOr<int> pull() {
    var pulling = _pulling;
    if (pulling != null) {
      return pulling;
    }

    try {
      var pullAsync = channel.pull();
      _pulling = pullAsync;

      if (pullAsync is Future<int>) {
        return pullAsync.then(_onPull, onError: (e, s) {
          _logAsyncEventPulling.severe(
              "Error pulling> channel: $channel", e, s);
          return _onPull(0);
        });
      } else {
        return _onPull(pullAsync);
      }
    } catch (e, s) {
      _logAsyncEventPulling.severe("Error pulling> channel: $channel", e, s);
      return _onPull(0);
    }
  }

  FutureOr<int> _onPull(int eventsLength) {
    _pulling = null;
    _lastEventsLength = eventsLength;

    if (eventsLength <= 0) {
      ++_consecutiveEmptyEventsCount;
    } else {
      _consecutiveEmptyEventsCount = 0;
    }

    var waitPulling = _waitPulling;
    if (waitPulling != null) {
      assert(!waitPulling.isCompleted);
      waitPulling.complete(true);
      _waitPulling = null;
    }

    return eventsLength;
  }

  Completer<bool>? _waitPulling;

  /// Waits for a [pull] and completes.
  FutureOr<bool> waitPulling() {
    if (!isStarted || isStopped) return false;

    var pulling = _pulling;
    if (pulling != null) {
      return pulling.resolveWith(() => true);
    }

    var completer = _waitPulling ??= Completer<bool>();
    return completer.future;
  }

  void _autoPull() {
    if (_stopped) {
      _started = false;
      return;
    }

    pull().onResolve((_) => _schedule());
  }

  int _scheduleIdCount = 0;

  int _scheduled = 0;

  /// Returns `true` if a pulling was scheduled.
  bool get isScheduled => _scheduled > 0;

  void _schedule({bool force = false}) {
    if (_stopped) {
      _started = false;
      return;
    }

    if (isScheduled && !force) return;

    var scheduleId = ++_scheduleIdCount;
    _scheduled = scheduleId;

    var delay = _nextDelay();

    Future.delayed(delay, () {
      if (_scheduled != scheduleId) return;
      _scheduled = 0;
      _autoPull();
    });
  }

  Duration _nextDelay() {
    if (_lastEventsLength > 0) {
      return minInterval;
    }

    switch (_consecutiveEmptyEventsCount) {
      case 1:
        {
          return minInterval;
        }
      case 2:
      case 3:
        {
          return _min(
              Duration(
                  milliseconds: minInterval.inMilliseconds *
                      _consecutiveEmptyEventsCount),
              period);
        }
      default:
        {
          return period;
        }
    }
  }

  @override
  String toString() {
    return 'AsyncEventPulling{channel: ${channel.name}, config: ${config.toJson()}, started: $_started, stopped: $_stopped, pulling: $isPulling, scheduled: $isScheduled, lastEventsLength: $_lastEventsLength, consecutiveEmptyEventsCount: $_consecutiveEmptyEventsCount}';
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

  void _flushSync([int retry = 0]) {
    var flushEventsAsync = _flushEvents();

    flushEventsAsync.resolveMapped((_) {
      if (hasUnflushedEvents) {
        if (retry <= 3 || flushEventsAsync is Future) {
          _flushSync(retry + 1);
        } else {
          Future.microtask(() => _flushSync(retry + 1));
        }
      } else {
        _finishSync();
      }
    });
  }

  void _finishSync() {
    var syncWaiting = _syncWaiting;
    _sync = true;

    if (syncWaiting != null) {
      assert(!syncWaiting.isCompleted);
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
  FutureOr<int> pull() => _group.channel.pull();

  @override
  String toString() {
    return 'AsyncEventSubscription[${_group.channel.name}]{fromID: $fromID}';
  }
}

/// An error while handling an [AsyncEvent].
class AsyncEventError extends Error {
  /// The error message.
  final String message;

  /// The original native error.
  final Object? cause;

  AsyncEventError(this.message, {this.cause});

  factory AsyncEventError.from(String? message, Object? cause) {
    if (message == null) {
      if (cause != null) {
        return AsyncEventError('$cause', cause: cause);
      } else {
        return AsyncEventError('', cause: cause);
      }
    } else {
      return AsyncEventError(message, cause: cause);
    }
  }

  @override
  String toString() => "[AsyncEventError] $message";
}
