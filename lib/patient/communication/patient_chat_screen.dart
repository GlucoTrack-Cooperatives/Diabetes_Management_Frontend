import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/chat_view.dart';
import '../../utils/responsive_layout.dart';
import 'chat_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PatientChatScreen extends ConsumerWidget {
  const PatientChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return threadsAsync.when(
      data: (threads) {
        if (threads.isEmpty) {
          return const Center(child: Text("No chat thread found with your physician."));
        }

        // Assuming the patient has only one primary physician thread
        final mainThread = threads.first;

        return ResponsiveLayout(
          mobileBody: _PatientChatBody(
              threadId: mainThread.id,
              physicianName: mainThread.physicianName
          ),
          // Removed ConstrainedBox and Center to allow chat to fill the available space
          desktopBody: _PatientChatBody(
              threadId: mainThread.id,
              physicianName: mainThread.physicianName
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _PatientChatBody extends StatelessWidget {
  final String threadId;
  final String physicianName;

  const _PatientChatBody({required this.threadId, required this.physicianName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ChatView(
            title: "Dr. $physicianName",
            threadId: threadId,
          ),
        ),
      ],
    );
  }
}


