import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('items');
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<Map?> getUserPosts() async {
    final snapshot = await _dbRef.get();
    if (!snapshot.exists) return null;

    final allData = Map<String, dynamic>.from(snapshot.value as Map);
    final userEmail = currentUser?.email;

    final userPosts = allData.entries
        .where((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          return data['owner'] == userEmail;
        })
        .map((e) => MapEntry(e.key, e.value))
        .toList();

    return Map.fromEntries(userPosts);
  }

  Future<String?> getLocationName(double latitude, double longitude) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'PassItOn/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'];
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  void _delete(String id) async {
    try {
      await _dbRef.child(id).remove();
      setState(() {});
      Get.snackbar(
        "Success",
        "Item deleted successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: const Color(0xff1e3d1e),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete item: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  String getUsername() {
    final email = currentUser?.email ?? 'User';
    return email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final username = getUsername();
    return Scaffold(
      backgroundColor: const Color(0xffe8f5e9),
      appBar: AppBar(backgroundColor: const Color(0xff1b5e20)),
      body: Column(
        children: [
          Container(
            width: double.infinity,

            color: const Color(0xff1b5e20),

            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xff1b5e20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // --- Posts List ---
          Expanded(
            child: FutureBuilder<Map?>(
              future: getUserPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xff4caf50)),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'You have not posted anything yet.',
                      style: TextStyle(fontSize: 16, color: Color(0xff486f48)),
                    ),
                  );
                }

                final items = snapshot.data!.entries.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final data = Map<String, dynamic>.from(items[index].value);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Image Section ---
                          if (data['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: Image.network(
                                data['imageUrl'],
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.cover,
                              ),
                            ),

                          // --- Post Details ---
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? 'Untitled Post',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Color(0xff1e3d1e),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['description'] ?? '',
                                  style: const TextStyle(
                                    color: Color(0xff2e5f2e),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Price: \$${data['price'] ?? 0.0}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff486f48),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FutureBuilder<String?>(
                                  future: getLocationName(
                                    (data['latitude'] ?? 0.0).toDouble(),
                                    (data['longitude'] ?? 0.0).toDouble(),
                                  ),
                                  builder: (context, locSnapshot) {
                                    if (locSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                        'Locating...',
                                        style: TextStyle(
                                          color: Color(0xff486f48),
                                        ),
                                      );
                                    } else if (!locSnapshot.hasData ||
                                        locSnapshot.data == null) {
                                      return const Text(
                                        'Location unavailable',
                                        style: TextStyle(
                                          color: Color(0xff486f48),
                                        ),
                                      );
                                    } else {
                                      return Text(
                                        locSnapshot.data!,
                                        style: const TextStyle(
                                          color: Color(0xff486f48),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Posted on: ${data['createdAt'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _delete(items[index].key),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
  }
}
