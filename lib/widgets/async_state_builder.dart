import 'package:flutter/material.dart';
import 'premium_error_state.dart';
import 'premium_skeleton_loader.dart';

class AsyncStateBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) onData;
  final Widget Function()? onLoading;
  final Widget Function(Object error)? onError;
  final Widget Function()? onEmpty;
  final bool Function(T data)? isEmpty;

  const AsyncStateBuilder({
    required this.snapshot,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.isEmpty,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return onError?.call(snapshot.error!) ?? PremiumErrorState(
        severity: ErrorSeverity.critical,
        title: "Something went wrong",
        message: "Please try again.",
      );
    }
    if (!snapshot.hasData) {
      return onLoading?.call() ?? const PremiumSkeletonLoader();
    }
    if (isEmpty?.call(snapshot.data as T) ?? false) {
      return onEmpty?.call() ?? const SizedBox.shrink();
    }
    return onData(snapshot.data as T);
  }
}
