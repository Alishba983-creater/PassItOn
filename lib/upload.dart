import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;
  Position? _currentPosition;
  File? _pickedImage;
  Uint8List? _webImage;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("items");

  // --- Pick image ---
  Future<void> pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) _webImage = await image.readAsBytes();
    } else {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) _pickedImage = File(image.path);
    }
    setState(() {});
  }

  // --- Get user location ---
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied)
      return;

    _currentPosition = await Geolocator.getCurrentPosition();
  }

  // --- Upload image to Cloudinary ---
  Future<String?> _uploadImageToCloudinary() async {
    const cloudName = 'dasc1kik1';
    const uploadPreset = 'ml_default';
    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      var request = http.MultipartRequest('POST', uploadUrl);
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webImage!,
            filename: "upload.jpg",
          ),
        );
      } else if (_pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _pickedImage!.path),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['secure_url'];
      }
    } catch (e) {
      print("Cloudinary upload error: $e");
    }
    return null;
  }

  // --- Generate short conceptual meanings using Datamuse API ---
  Future<List<String>> _generateMeanings(String text) async {
    final words = text
        .split(RegExp(r'\s+'))
        .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''))
        .where((w) => w.length > 2)
        .toList();

    if (words.isEmpty) return [];

    List<String> allMeanings = [];

    for (final word in words) {
      try {
        final url = Uri.parse('https://api.datamuse.com/words?ml=$word');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          for (var item in data) {
            final meaning = item['word']?.toString();
            if (meaning != null && meaning.length > 2) {
              allMeanings.add(meaning);
            }
          }
        }
      } catch (e) {
        print("Meaning fetch error for '$word': $e");
      }
    }

    // Remove duplicates and limit to reasonable number for DB efficiency
    return allMeanings.toSet().toList();
  }

  // --- Save item to Firebase ---
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null && _webImage == null) {
      Get.snackbar(
        "Missing Image",
        "Please select an image.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _getCurrentLocation();

      final imageUrl = await _uploadImageToCloudinary();
      if (imageUrl == null) throw Exception("Image upload failed");

      final combinedText =
          "${_titleController.text.trim()} ${_descriptionController.text.trim()}";

      final meanings = await _generateMeanings(combinedText);

      final newItemRef = _dbRef.push();
      await newItemRef.set({
        'owner': FirebaseAuth.instance.currentUser?.email,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'latitude': _currentPosition?.latitude ?? 0.0,
        'longitude': _currentPosition?.longitude ?? 0.0,
        'imageUrl': imageUrl,
        'meanings': meanings,
        'createdAt': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        "Success",
        "Item uploaded successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );

      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _pickedImage = null;
      _webImage = null;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to upload item: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Update all items with new meanings ---

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF9),
      appBar: AppBar(
        title: const Text(
          "Upload Item",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _titleController,
                label: "Title",
                icon: Icons.title_rounded,
                validator: (v) => v!.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (v) =>
                    v!.isEmpty ? "Please enter a description" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: "Price (if applicable)",
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                    return "Enter a valid number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text("Pick Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 10),
              if (_pickedImage != null || _webImage != null)
                kIsWeb
                    ? Image.memory(_webImage!, height: 160, fit: BoxFit.cover)
                    : Image.file(_pickedImage!, height: 160, fit: BoxFit.cover),
              const SizedBox(height: 25),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveItem,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text("Upload Item"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
