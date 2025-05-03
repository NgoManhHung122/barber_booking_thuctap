import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    try {
      final name = (userInfoMap['Name'] as String? ?? '').toLowerCase();
      final email = (userInfoMap['Email'] as String? ?? '').toLowerCase();

      [...name.split(' '), ...email.split('@').first.split('.')]
          .where((s) => s.isNotEmpty)
          .toList();

      // Cập nhật userInfoMap với kiểu dữ liệu đúng
      await FirebaseFirestore.instance.collection("Users").doc(id).set({
        "Name": userInfoMap['Name'],
        "Email": userInfoMap['Email'],
        "Id": id,
        "avatarUrl": userInfoMap['avatarUrl'],
      });

      print("User added to Firestore: $id");
    } catch (e) {
      print("Exception in addUserDetails: $e");
      throw e;
    }
  }

  //ham them nguoi dung dat lich
  Future addUserBooking(Map<String, dynamic> userInfoMap, String userId) async {
    userInfoMap["userId"] = userId;
    return await FirebaseFirestore.instance
        .collection("Booking")
        .add(userInfoMap);
  }

  //ham lay cac booking tu csdl
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookings() {
    return FirebaseFirestore.instance.collection("Booking").snapshots();
  }

  //
  Future deleteBooking(String id) async {
    return await FirebaseFirestore.instance
        .collection("Booking")
        .doc(id)
        .delete();
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null; // Trả về null nếu user không tồn tại
    } catch (e) {
      print("Error getting user details: $e");
      return null;
    }
  }

  Future updateBookingStatus(String bookingId, String newStatus) async {
    return await FirebaseFirestore.instance
        .collection("Booking")
        .doc(bookingId)
        .update({"Status": newStatus});
  }

  // Lấy danh sách users
  Stream<QuerySnapshot> getUsers() {
    return FirebaseFirestore.instance.collection("Users").snapshots();
  }

  Future<void> deleteAllUserBookings(String userId) async {
    final bookingSnapshot = await FirebaseFirestore.instance
        .collection("Booking")
        .where("userId", isEqualTo: userId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in bookingSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteUser(String userId) async {
    await deleteAllUserBookings(userId);
    await FirebaseFirestore.instance.collection("Users").doc(userId).delete();
  }
}
//tai du lieu len csdl(firebase store)