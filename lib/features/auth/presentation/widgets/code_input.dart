import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_tokens.dart';

/// One-time-code input shared by the sign-up verification and the password
/// recovery screens.
///
/// Supabase can be configured to send anywhere from 6 to 8 digits, so the
/// input renders [maxLength] boxes and lets the parent decide when a partial
/// code is submittable via [CodeInputState.code]: [onCompleted] fires once
/// the full [maxLength] digits land (auto-submit), while shorter codes go
/// through an explicit button.
///
/// A single hidden [TextField] drives the boxes, so typing, keyboard paste,
/// and one-time-code autofill all work. Set [error] to colour the boxes red
/// and shake them; call [CodeInputState.clear] to wipe the digits and refocus.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.error,
    this.enabled = true,
    this.maxLength = 8,
  }) : assert(maxLength >= 6);

  /// Shortest code the parent will accept on an explicit submit.
  static const minLength = 6;

  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final String? error;
  final bool enabled;

  /// Box count and the length at which [onCompleted] fires.
  final int maxLength;

  @override
  State<CodeInput> createState() => CodeInputState();
}

class CodeInputState extends State<CodeInput>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refreshBoxes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(CodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != oldWidget.error && widget.error != null) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_refreshBoxes);
    _focusNode.dispose();
    _controller.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _refreshBoxes() => setState(() {});

  /// Wipes the digits and returns focus for the next attempt.
  void clear() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  /// The digits entered so far.
  String get code => _controller.text;

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.maxLength) widget.onCompleted(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final digits = _controller.text;
    final focused = _focusNode.hasFocus;
    final activeIndex = digits.length >= widget.maxLength
        ? widget.maxLength - 1
        : digits.length;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final offset = math.sin(t * math.pi * 6) * (1 - t) * 8;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: SizedBox(
        height: 58,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < widget.maxLength; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.error != null
                              ? scheme.error
                              : focused && i == activeIndex
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: focused && i == activeIndex ? 1.6 : 1,
                        ),
                      ),
                      child: Text(
                        i < digits.length ? digits[i] : '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Positioned.fill(
              child: TextField(
                key: const ValueKey('otp-field'),
                controller: _controller,
                focusNode: _focusNode,
                readOnly: !widget.enabled,
                showCursor: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.maxLength),
                ],
                style: const TextStyle(
                  height: 58,
                  fontSize: 1,
                  color: Colors.transparent,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                onChanged: _onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
