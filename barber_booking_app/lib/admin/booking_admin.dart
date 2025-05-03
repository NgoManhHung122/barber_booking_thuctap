import 'package:barber_booking_app/admin/user_management.dart';
import 'package:barber_booking_app/pages/auth/login.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingAdmin extends StatefulWidget {
  const BookingAdmin({super.key});

  @override
  State<BookingAdmin> createState() => _BookingAdminState();
}

class _BookingAdminState extends State<BookingAdmin> {
  Stream? bookingStream;

  // Lấy dữ liệu booking từ Firestore
  getontheload() async {
    try {
      bookingStream = await DatabaseMethods().getBookings();
      setState(() {});
    } catch (e) {
      print("Lỗi khi tải dữ liệu: $e");
    }
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  // Hàm đăng xuất
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  // Hàm xác định màu trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // Widget dropdown trạng thái
  Widget _buildStatusDropdown(DocumentSnapshot ds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: ds["Status"] ?? 'pending',
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        underline: const SizedBox(),
        items: ['pending', 'confirmed', 'completed', 'cancelled']
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(value),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            DatabaseMethods().updateBookingStatus(ds.id, newValue);
          }
        },
      ),
    );
  }

  // Widget hiển thị danh sách booking
  Widget _buildBookingList() {
    return StreamBuilder(
      stream: bookingStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No bookings found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            String userId = ds["userId"];
            String barberName = ds["Barber"] ?? "Unknown";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                // Xử lý loading
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                // Xử lý user không tồn tại
                if (!userSnapshot.hasData || userSnapshot.data!.data() == null) {
                  return _buildDeletedUserBooking(ds, barberName);
                }

                // Hiển thị thông tin booking
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                return _buildUserBookingCard(ds, userData, barberName);
              },
            );
          },
        );
      },
    );
  }

  // Hiển thị booking khi user đã bị xóa
  Widget _buildDeletedUserBooking(DocumentSnapshot ds, String barberName) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[100],
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person_off, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ds["Main_Service"] ?? "No service",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            Text(
              "Package: ${ds["Sub_Service"] ?? "No package"}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Customer", "Deleted User"),
            _buildInfoRow("Barber", barberName),
            _buildInfoRow("Price", "\$${ds["Price"]?.toStringAsFixed(2) ?? "0.00"}"),
            _buildInfoRow("Date", ds["Date"] ?? "N/A"),
            _buildInfoRow("Time", ds["Time"] ?? "N/A"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatusDropdown(ds)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async => await DatabaseMethods().deleteBooking(ds.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFdf711a),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "DONE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị booking khi user tồn tại
  Widget _buildUserBookingCard(
      DocumentSnapshot ds, Map<String, dynamic> userData, String barberName) {
    String username = userData['Name'] ?? "Unknown";
    String avatarUrl = userData['avatarUrl'] ?? "https://i.imgur.com/a6kQUGU.png";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[100],
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError: (_, __) =>
              const Icon(Icons.person, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ds["Main_Service"] ?? "No service",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            Text(
              "Package: ${ds["Sub_Service"] ?? "No package"}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Customer", username),
            _buildInfoRow("Barber", barberName),
            _buildInfoRow("Price", "\$${ds["Price"]?.toStringAsFixed(2) ?? "0.00"}"),
            _buildInfoRow("Date", ds["Date"] ?? "N/A"),
            _buildInfoRow("Time", ds["Time"] ?? "N/A"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatusDropdown(ds)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async => await DatabaseMethods().deleteBooking(ds.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFdf711a),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "DONE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper hiển thị thông tin
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                color: Colors.blueGrey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.blueGrey[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Management"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: getontheload,
          )
        ],
      ),
      body: _buildBookingList(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.brown),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        NetworkImage("https://i.imgur.com/a6kQUGU.png"),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Admin Panel",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Manage Users"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserManagement()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirmLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout Confirmation"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmLogout == true) {
                  await FirebaseAuth.instance.signOut();
                  await SharedpreferenceHelper().clearAllData();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}