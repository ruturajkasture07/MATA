import 'package:flutter/material.dart';
import '../services/narrator_service.dart';

class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback? onActivate;
  final bool autofocus;

  const AccessibleWidget({
    super.key,
    required this.child,
    required this.label,
    this.onActivate,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        NarratorService().speak(label);
      },
      onDoubleTap: onActivate,
      behavior: HitTestBehavior.translucent,
        child: Semantics(
          label: label,
          button: onActivate != null,
          child: Focus(
            autofocus: autofocus,
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                NarratorService().speak(label);
              }
            },
            child: child,
          ),
        ),
    );
  }
}
