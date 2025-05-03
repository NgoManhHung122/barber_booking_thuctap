import 'package:barber_booking_app/data/barber_data.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingHistory extends StatefulWidget {
  @override
  _BookingHistoryState createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  String? userEmail;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _getUserEmail();
  }

  Future<void> _getUserInfo() async {
    currentUserId = await SharedpreferenceHelper().getUserId();
    userEmail = await SharedpreferenceHelper().getUserEmail();
    setState(() {});
  }

  Future<void> _getUserEmail() async {
    userEmail = await SharedpreferenceHelper().getUserEmail();
    setState(() => isLoading = false);
  }

// Sửa hàm _showCancelDialog
void _showCancelDialog(BuildContext context, String bookingId) {
  final scaffoldContext = ScaffoldMessenger.of(context).context;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Cancellation'),
      content: const Text('Are you sure you want to cancel this booking?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // Đóng dialog trước
            
            try {
              await DatabaseMethods().updateBookingStatus(bookingId, 'cancelled');
              
              // Kiểm tra mounted trước khi show SnackBar
              if (mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('Booking cancelled successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(
                    content: Text('Error cancelling booking: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

  // Thêm hàm helper để đổi màu theo trạng thái
  Color _getStatusColor(String? status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking History"),
        backgroundColor: Colors.brown,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Booking')
                  .where('userId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No bookings found!",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                var bookings = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    var booking = bookings[index];
                    var bookingData = booking.data() as Map<String, dynamic>?;

                    String mainService =
                        bookingData?["Main_Service"] ?? "Unknown";
                    String subService =
                        bookingData?["Sub_Service"] ?? "Unknown";
                    String price =
                        bookingData?["Price"]?.toString() ?? "Unknown";
                    String barberName = bookingData?["Barber"] ?? "Unknown";
                    Map<String, dynamic>? barber = getBarberByName(barberName);
                    String barberImage =
                        barber?["image"] ?? "assets/images/default_barber.png";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      color: Colors.brown[100],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(barberImage),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mainService,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                            Text(
                              "Package: $subService",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.brown[600],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Barber: $barberName",
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Price: \$$price",
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Date: ${bookingData?["Date"] ?? 'Unknown'}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Time: ${bookingData?["Time"] ?? 'Unknown'}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Status: ${bookingData?["Status"]?.toUpperCase() ?? 'PENDING'}",
                              style: TextStyle(
                                color: _getStatusColor(bookingData?["Status"]),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: (bookingData?["Status"] == 'pending')
                            ? IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () =>
                                    _showCancelDialog(context, booking.id),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
