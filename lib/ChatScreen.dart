import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUser;

  ChatScreen({required this.chatId, required this.otherUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController msgCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  void sendMessage() async {
    if (msgCtrl.text.trim().isEmpty) return;

    final current = FirebaseAuth.instance.currentUser!.email!;
    final db = FirebaseDatabase.instance.ref("chats/${widget.chatId}/messages");

    await db.push().set({
      'sender': current,
      'message': msgCtrl.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    msgCtrl.clear();

    Future.delayed(Duration(milliseconds: 300), () {
      scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.otherUser.split('@').first}"),
        backgroundColor: Color(0xff325832),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref("chats/${widget.chatId}/messages")
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return Center(child: Text("No messages yet"));
                }

                final data = snapshot.data!.snapshot.value as Map;
                final msgs = data.entries.toList()
                  ..sort(
                    (a, b) =>
                        a.value['timestamp'].compareTo(b.value['timestamp']),
                  );

                return ListView.builder(
                  controller: scrollCtrl,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final msg = msgs[index].value as Map;
                    final isMe =
                        msg['sender'] ==
                        FirebaseAuth.instance.currentUser!.email;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['message']),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // -------- SEND MESSAGE -------
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
