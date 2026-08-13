import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';
import 'theme_ripple_controller.dart';

/// Switches the app's theme with the full-screen circular-reveal ripple,
/// starting from wherever [context]'s widget is on screen. Drop-in
/// replacement for `Get.find<ThemeController>().setTheme(mode)` at any
/// theme-toggle tap site.
void switchThemeWithRipple(BuildContext context, ThemeMode mode) {
  final tc = Get.find<ThemeController>();
  final box = context.findRenderObject();
  final Offset origin;
  if (box is RenderBox && box.attached) {
    origin = box.localToGlobal(box.size.center(Offset.zero));
  } else {
    final size = MediaQuery.of(context).size;
    origin = Offset(size.width / 2, size.height / 2);
  }
  Get.find<ThemeRippleController>().trigger(
    globalPosition: origin,
    applyTheme: () => tc.setTheme(mode),
  );
}
