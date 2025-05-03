import 'package:barber_booking_app/data/services_data.dart';
import 'package:barber_booking_app/pages/auth/change_password.dart';
import 'package:barber_booking_app/pages/auth/login.dart';
import 'package:barber_booking_app/pages/booking/booking.dart';
import 'package:barber_booking_app/pages/booking/booking_history.dart';
import 'package:barber_booking_app/pages/profile/profile.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.user});
  final User? user;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? name;
  String? image;

  final TextEditingController _searchController =
      TextEditingController(); // Controller cho thanh tìm kiếm
  List<Map<String, dynamic>> allServices = []; // Danh sách tất cả dịch vụ
  List<Map<String, dynamic>> displayedServices =
      []; // Danh sách dịch vụ hiển thị sau khi lọc

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    getUserData();
    _initializeServices();
    _setupUserPresenceCheck();
  }

  // Thêm hàm này
  void _setupUserPresenceCheck() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          _handleUserDeletion();
        }
      });
    }
  }

// Thêm hàm xử lý xóa user
  void _handleUserDeletion() async {
    await FirebaseAuth.instance.signOut();
    await SharedpreferenceHelper().clearAllData();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final userData = await DatabaseMethods().getUserDetails(userId);
      if (userData != null) {
        await SharedpreferenceHelper().saveUserName(userData['Name'] ?? '');
        await SharedpreferenceHelper().saveUserEmail(userData['Email'] ?? '');
        await SharedpreferenceHelper()
            .saveUserAvatar(userData['avatarUrl'] ?? '');
        await SharedpreferenceHelper().saveUserId(userId);
      }
    }
  }

  Future<void> getUserData() async {
    String? savedName = await SharedpreferenceHelper().getUserName();
    String? savedEmail = await SharedpreferenceHelper().getUserEmail();
    String? savedImage = await SharedpreferenceHelper().getUserAvatar();

    setState(() {
      name = savedName?.isNotEmpty == true
          ? savedName
          : savedEmail ?? "Guest"; // Xử lý null
      image = savedImage;
    });
  }

  // Khởi tạo danh sách dịch vụ
  void _initializeServices() {
    allServices = ServicesData.allServices; // Lấy dữ liệu từ file mới
    displayedServices = List.from(allServices);
  }

  // Hàm lọc dịch vụ theo từ khóa
  void _filterServices(String query) {
    dynamic filtered = allServices.where((service) {
      final titleLower = service['title']!.toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower
          .contains(queryLower); // Kiểm tra từ khóa có trong tên dịch vụ không
    }).toList();

    setState(() {
      displayedServices = filtered;
    });
  }

  Future<void> _logout() async {
    // Clear Firebase session
    await FirebaseAuth.instance.signOut();

    // Clear ALL SharedPreferences data
    await SharedpreferenceHelper().clearAllData();

    // Chuyển hướng và xóa toàn bộ Navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF2b1615),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2b1615),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profile(
                        user: name,
                        email: widget.user?.email,
                      ),
                    ),
                  ).then((result) {
                    // Nhận cả object kết quả
                    if (result != null) {
                      setState(() {
                        name = result['name'];
                        image = result['avatar'];
                      });
                    }
                  });
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: FutureBuilder<String?>(
                    future: SharedpreferenceHelper().getUserAvatar(),
                    builder: (context, snapshot) {
                      final currentImage = snapshot.data ?? image;
                      return ClipOval(
                        child: Image.network(
                          currentImage ?? "assets/images/default_user.png",
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset("assets/images/default_user.png"),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10.0),
              const Text(
                "Hello!",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 40.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                name ?? "Guest",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 21.0),
              const Divider(color: Colors.white30),
              const SizedBox(height: 20.0),
              const Text(
                "Services",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15.0),

              // Thanh tìm kiếm
              TextField(
                controller: _searchController,
                onChanged: _filterServices, // Lọc dịch vụ khi nhập
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search services...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF4e2d2c),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // Danh sách dịch vụ (lọc theo tìm kiếm)
              Expanded(
                child: displayedServices.isEmpty
                    ? const Center(
                        child: Text(
                          "No services found.",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 18.0),
                        ),
                      )
                    : GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20.0,
                        mainAxisSpacing: 20.0,
                        children: displayedServices
                            .map((service) => _serviceItem(
                                service['title']!, service['image']!))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Drawer (không thay đổi)
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trong phần CircleAvatar của AppBar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: FutureBuilder<String?>(
                    future: SharedpreferenceHelper().getUserAvatar(),
                    builder: (context, snapshot) {
                      final currentImage = snapshot.data ?? image;
                      return ClipOval(
                        child: Image.network(
                          currentImage ?? "assets/images/default_user.png",
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset("assets/images/default_user.png"),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name ?? "Guest",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.black),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.black),
            title: const Text("Booking History"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BookingHistory()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.black),
            title: const Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.black),
            title: const Text("Change Password"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChangePassword()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel")),
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
                _logout();
              }
            },
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng dịch vụ
  Widget _serviceItem(String title, String imagePath) {
    return GestureDetector(
// Trong hàm _serviceItem của Home
      // Trong Home.dart, hàm _serviceItem
      onTap: () {
        final selectedService =
            allServices.firstWhere((s) => s['title'] == title);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Booking(service: selectedService), // Truyền cả Map
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFe29452),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 80.0,
              width: 80.0,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
