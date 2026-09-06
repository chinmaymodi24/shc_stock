import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The app's typeahead field, used by every "type a name, pick a record" input
// (product lines on Add Purchase/Add Sale, the client/consignee field on both).
//
// This exists instead of the framework's `Autocomplete` because that widget
// always anchors its suggestion list BELOW the field, with no way to flip it.
// That's fine on web, where there's no keyboard — but on a phone these fields
// sit in a long scrolling form, and focusing one scrolls it up to sit right
// above the soft keyboard. `Autocomplete` then renders the list directly under
// the field, i.e. behind the keyboard: present, but invisible. Web showed
// suggestions, mobile silently didn't.
//
// So this manages its own [OverlayEntry] and picks above-or-below from the
// field's real on-screen position and the keyboard's height, the way a native
// combobox would — while keeping the arrow-key/Enter navigation `Autocomplete`
// gave the web forms.
// ─────────────────────────────────────────────────────────────────────────────
class OverlayAutocompleteField<T extends Object> extends StatefulWidget {
  /// Text the field starts with (an existing row being edited).
  final String initialValue;

  /// Matches for what's been typed. Called on every keystroke; return an
  /// empty list to close the dropdown.
  final List<T> Function(String query) optionsFor;

  /// What gets written into the field once [option] is chosen.
  final String Function(T option) displayStringFor;

  final ValueChanged<T> onSelected;

  /// One row of the dropdown. [highlighted] is true for the row the arrow
  /// keys have landed on, so callers can tint it.
  final Widget Function(BuildContext context, T option, bool highlighted)
  optionBuilder;

  final InputDecoration decoration;
  final TextStyle? textStyle;
  final AppThemeColors colors;

  /// Tallest the dropdown may get; it shrinks further when the space between
  /// the field and the keyboard (or the screen edge) is tighter than this.
  final double maxDropdownHeight;

  const OverlayAutocompleteField({
    super.key,
    required this.initialValue,
    required this.optionsFor,
    required this.displayStringFor,
    required this.onSelected,
    required this.optionBuilder,
    required this.decoration,
    required this.colors,
    this.textStyle,
    this.maxDropdownHeight = 260,
  });

  @override
  State<OverlayAutocompleteField<T>> createState() =>
      _OverlayAutocompleteFieldState<T>();
}

class _OverlayAutocompleteFieldState<T extends Object>
    extends State<OverlayAutocompleteField<T>> {
  final _layerLink = LayerLink();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late final TextEditingController _controller;

  /// Groups the field's own tap region with the overlay's, so a mouse click
  /// on a suggestion doesn't count as "outside" the field. Without this,
  /// `TextField`'s default on-tap-outside handling unfocuses on pointer
  /// *down* — before the InkWell's tap-up fires — which tears the overlay
  /// down (via `_onFocusChange`) mid-click. Enter/arrow-key selection never
  /// hit this because it never touches focus.
  final Object _tapRegionGroupId = Object();

  OverlayEntry? _overlayEntry;
  List<T> _options = const [];

  /// Which row the arrow keys are on. Lives in a notifier so moving the
  /// highlight repaints only the dropdown, not the whole form behind it.
  final _highlighted = ValueNotifier<int>(0);

  static const double _minDropdownHeight = 80;
  static const double _fieldGap = 4;

  /// Below this much free space under the field, the dropdown flips above it
  /// — that's the keyboard-is-covering-it case.
  static const double _flipThreshold = 120;

  static const double _rowHeightEstimate = 48;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _highlighted.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _onTextChange();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChange() {
    final query = _controller.text.trim();
    if (query.isEmpty || !_focusNode.hasFocus) {
      _options = const [];
      _removeOverlay();
      return;
    }
    _options = widget.optionsFor(query);
    _highlighted.value = 0;
    if (_options.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _select(T option) {
    // Detach the listener before writing the chosen text: `.text =` fires it
    // synchronously, and with focus still held it would recompute options for
    // the now-selected name and reopen the dropdown a beat before the lines
    // below close it for good.
    _controller.removeListener(_onTextChange);
    _controller.text = widget.displayStringFor(option);
    _controller.addListener(_onTextChange);
    _removeOverlay();
    _focusNode.unfocus();
    widget.onSelected(option);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Arrow keys move the highlight, Enter takes it, Escape closes — the
  /// keyboard handling the web forms had from `Autocomplete`, kept because
  /// these forms are filled in fast without touching the mouse.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_overlayEntry == null || _options.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveHighlight(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveHighlight(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _select(_options[_highlighted.value.clamp(0, _options.length - 1)]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        _removeOverlay();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveHighlight(int delta) {
    final next = (_highlighted.value + delta).clamp(0, _options.length - 1);
    _highlighted.value = next;
    // Keep the highlighted row on screen as it walks past the visible window.
    if (_scrollController.hasClients) {
      final target = (next * _rowHeightEstimate).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  /// Rebuilt from scratch on every text change rather than patched in place,
  /// which is what keeps the above/below decision in step with the keyboard
  /// opening mid-type.
  void _showOverlay() {
    _removeOverlay();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final fieldSize = box.size;
    final fieldTopLeft = box.localToGlobal(Offset.zero);

    // Built straight from the platform view, not `MediaQuery.of(context)`:
    // an ancestor `Scaffold` resizes its body to make room for the keyboard
    // and then hands that body a MediaQuery with `viewInsets.bottom` zeroed
    // out again, considering the inset already accounted for. Reading the
    // local MediaQuery here would always see "no keyboard" — exactly backwards
    // for a field that needs to know whether the keyboard is about to cover it.
    final rawMedia = MediaQueryData.fromView(View.of(context));
    final visibleBottom = rawMedia.size.height - rawMedia.viewInsets.bottom;

    final spaceBelow = visibleBottom - (fieldTopLeft.dy + fieldSize.height);
    final spaceAbove = fieldTopLeft.dy;
    final showAbove = spaceBelow < _flipThreshold && spaceAbove > spaceBelow;

    final available = (showAbove ? spaceAbove : spaceBelow) - _fieldGap - 8;
    final dropdownHeight = math.max(
      math.min(widget.maxDropdownHeight, available),
      math.min(_minDropdownHeight, available),
    );
    if (dropdownHeight <= 0) return;

    final colors = widget.colors;
    final options = _options;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        width: fieldSize.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: showAbove ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(0, showAbove ? -_fieldGap : _fieldGap),
          child: TapRegion(
            groupId: _tapRegionGroupId,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: colors.surface,
              child: Container(
                constraints: BoxConstraints(maxHeight: dropdownHeight),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: _highlighted,
                  builder: (context, highlighted, _) => ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) => InkWell(
                      // Never take focus: without this a tap on a suggestion
                      // could pull focus off the field, whose focus-lost handler
                      // tears down this very overlay before onTap ever runs.
                      canRequestFocus: false,
                      onTap: () => _select(options[index]),
                      child: widget.optionBuilder(
                        context,
                        options[index],
                        index == highlighted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onKeyEvent: _onKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          groupId: _tapRegionGroupId,
          style: widget.textStyle,
          decoration: widget.decoration,
        ),
      ),
    );
  }
}
