import 'package:barber_booking_app/pages/barbers/barbers.dart';
import 'package:barber_booking_app/pages/barbers/sub_service_selection.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';

class Booking extends StatefulWidget {
  final Map<String, dynamic> service;
  const Booking({required this.service, super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  String? name;
  String? email;
  String? image;
  bool isLoading = false;
  Map<String, dynamic>? selectedBarber;
  Map<String, dynamic>? selectedSubService;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    image = await SharedpreferenceHelper().getUserAvatar();
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final now = DateTime.now();
    // Xác định initialTime dựa trên ngày đã chọn
    final initialTime = _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day
        ? TimeOfDay.fromDateTime(now) // Nếu là hôm nay, bắt đầu từ giờ hiện tại
        : _selectedTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );

      if (selectedDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot select a past time!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        setState(() => _selectedTime = picked);
      }
    }
  }

  Future<void> _selectBarber() async {
    final barber = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Barbers()),
    );

    if (barber != null) {
      setState(() {
        selectedBarber = barber;
      });
    }
  }

  Future<void> bookService() async {
    // Kiểm tra thời gian trước khi đặt
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selected time is in the past!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (selectedBarber == null || selectedSubService == null) {
      // Thêm điều kiện check sub service
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedBarber == null
              ? "Please select a barber!"
              : "Please select a service package!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final userBookingMap = {
      "Main_Service": widget.service['title'],
      "Sub_Service": selectedSubService!['name'],
      "Price": selectedSubService!['price'],
      "Barber": selectedBarber?["name"],
      "Date":
          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
      "Time": _selectedTime.format(context),
      "userId": await SharedpreferenceHelper().getUserId(),
      "Email": email,
      "Image": image,
      "Status": "pending",
    };

    try {
      String? userId = await SharedpreferenceHelper().getUserId();
      if (userId != null) {
        
        await DatabaseMethods().addUserBooking(userBookingMap, userId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not found. Please log in again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Service booked successfully!"),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Booking failed: ${e.toString()}"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectSubService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubServiceSelection(
          subServices: widget.service['sub_services'],
        ),
      ),
    );

    if (result != null) {
      setState(() => selectedSubService = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2b1615),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 30.0),
            ),
            const SizedBox(height: 20),

            Text("Book ${widget.service['title']}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Chọn Barber
            GestureDetector(
              onTap: _selectBarber,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(selectedBarber?["name"] ?? "Select Barber",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nút chọn gói dịch vụ con
            GestureDetector(
              onTap: _selectSubService,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      selectedSubService?['name'] ?? "Select Service Package",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (selectedSubService != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.work_history,
                            color: Colors.orange, size: 25),
                        const SizedBox(width: 10),
                        Text(
                          selectedSubService!['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Price:",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "\$${selectedSubService!['price']}",
                          style: const TextStyle(
                              color: Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Chọn Ngày
            GestureDetector(
              onTap: () => _selectDate(context),
              child: _buildOptionTile(Icons.calendar_month, "Select Date",
                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
            ),
            const SizedBox(height: 20),

            // Chọn Giờ
            GestureDetector(
              onTap: () => _selectTime(context),
              child: _buildOptionTile(Icons.access_time, "Select Time",
                  _selectedTime.format(context)),
            ),
            const SizedBox(height: 20),

            // Nút Đặt Lịch
            GestureDetector(
              onTap: isLoading ? null : bookService,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("BOOK NOW",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white24, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
