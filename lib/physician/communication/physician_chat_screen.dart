import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PhysicianChatScreen extends StatelessWidget {
  const PhysicianChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The Scaffold is provided by PhysicianMainScreen
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _MessageList(),
    );
  }
}

class _MessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messages = [
      {
        'name': 'John Doe',
        'message': 'Dr., I had a severe low last night and used glucagon...',
        'time': '10:30 AM',
        'isUnread': true,
      },
      {
        'name': 'Alice Smith',
        'message': 'Thanks for the adjustments. My morning numbers are better.',
        'time': 'Yesterday',
        'isUnread': false,
      },
      {
        'name': 'Robert Johnson',
        'message': 'Can we reschedule our appointment?',
        'time': 'Mon',
        'isUnread': false,
      },
    ];

    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isUnread = msg['isUnread'] as bool;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              (msg['name'] as String)[0],
              style: TextStyle(color: Colors.white),
            ),
          ),
          title: Text(msg['name'] as String, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(
            msg['message'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyText2,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(msg['time'] as String, style: AppTextStyles.bodyText2),
              if (isUnread) ...[
                SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            // Navigate to individual chat thread
          },
        );
      },
    );
  }
}
