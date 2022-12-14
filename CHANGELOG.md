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
