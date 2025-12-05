import 'dart:math';
import 'package:card_swiper/card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:passiton/chat_list_screen.dart';
import 'package:passiton/login.dart';
import 'package:passiton/ChatScreen.dart';
import 'package:passiton/profile.dart';
import 'package:passiton/upload.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  String searchQuery = '';
  double myLatitude = 0.0;
  double myLongitude = 0.0;
  bool searchPressed = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  sendNotification(String msg, String title, String recipient) async {
    final ref = FirebaseDatabase.instance.ref('notifications');

    final snapshot = await ref.get();

    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final data = child.value as Map;

        if (data['recipient'] == recipient && data['message'] == msg) {
          print("Duplicate notification detected. Not sending.");
          return;
        }
      }
    }
    await ref.push().set({
      'recipient': recipient,
      'sender': FirebaseAuth.instance.currentUser?.email ?? '',
      'title': title,
      'message': msg,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    print("Notification sent successfully ✔️");
  }

  // ---------------- GET CURRENT LOCATION ----------------
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() {
        myLatitude = 0.0;
        myLongitude = 0.0;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      myLatitude = position.latitude;
      myLongitude = position.longitude;
    });
  }

  // ---------------- DISTANCE CALCULATION ----------------
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  // ---------------- FETCH POSTS (using definitions) ----------------
  Future<List<Map<String, dynamic>>> getPosts() async {
    final snapshot = await FirebaseDatabase.instance.ref('items').get();
    if (!snapshot.exists) return [];

    final allData = Map<String, dynamic>.from(snapshot.value as Map);
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    // Extract query words (cleaned)
    List<String> queryWords = [];
    if (searchPressed && searchQuery.isNotEmpty) {
      queryWords = searchQuery
          .split(RegExp(r'\s+'))
          .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''))
          .where((w) => w.length > 2)
          .toList();
    }

    final itemsWithDistance = allData.entries
        .where((entry) => (entry.value as Map)['owner'] != currentUserEmail)
        .map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          final lat = (data['latitude'] ?? 0.0).toDouble();
          final lon = (data['longitude'] ?? 0.0).toDouble();

          data['distance'] = calculateDistance(
            myLatitude,
            myLongitude,
            lat,
            lon,
          );
          data['key'] = entry.key;

          if (searchPressed && searchQuery.isNotEmpty) {
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '')
                .toString()
                .toLowerCase();
            final storedDefinitions = (data['meanings'] ?? [])
                .map((e) => e.toString().toLowerCase())
                .join(' ');

            final combinedText = "$title $description $storedDefinitions";
            int keywordMatches = 0;

            for (var q in queryWords) {
              if (combinedText.contains(q)) {
                keywordMatches++;
              }
            }
            data['score'] = keywordMatches.toDouble();
          } else {
            data['score'] = 0.0;
          }

          return data;
        })
        .toList();

    if (searchPressed && searchQuery.isNotEmpty) {
      // Sort by relevance score
      itemsWithDistance.sort((a, b) => b['score'].compareTo(a['score']));
    } else {
      // Sort by distance normally
      itemsWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));
    }

    return itemsWithDistance;
  }

  Widget CardLayout({required Map<String, dynamic> post}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post['imageUrl'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  post['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height * 0.50,
                ),
              ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    post['description'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 5),

                  // Price and Distance Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.sell_outlined,
                            size: 18,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "RS ${post['price'] ?? 0}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${post['distance']?.toStringAsFixed(1) ?? '0.0'} km",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${post['owner'].split('@').first ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepOrange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ButtonStyle(
                          fixedSize: WidgetStatePropertyAll<Size>(
                            Size(130, 40),
                          ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            const Color(0xff325832),
                          ),
                        ),
                        icon: Icon(Icons.money, color: Colors.white, size: 20),
                        label: Text(
                          'Buy',
                          style: TextStyle(color: Colors.white, fontSize: 21),
                        ),
                        onPressed: () {
                          var email = post['owner'].split('@').first ?? '';
                          sendNotification(
                            "$email  is interested in buying your item: ${post['title']}",
                            "Buy Request",
                            post['owner'] ?? '',
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        style: ButtonStyle(
                          fixedSize: WidgetStatePropertyAll<Size>(
                            Size(130, 40),
                          ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            const Color(0xff325832),
                          ),
                        ),
                        icon: Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          'Swap',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        onPressed: () {
                          var email = post['owner'].split('@').first ?? '';
                          sendNotification(
                            "$email is interested in swapping for your item: ${post['title']}",
                            "Swap Request",
                            post['owner'] ?? '',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteNotification(String id) {
    FirebaseDatabase.instance.ref('notifications/$id').remove();
  }

  void _openNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    "Notifications",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance
                          .ref('notifications')
                          .onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final data =
                            snapshot.data!.snapshot.value
                                as Map<dynamic, dynamic>?;

                        if (data == null || data.isEmpty) {
                          return const Center(child: Text("No notifications."));
                        }

                        final notifications = data.entries.toList()
                          ..sort(
                            (a, b) => (b.value['timestamp'] as int).compareTo(
                              a.value['timestamp'] as int,
                            ),
                          ); // latest first

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final key = notifications[index].key;
                            final notif = Map<String, dynamic>.from(
                              notifications[index].value,
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ---- Left icon ----
                                    Icon(
                                      Icons.notifications,
                                      size: 32,
                                      color: Colors.blueGrey,
                                    ),

                                    const SizedBox(width: 12),

                                    // ---- Text Column ----
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif['title'] ?? "No Title",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif['message'] ?? "",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ---- Chat + Delete Buttons ----
                                    Column(
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              Chat(notif['sender']),
                                          icon: Icon(
                                            Icons.chat_bubble,
                                            color: Colors.blue,
                                          ),
                                          tooltip: "Chat",
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _deleteNotification(key),
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          tooltip: "Delete",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe8f5e9),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.recycling_rounded, color: Color(0xff325832)),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Get.to(() => const Profile()),
            ),

            ListTile(
              leading: Icon(Icons.add),
              title: const Text('Upload Item'),
              onTap: () => Get.to(() => const Upload()),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text("Chats"),
              onTap: () => Get.to(() => ChatListScreen()),
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => const Login());
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff325832),
        child: const Icon(Icons.notifications, color: Colors.white),
        onPressed: () {
          _openNotificationsPanel();
        },
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xff325832),
        elevation: 1,
        title: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search items...',

                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: (value) => searchQuery = value,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() => searchPressed = true);
              },
            ),
          ],
        ),
        toolbarHeight: 60,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No posts available."));
          }

          final posts = snapshot.data!;

          // --- NORMAL MODE (no search) ---
          if (!searchPressed || searchQuery.isEmpty) {
            return Swiper(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return CardLayout(post: post);
              },
              layout: SwiperLayout.TINDER,
              itemWidth: double.infinity,
              itemHeight: double.infinity,
            );
          }

          // --- SEARCH MODE (definition matching) ---
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return CardLayout(post: post);
            },
          );
        },
      ),
    );
  }

  void Chat(String otherEmail) async {
    final currentEmail = FirebaseAuth.instance.currentUser!.email!;

    final safe1 = safeEmail(currentEmail);
    final safe2 = safeEmail(otherEmail);

    // consistent chat id
    final chatId = (safe1.compareTo(safe2) < 0)
        ? "${safe1}_${safe2}"
        : "${safe2}_${safe1}";

    final chatRef = FirebaseDatabase.instance.ref("chats/$chatId");

    // Create chat document if missing
    final snap = await chatRef.get();
    if (!snap.exists) {
      await chatRef.set({
        "sender": currentEmail,
        "receiver": otherEmail,
        "createdAt": DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Navigate
    Get.to(() => ChatScreen(chatId: chatId, otherUser: otherEmail));
  }

  String safeEmail(String email) {
    return email
        .replaceAll('.', '_dot_')
        .replaceAll('@', '_at_')
        .replaceAll('\$', '_dollar_')
        .replaceAll('#', '_hash_')
        .replaceAll('[', '_lb_')
        .replaceAll(']', '_rb_');
  }
}
