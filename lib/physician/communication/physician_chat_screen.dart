import 'package:flutter/material.dart';
import '../../widgets/chat_view.dart';
import '../../utils/responsive_layout.dart';

class PhysicianChatScreen extends StatelessWidget {
  final String threadId;
  final String patientName;

  const PhysicianChatScreen({
    super.key,
    required this.threadId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: ChatView(title: patientName, threadId: threadId),
      desktopBody: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ChatView(title: patientName, threadId: threadId),
        ),
      ),
    );
  }
}
