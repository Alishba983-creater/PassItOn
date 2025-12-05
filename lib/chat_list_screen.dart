import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:passiton/ChatScreen.dart';

class ChatListScreen extends StatelessWidget {
  final current = FirebaseAuth.instance.currentUser!.email!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Chats"),
        backgroundColor: Color(0xff325832),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('chats').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return Center(child: Text("No chats yet"));
          }

          final data = snapshot.data!.snapshot.value as Map;
          final chats = data.entries.where((e) {
            final c = e.value as Map;
            return c['sender'] == current || c['receiver'] == current;
          }).toList();

          if (chats.isEmpty) return Center(child: Text("No chats"));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final c = chat.value as Map;

              final otherUser =
                  c['sender'] == current ? c['receiver'] : c['sender'];

              return ListTile(
                leading: Icon(Icons.chat_bubble_outline),
                title: Text(otherUser),
                onTap: () {
                  Get.to(() => ChatScreen(
                        chatId: chat.key,
                        otherUser: otherUser,
                      ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
