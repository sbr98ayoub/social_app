class UserModel {
  final String uid;
  final String username;
  final String email;
  final String phone;
  final String status; // to track if the user is online or offline

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phone,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'phone': phone,
      'status': status, // Add the status for online/offline
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      status: map['status'] ?? 'offline', // Default status is offline
    );
  }
}
