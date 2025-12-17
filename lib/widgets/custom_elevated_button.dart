import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;

  const CustomElevatedButton({
    Key? key,
    required this.onPressed,
    this.text,
    this.child,
  }) : assert(text != null || child != null, 'Either text or child must be provided'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: child ?? Text(text!),
    );
  }
}
