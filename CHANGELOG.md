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
