// # Flutter Firebase CRUD (Add, Update, Delete, Show Data)
// # Using BOTH:
// # 1) Firebase Realtime Database
// # 2) Cloud Firestore

// --------------------------------------------
// STEP 1: PUBSPEC.YAML DEPENDENCIES
// --------------------------------------------
// Add these packages:

// dependencies:
//   flutter:
//     sdk: flutter
//   firebase_core: ^2.30.0
//   firebase_database: ^10.5.0
//   cloud_firestore: ^5.4.0

// --------------------------------------------
// STEP 2: FIREBASE INITIALIZATION
// --------------------------------------------
// main.dart

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'home_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Firebase CRUD',
//       home: HomeScreen(),
//     );
//   }
// }

// --------------------------------------------
// HOME SCREEN WITH TWO OPTIONS
// --------------------------------------------
// home_screen.dart

// import 'package:flutter/material.dart';
// import 'realtime_crud.dart';
// import 'firestore_crud.dart';

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Firebase CRUD Demo")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               child: Text("Realtime Database CRUD"),
//               onPressed: () => Navigator.push(context,
//                   MaterialPageRoute(builder: (_) => RealtimeCRUD())),
//             ),
//             ElevatedButton(
//               child: Text("Firestore CRUD"),
//               onPressed: () => Navigator.push(context,
//                   MaterialPageRoute(builder: (_) => FirestoreCRUD())),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ============================================================
// 🚀 PART 1: FIREBASE REALTIME DATABASE CRUD
// ============================================================

// realtime_crud.dart

// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class RealtimeCRUD extends StatefulWidget {
//   @override
//   _RealtimeCRUDState createState() => _RealtimeCRUDState();
// }

// class _RealtimeCRUDState extends State<RealtimeCRUD> {
//   final dbRef = FirebaseDatabase.instance.ref("students");
//   final nameController = TextEditingController();
//   final ageController = TextEditingController();

//   String? editKey;

//   // CREATE / UPDATE
//   void saveData() {
//     if (editKey == null) {
//       dbRef.push().set({
//         "name": nameController.text,
//         "age": ageController.text,
//       });
//     } else {
//       dbRef.child(editKey!).update({
//         "name": nameController.text,
//         "age": ageController.text,
//       });
//       editKey = null;
//     }

//     nameController.clear();
//     ageController.clear();
//   }

//   // DELETE
//   void deleteData(String key) {
//     dbRef.child(key).remove();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Realtime Database CRUD")),
//       body: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.all(10),
//             child: Column(children: [
//               TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
//               TextField(controller: ageController, decoration: InputDecoration(labelText: 'Age')),
//               SizedBox(height: 10),
//               ElevatedButton(onPressed: saveData, child: Text("Save")),
//             ]),
//           ),

//           Expanded(
//             child: StreamBuilder(
//               stream: dbRef.onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
//                   return Center(child: Text("No Data"));
//                 }

//                 Map data = snapshot.data!.snapshot.value as Map;
//                 List keys = data.keys.toList();

//                 return ListView.builder(
//                   itemCount: keys.length,
//                   itemBuilder: (context, index) {
//                     String key = keys[index];
//                     var item = data[key];

//                     return ListTile(
//                       title: Text(item['name']),
//                       subtitle: Text("Age: ${item['age']}"),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: Icon(Icons.edit),
//                             onPressed: () {
//                               nameController.text = item['name'];
//                               ageController.text = item['age'];
//                               editKey = key;
//                             },
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.delete),
//                             onPressed: () => deleteData(key),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// ============================================================
// 🔥 PART 2: FIRESTORE CRUD
// ============================================================

// firestore_crud.dart

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class FirestoreCRUD extends StatefulWidget {
//   @override
//   _FirestoreCRUDState createState() => _FirestoreCRUDState();
// }

// class _FirestoreCRUDState extends State<FirestoreCRUD> {
//   final CollectionReference students =
//       FirebaseFirestore.instance.collection('students');

//   final nameController = TextEditingController();
//   final ageController = TextEditingController();

//   String? docId;

//   // CREATE / UPDATE
//   void saveData() async {
//     if (docId == null) {
//       await students.add({
//         'name': nameController.text,
//         'age': ageController.text,
//       });
//     } else {
//       await students.doc(docId).update({
//         'name': nameController.text,
//         'age': ageController.text,
//       });
//       docId = null;
//     }

//     nameController.clear();
//     ageController.clear();
//   }

//   // DELETE
//   void deleteData(String id) async {
//     await students.doc(id).delete();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Firestore CRUD")),
//       body: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.all(10),
//             child: Column(children: [
//               TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
//               TextField(controller: ageController, decoration: InputDecoration(labelText: 'Age')),
//               SizedBox(height: 10),
//               ElevatedButton(onPressed: saveData, child: Text("Save")),
//             ]),
//           ),

//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: students.snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     var doc = snapshot.data!.docs[index];

//                     return ListTile(
//                       title: Text(doc['name']),
//                       subtitle: Text("Age: ${doc['age']}"),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: Icon(Icons.edit),
//                             onPressed: () {
//                               nameController.text = doc['name'];
//                               ageController.text = doc['age'];
//                               docId = doc.id;
//                             },
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.delete),
//                             onPressed: () => deleteData(doc.id),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// ============================================================
// 📌 DATABASE STRUCTURE
// ============================================================
// Realtime Database:

// students
//   ├── uniqueKey1
//   │     ├── name: Ali
//   │     └── age: 20

// Firestore:

// students (collection)
//   └── docId
//         ├── name: Ali
//         └── age: 20

// ============================================================
//  FEATURES INCLUDED
// ============================================================
// ✔ Add Data
// ✔ Update Data
// ✔ Delete Data
// ✔ Show Live Data
// ✔ Real-time UI Updates
// ✔ Works for BOTH Databases

// --------------------------------------------



// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: FilterStudentsScreen(),
//     );
//   }
// }

// class FilterStudentsScreen extends StatefulWidget {
//   @override
//   _FilterStudentsScreenState createState() => _FilterStudentsScreenState();
// }

// class _FilterStudentsScreenState extends State<FilterStudentsScreen> {

//   String searchName = '';
//   String selectedDepartment = 'All';

//   @override
//   Widget build(BuildContext context) {
//     Query studentsQuery = FirebaseFirestore.instance.collection('students');

//     // Apply department filter
//     if (selectedDepartment != 'All') {
//       studentsQuery =
//           studentsQuery.where('department', isEqualTo: selectedDepartment);
//     }

//     // Apply name filter
//     if (searchName.isNotEmpty) {
//       studentsQuery = studentsQuery
//           .where('name', isGreaterThanOrEqualTo: searchName)
//           .where('name', isLessThan: searchName + 'z');
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Filtered Students"),
//       ),
//       body: Column(
//         children: [

//           // 🔍 Search by Name
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search by name',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchName = value;
//                 });
//               },
//             ),
//           ),

//           // 🎯 Filter by Department Dropdown
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: DropdownButtonFormField<String>(
//               value: selectedDepartment,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//               ),
//               items: ['All', 'CS', 'SE', 'IT']
//                   .map((dep) => DropdownMenuItem(
//                         value: dep,
//                         child: Text(dep),
//                       ))
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedDepartment = value!;
//                 });
//               },
//             ),
//           ),

//           SizedBox(height: 10),

//           // 📄 Display Filtered Data
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: studentsQuery.snapshots(),
//               builder: (context, snapshot) {

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(child: Text("No data found"));
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {

//                     var student = snapshot.data!.docs[index];

//                     return Card(
//                       child: ListTile(
//                         leading: CircleAvatar(child: Text(student['name'][0])),
//                         title: Text(student['name']),
//                         subtitle: Text(
//                             "Dept: ${student['department']}  | CGPA: ${student['cgpa']}"),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: StudentCRUDPage(),
//     );
//   }
// }

// class StudentCRUDPage extends StatefulWidget {
//   @override
//   _StudentCRUDPageState createState() => _StudentCRUDPageState();
// }

// class _StudentCRUDPageState extends State<StudentCRUDPage> {

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController deptController = TextEditingController();
//   final TextEditingController cgpaController = TextEditingController();

//   // 🔗 CHANGE THESE TO YOUR PHP FILE PATHS
//   final String baseUrl = "http://10.0.2.2/flutter_api";
//   // for real device use PC IP e.g: http://192.168.1.5/flutter_api

//   List students = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchStudents();
//   }

//   // ================= FETCH DATA =================
//   Future<void> fetchStudents() async {
//     final response = await http.get(Uri.parse("$baseUrl/get_students.php"));
//     if (response.statusCode == 200) {
//       setState(() {
//         students = jsonDecode(response.body);
//       });
//     }
//   }

//   // ================= ADD DATA =================
//   Future<void> addStudent() async {
//     await http.post(
//       Uri.parse("$baseUrl/insert_student.php"),
//       body: {
//         "name": nameController.text,
//         "department": deptController.text,
//         "cgpa": cgpaController.text,
//       },
//     );
//     clearFields();
//     fetchStudents();
//   }

//   // ================= UPDATE DATA =================
//   Future<void> updateStudent(String id) async {
//     await http.post(
//       Uri.parse("$baseUrl/update_student.php"),
//       body: {
//         "id": id,
//         "name": nameController.text,
//         "department": deptController.text,
//         "cgpa": cgpaController.text,
//       },
//     );
//     clearFields();
//     fetchStudents();
//   }

//   // ================= DELETE DATA =================
//   Future<void> deleteStudent(String id) async {
//     await http.post(
//       Uri.parse("$baseUrl/delete_student.php"),
//       body: {"id": id},
//     );
//     fetchStudents();
//   }

//   void clearFields() {
//     nameController.clear();
//     deptController.clear();
//     cgpaController.clear();
//   }

//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Flutter CRUD with XAMPP")),
//       body: Column(
//         children: [

//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: InputDecoration(labelText: "Name"),
//                 ),
//                 TextField(
//                   controller: deptController,
//                   decoration: InputDecoration(labelText: "Department"),
//                 ),
//                 TextField(
//                   controller: cgpaController,
//                   decoration: InputDecoration(labelText: "CGPA"),
//                   keyboardType: TextInputType.number,
//                 ),
//                 SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: addStudent,
//                   child: Text("Add Student"),
//                 ),
//               ],
//             ),
//           ),

//           Divider(),

//           Expanded(
//             child: ListView.builder(
//               itemCount: students.length,
//               itemBuilder: (context, index) {
//                 var student = students[index];

//                 return Card(
//                   child: ListTile(
//                     title: Text(student['name']),
//                     subtitle: Text(
//                         "Dept: ${student['department']} | CGPA: ${student['cgpa']}"),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [

//                         // EDIT BUTTON
//                         IconButton(
//                           icon: Icon(Icons.edit, color: Colors.blue),
//                           onPressed: () {
//                             nameController.text = student['name'];
//                             deptController.text = student['department'];
//                             cgpaController.text = student['cgpa'];

//                             showDialog(
//                               context: context,
//                               builder: (_) => AlertDialog(
//                                 title: Text("Update Student"),
//                                 content: ElevatedButton(
//                                   onPressed: () {
//                                     updateStudent(student['id']);
//                                     Navigator.pop(context);
//                                   },
//                                   child: Text("Update"),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),

//                         // DELETE BUTTON
//                         IconButton(
//                           icon: Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => deleteStudent(student['id']),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }