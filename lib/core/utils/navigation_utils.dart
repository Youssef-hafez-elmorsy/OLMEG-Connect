import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void closeOrGo(BuildContext context, {String fallback = '/home'}) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  context.go(fallback);
}
