import 'dart:async';
import 'package:flutter/widgets.dart';

/// Tracks StreamSubscriptions to prevent leaks.
mixin StreamDisposer<T extends StatefulWidget> on State<T> {
  final _subs = <StreamSubscription>[];

  void track(StreamSubscription sub) => _subs.add(sub);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}


