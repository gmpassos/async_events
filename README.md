# async_events

[![pub package](https://img.shields.io/pub/v/async_events.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/async_events)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Codecov](https://img.shields.io/codecov/c/github/gmpassos/async_events)](https://app.codecov.io/gh/gmpassos/async_events)
[![CI](https://img.shields.io/github/workflow/status/gmpassos/async_events/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/async_events/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/async_events?logo=git&logoColor=white)](https://github.com/gmpassos/async_events/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/async_events/latest?logo=git&logoColor=white)](https://github.com/gmpassos/async_events/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/async_events?logo=git&logoColor=white)](https://github.com/gmpassos/async_events/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/async_events?logo=github&logoColor=white)](https://github.com/gmpassos/async_events/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/async_events?logo=github&logoColor=white)](https://github.com/gmpassos/async_events)
[![License](https://img.shields.io/github/license/gmpassos/async_events?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/async_events/blob/master/LICENSE)

A portable asynchronous event hub supporting multiple storage types

## Usage

Here's a simple usage example:

```dart
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

  // Subscribe later to the channel `c2`:
  // - `fromBegin: true`: will receive all the previous events.
  var sub2b = await c2.subscribe(fromBegin: true, (event) {
    print('C2[b] EVENT> $event');
  });

  // Submit another event to `c2`:
  var event3 = await c2.submit('t', {'name': 't3'});

  // Cancel subscription to channel `c1`:
  sub1.cancel();
}
```

Output:

```text
C1 EVENT> AsyncEvent[0#1@2022-08-14T16:15:10.526863Z]<t>{name: t1}
C2 EVENT> AsyncEvent[0#1@2022-08-14T16:15:10.538934Z]<t>{name: t2}
C2[b] EVENT> AsyncEvent[0#1@2022-08-14T16:15:10.538934Z]<t>{name: t2}
C2 EVENT> AsyncEvent[0#2@2022-08-14T16:15:10.544065Z]<t>{name: t3}
C2[b] EVENT> AsyncEvent[0#2@2022-08-14T16:15:10.544065Z]<t>{name: t3}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gmpassos/async_events/issues

## Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

Dart free & open-source [license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).
