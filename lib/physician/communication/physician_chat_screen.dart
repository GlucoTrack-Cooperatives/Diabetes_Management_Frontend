import 'package:diabetes_management_system/physician/patient_analysis/patient_analysis_screen.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../widgets/chat_view.dart';
import '../../utils/responsive_layout.dart';

class PhysicianChatScreen extends StatelessWidget {
  final String threadId;
  final String patientName;
  final String patientId;

  const PhysicianChatScreen({
    super.key,
    required this.threadId,
    required this.patientName,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 2. Wrap the title in an InkWell (or GestureDetector)
        title: InkWell(
          onTap: () {
            // 3. Navigate to Patient Analysis Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientAnalysisScreen(
                  patientId: patientId,
                  patientName: patientName,
                ),
              ),
            );
          },
          // Added a Row to show a small icon indicating it's clickable
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                patientName,
                style: AppTextStyles.headline2.copyWith(fontSize: 18),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8), // Extra padding for touch target
            ],
          ),
        ),
      ),
      body: ResponsiveLayout(
        mobileBody: ChatView(title: patientName, threadId: threadId),
        desktopBody: ChatView(title: patientName, threadId: threadId),
      ),
    );
  }
}
