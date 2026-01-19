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
    // We need a Scaffold here because this screen is pushed via Navigator.push
    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
      ),
      body: ResponsiveLayout(
        mobileBody: ChatView(title: patientName, threadId: threadId),
        // Removed ConstrainedBox/Center to match the Patient side and fill the screen
        desktopBody: ChatView(title: patientName, threadId: threadId),
      ),
    );
  }
}
