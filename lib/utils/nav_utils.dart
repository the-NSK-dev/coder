import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Consistent back navigation: pop when possible, otherwise go to fallback route.
void popOrGo(BuildContext context, {String fallback = '/main'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
