import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `showDatePicker` where Enter confirms, like clicking OK.
///
/// Flutter's calendar dialog ignores Enter, so after picking a day the user had
/// to reach for the mouse to hit OK. Use this for every single-date picker so
/// the keyboard behaves the same on every form.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  TransitionBuilder? builder,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (ctx, child) {
      final themed = builder == null ? child! : builder(ctx, child);
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): () => pressOk(ctx),
          const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
              pressOk(ctx),
        },
        child: Focus(autofocus: true, child: themed),
      );
    },
  );
}

/// Taps the dialog's OK button. The dialog keeps its selection private, so
/// the button itself is the one place that knows which day is picked.
void pressOk(BuildContext context) {
  final ok = MaterialLocalizations.of(context).okButtonLabel;
  var done = false;
  void visit(Element e) {
    if (done) return;
    final w = e.widget;
    if (w is TextButton && w.child is Text && (w.child as Text).data == ok) {
      w.onPressed?.call();
      done = true;
      return;
    }
    e.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
}
