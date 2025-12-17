import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:flutter/material.dart';

class PatientChatScreen extends StatelessWidget {
  const PatientChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The Scaffold is provided by PatientMainScreen
    return ResponsiveLayout(
      mobileBody: _ChatBody(),
      desktopBody: _DesktopChatBody(),
    );
  }
}

// For desktop, we can constrain the width for better readability
class _DesktopChatBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: _ChatBody(),
      ),
    );
  }
}

// The main content of the chat screen, shared by mobile and desktop
class _ChatBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _SystemAlertCard(),
            SizedBox(height: 16),
            _ChatThreadList(),
          ],
        ),
      ),
    );
  }
}

class _SystemAlertCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: ListTile(
        leading: Icon(Icons.error_outline, color: AppColors.error),
        title: Text('CRITICAL ALERT', style: AppTextStyles.bodyText1.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
        subtitle: Text('Your physician requires a check-in. Tap to view.', style: AppTextStyles.bodyText2.copyWith(color: AppColors.error)),
        onTap: () {},
      ),
    );
  }
}

class _ChatThreadList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock data for chat threads
    final List<Map<String, String>> mockThreads = [
      {'name': 'Dr. Evelyn Smith', 'message': 'Sounds good, let\'s review the new data tomorrow.', 'time': '2:45 PM'},
      {'name': 'System Alerts', 'message': 'Reminder: Your upcoming appointment is in 3 days.', 'time': 'Yesterday'},
      {'name': 'Support Team', 'message': 'We have resolved the issue with your account.', 'time': '3d ago'},
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: mockThreads.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text(mockThreads[index]['name']![0]), // First letter of name
            ),
            title: Text(mockThreads[index]['name']!, style: AppTextStyles.bodyText1),
            subtitle: Text(mockThreads[index]['message']!, style: AppTextStyles.bodyText2, overflow: TextOverflow.ellipsis),
            trailing: Text(mockThreads[index]['time']!, style: AppTextStyles.bodyText2),
            onTap: () {},
          );
        },
        separatorBuilder: (context, index) => Divider(height: 1),
      ),
    );
  }
}
