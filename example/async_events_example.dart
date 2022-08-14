import 'package:async_events/async_events.dart';

void main() async {
  // The event storage:
  var storage = AsyncEventStorageMemory('test');

  // The event HUB:
  var hub = AsyncEventHub('test', storage);

  // Get the channels:
  var c1 = hub.channel('c1');
  var c2 = hub.channel('c2');

  // Subscribe to channels:

  var sub1 = await c1.subscribe((event) {
    print('C1 EVENT> $event');
  });

  var sub2 = await c2.subscribe((event) {
    print('C2 EVENT> $event');
  });

  // Submit somme events:

  var event1 = await c1.submit('t', {'name': 't1'});
  var event2 = await c2.submit('t', {'name': 't2'});

  var sentEvents = [event1, event2];

  // Subscribe later to the channel `c2`:
  // - `fromBegin: true`: will receive all the previous events.
  var sub2b = await c2.subscribe(fromBegin: true, (event) {
    print('C2[b] EVENT> $event');
  });

  // Submit another event to `c2`:
  var event3 = await c2.submit('t', {'name': 't3'});

  sentEvents.add(event3);

  // Cancel channel subscriptions:
  sub1.cancel();
  sub2.cancel();
  sub2b.cancel();
}

/////////////////////////////
// OUTPUT:
/////////////////////////////
// C1 EVENT> AsyncEvent[0#1@2022-08-14T16:08:27.454474Z]<t>{name: t1}
// C2 EVENT> AsyncEvent[0#1@2022-08-14T16:08:27.466402Z]<t>{name: t2}
// C2[b] EVENT> AsyncEvent[0#1@2022-08-14T16:08:27.466402Z]<t>{name: t2}
// C2 EVENT> AsyncEvent[0#2@2022-08-14T16:08:27.471468Z]<t>{name: t3}
// C2[b] EVENT> AsyncEvent[0#2@2022-08-14T16:08:27.471468Z]<t>{name: t3}
