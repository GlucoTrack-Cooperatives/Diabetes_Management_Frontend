import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final double? width;
  final double? height;

  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.width,
    this.height,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  @override
  Widget build(BuildContext context) {
    // 1. Create the button
    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // Use minimumSize to enforce height (50 is larger than default)
        // If width is provided, use it; otherwise allow it to be flexible.
        minimumSize: Size(width ?? 0, height ?? 50),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child ?? Text(text!, style: const TextStyle(fontSize: 16)),
    );

    // 2. If a specific width is provided, we need to wrap the button
    // to stop it from stretching if the parent (like a Column) forces it to.
    if (width != null) {
      return UnconstrainedBox(
        child: SizedBox(
            width: width,
            height: height ?? 20,
            child: button
        ),
      );
    }

    // 3. If no width is provided, return the button directly (it will fill space if parent says so)
    return button;
  }
}
