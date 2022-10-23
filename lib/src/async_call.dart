import 'dart:async';
import 'dart:collection';

import 'package:async_events/async_events.dart';
import 'package:logging/logging.dart' as logging;

import 'async_events_base.dart';

final _logAsyncCall = logging.Logger('AsyncCall');

/// An async call handler with retry support.
mixin AsyncCaller {
  /// The default retry interval.
  Duration get retryInterval => const Duration(seconds: 1);

  final ListQueue<AsyncCall> _calling = ListQueue<AsyncCall>(4);

  List<AsyncCall> get calls => UnmodifiableListView<AsyncCall>(_calling);

  /// Performs an async call with retry support.
  FutureOr<R> call<R>(FutureOr<R> Function() call,
      {R? errorValue,
      bool nullErrorValue = false,
      String? errorMessage,
      String? methodName,
      int maxRetries = 0,
      Duration? retryInterval}) {
    var asyncCall = AsyncCall(methodName, call, errorValue, nullErrorValue,
        errorMessage, maxRetries, retryInterval ?? this.retryInterval);

    _calling.add(asyncCall);

    try {
      var ret = call();

      if (asyncCall.isCanceled) {
        return _callReturn(asyncCall, withError: true);
      }

      if (ret is Future<R>) {
        return ret.then((r) {
          if (asyncCall.isCanceled) {
            return _callReturn(asyncCall, withError: true);
          }

          _calling.remove(asyncCall);
          return r;
        }, onError: (e, s) => _callRetry(asyncCall, e, s));
      } else {
        _calling.remove(asyncCall);
        return ret;
      }
    } catch (e, s) {
      return _callRetry(asyncCall, e, s);
    }
  }

  Future<R> _callRetry<R>(
      AsyncCall<R> asyncCall, Object error, StackTrace stackTrace) async {
    asyncCall.error = error;
    asyncCall.stackTrace = stackTrace;

    if (asyncCall.maxRetries < 1) {
      return _callReturn(asyncCall, withError: true);
    }

    _logAsyncCall.warning(
        "Error calling method `${asyncCall.methodName}`. Retrying (${asyncCall.maxRetries}) call. Error: $error");

    final retryIntervalMs = asyncCall.retryInterval.inMilliseconds;
    final maxRetries = asyncCall.maxRetries;

    for (var i = 0; i < maxRetries; ++i) {
      var intervalMs = _calcInterval(i, retryIntervalMs);

      await Future.delayed(Duration(milliseconds: intervalMs));

      try {
        var ret = await asyncCall.call();
        return _callReturn(asyncCall, returnValue: ret)!;
      } catch (e, s) {
        error = e;
        stackTrace = s;
      }
    }

    return _callReturn(asyncCall, withError: true);
  }

  R _callReturn<R>(AsyncCall<R> asyncCall,
      {bool withError = false, R? returnValue}) {
    _calling.remove(asyncCall);

    if (asyncCall.isCanceled) {
      asyncCall.error ??=
          StateError("Call to `${asyncCall.methodName}` canceled!");
      withError = true;
    }

    if (withError) {
      if (asyncCall.nullErrorValue) return null as R;

      var errorValue = asyncCall.errorValue;
      if (errorValue != null) return errorValue;

      var stackTrace = asyncCall.stackTrace;

      if (stackTrace == null) {
        var error = asyncCall.error;
        if (error is Error) {
          stackTrace = error.stackTrace;
        }
      }

      stackTrace ??= StackTrace.current;

      var eventError =
          AsyncEventError.from(asyncCall.errorMessage, asyncCall.error);

      Error.throwWithStackTrace(eventError, stackTrace);
    } else {
      return returnValue as R;
    }
  }

  int _calcInterval(final int i, final int retryIntervalMs) {
    int intervalMs;
    if (i == 0) {
      intervalMs = retryIntervalMs ~/ 2;
    } else {
      var r = 1 + (0.20 * (i - 1));
      intervalMs = (retryIntervalMs * r).toInt();
    }

    intervalMs = intervalMs.clamp(1, retryIntervalMs * 3);
    return intervalMs;
  }
}

class AsyncCall<R> {
  static int _idCount = 0;

  final int id = ++_idCount;

  final String? _methodName;

  final FutureOr<R> Function() call;

  final R? errorValue;
  final bool nullErrorValue;

  final String? _errorMessage;

  final int maxRetries;
  final Duration retryInterval;

  Object? error;
  StackTrace? stackTrace;

  AsyncCall(this._methodName, this.call, this.errorValue, this.nullErrorValue,
      this._errorMessage, int maxRetries, Duration retryInterval)
      : maxRetries = maxRetries < 0 ? 0 : maxRetries,
        retryInterval = retryInterval.inMilliseconds < 1
            ? const Duration(milliseconds: 1)
            : retryInterval;

  String? get errorMessage =>
      _errorMessage ??
      (_methodName != null ? "Error calling `$methodName`" : null);

  String get methodName => _methodName ?? '?';

  bool _canceled = false;

  bool get isCanceled => _canceled;

  void cancel() => _canceled = true;

  @override
  String toString() {
    return '_Call{id: $id, methodName: $methodName, _canceled: $_canceled}';
  }
}
