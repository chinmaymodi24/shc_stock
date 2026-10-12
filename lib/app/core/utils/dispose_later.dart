import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// How long a closed page can still be on screen: GetX's exit transition
/// plus the frames the keyboard takes to close.
const Duration kPageExitGrace = Duration(milliseconds: 800);

/// Disposes a page controller's text controllers (and other notifiers) only
/// once the page has really gone.
///
/// GetX calls `onClose` as soon as a route is replaced — while the old page is
/// still drawn for its exit transition, and while the keyboard is closing,
/// which rebuilds it. Disposing the text controllers right there made the
/// field that still had focus use a disposed controller ("A
/// TextEditingController was used after being disposed"), and the app showed
/// a red error screen after Save. So: drop the focus now, and dispose once
/// [kPageExitGrace] of frames has gone by.
///
/// Counted in frames rather than with a Timer, so a widget test that ends
/// mid-way is not left with a pending timer.
void disposeAfterPageExit(Iterable<ChangeNotifier> notifiers) {
  FocusManager.instance.primaryFocus?.unfocus();
  final pending = notifiers.toList();
  if (pending.isEmpty) return;
  final binding = SchedulerBinding.instance;
  Duration? start;

  void onFrame(Duration timeStamp) {
    start ??= timeStamp;
    if (timeStamp - start! >= kPageExitGrace) {
      for (final n in pending) {
        n.dispose();
      }
      return;
    }
    binding.addPostFrameCallback(onFrame);
    binding.scheduleFrame();
  }

  binding.addPostFrameCallback(onFrame);
  binding.scheduleFrame();
}
