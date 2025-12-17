import 'package:flutter/material.dart';

class PhysicianChatScreen extends StatelessWidget {
  const PhysicianChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Physician Chat'),
      ),
      body: Center(
        child: Text('Physician Chat Content Goes Here'),
      ),
    );
  }
}
