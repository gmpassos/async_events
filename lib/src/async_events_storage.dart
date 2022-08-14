import 'package:async_events/async_events.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart' as logging ;

final  _log = logging.Logger('AsyncEvent') ;

class AsyncEvent {}

typedef AsyncEventMatcher = bool Function(AsyncEvent event);

class AsyncEventHub {
  final Map<String, AsyncEventChannel> _channels =
      <String, AsyncEventChannel>{};

  AsyncEventChannel channel(String name) =>
      _channels.putIfAbsent(name, () => AsyncEventChannel(this, name));

  void _submit(AsyncEventChannel channel, AsyncEvent event) {

  }
}

class AsyncEventStorage {

  

}

typedef AsyncEventListener = void Function(AsyncEvent event);

class AsyncEventChannel {
  final AsyncEventHub hub;
  final String name;

  AsyncEventChannel(this.hub, this.name);

  final List<AsyncEventSubscription> _subscriptions =
      <AsyncEventSubscription>[];

  AsyncEventSubscription subscribe(AsyncEventListener listener) {
    var subscription = AsyncEventSubscription(this, listener);
    _subscriptions.add(subscription);
    return subscription;
  }

  bool cancel(AsyncEventSubscription subscription) =>
      _subscriptions.remove(subscription);

  void submit(AsyncEvent event) {
    hub._submit(this, event);
  }

  void _processEvent(AsyncEvent event) {
    for (var e in _subscriptions) {
      e._processEvent(event);
    }
  }

  @override
  String toString() {
    return 'AsyncEventChannel[$name]';
  }
}

class AsyncEventSubscription {
  final AsyncEventChannel channel;

  final AsyncEventListener listener;

  AsyncEventSubscription(this.channel, this.listener);

  void cancel() => channel.cancel(this);

  void _processEvent(AsyncEvent event) {
    try {

    }
    catch(e,s) {
    _log.severe("$channel Error processing event: $event", e,s);
    }
  }
}
