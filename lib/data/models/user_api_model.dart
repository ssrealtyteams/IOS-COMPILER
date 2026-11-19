class UserApiModel {
  final String id;
  final String fullName;
  final String emailAddress;

  const UserApiModel({
    required this.id,
    required this.fullName,
    required this.emailAddress,
  });

  factory UserApiModel.fromJson(Map<String, dynamic> json) {
    return UserApiModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      emailAddress: json['email_address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email_address': emailAddress,
    };
  }
}
