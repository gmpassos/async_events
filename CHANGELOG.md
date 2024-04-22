## 1.2.0

- `AsyncEventID`: added `tryParse`.

- `AsyncEventHub`: added `purge`.

- `AsyncEventChannel`:
  - Added `purge`.
  - `submit`: added parameter `time`.

- `AsyncEventStorage`:
  - Rename `purge` to `purgeEpochs`.
  - Added `purgeEvents`.

- Fix channel initial synchronization when using `limit`.

## 1.1.1

- `AsyncEventChannel`, `AsyncEventStorage`:
  - `fetch`: added parameter `limit`.

- async_extension: ^1.2.12
- reflection_factory: ^2.3.4

## 1.1.0

- sdk: '>=3.0.0 <4.0.0'

- async_extension: ^1.2.5
- reflection_factory: ^2.3.0
- logging: ^1.2.0

- lints: ^3.0.0
- build_runner: ^2.4.8
- dependency_validator: ^3.2.3
- test: ^1.25.2

## 1.0.12

- `AsyncEventChannel._onNewEvent`:
  - Fix call to `complete``: check if `!isCompleted`.
- sdk: '>=2.18.0 <4.0.0'
- async_extension: ^1.1.1
- collection: ^1.18.0
- reflection_factory: ^2.1.6
- test: ^1.24.3

## 1.0.11

- `AsyncEventChannel.pulling`: Fix behavior of `delay` parameter.

## 1.0.10

- sdk: '>=2.18.0 <3.0.0'
- async_extension: ^1.1.0
- reflection_factory: ^2.0.7
- test: ^1.24.1

## 1.0.9

- reflection_factory: ^2.0.0
- logging: ^1.1.1
- lints: ^2.0.1
- build_runner: ^2.3.3
- build_verify: ^3.1.0
- test: ^1.22.2

## 1.0.8

- Added `AsyncCaller`: expose call handler with retry support.
- `AsyncEventHub` and `AsyncEventStorageRemote`:
  - Added `cancelChannelCalls`.
- `AsyncEventPulling`: added `cancelPulling`.
- `AsyncEventSubscriptionGroup._flushSync`:
  - Fix possible stack overflow when flush is not using `Future`. 

## 1.0.7

- `AsyncEventStorageRemote`: log call error before retry attempt.
- reflection_factory: ^1.2.17

## 1.0.6

- Added `AsyncEventPulling.pull`.
- Add `AsyncEventError`.
- `AsyncEventStorageRemote`:
  - Added field `retryInterval`.
  - Retries of failed requests.

## 1.0.5

- `AsyncEventChannel`:
  - Added `fetchDelayed` and `waitNewEvent`.
- reflection_factory: ^1.2.13

## 1.0.4

- reflection_factory: ^1.2.12

## 1.0.3

- `AsyncEvent`:
  - Field `channelName`: `@JsonFieldAlias('channel')`

## 1.0.2

- `@EnableReflection()`: `AsyncEventID`, `AsyncEvent`.
- `AsyncEvent`:
  - `toJson`: `id` is a `String` now.
- Added `AsyncEventPulling`.
- `AsyncEventChannel`:
  - Improved event order sync. 
- reflection_factory: ^1.2.6
- build_runner: ^2.1.5
- build_verify: ^3.0.0

## 1.0.1

- Added `AsyncEventSubscriptionGroup`:
  - `AsyncEventSubscription` are now part of a group, to optimize multiple similar subscriptions.
  - Better synchronization and flush of unordered events.
- Added `AsyncEventStorageAsJSON` and `AsyncEventStorageFromJSON`:
  - Wrappers that help implementation of storage clients and servers.
- Added `AsyncEventStorageRemote`:
  - A remote storage.
  - Added `AsyncEventStorageClient`.
- Improved documentation.
- collection: ^1.16.0

## 1.0.0

- Initial version.
