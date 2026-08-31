class ProfileModel {
  final String id;
  final String name;
  final String mobile;
  final int points;
  final String? bankName;
  final String? bankAddress;
  final String? ifscCode;
  final String? accountNumber;
  final String? upiId;

  ProfileModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.points,
    this.bankName,
    this.bankAddress,
    this.ifscCode,
    this.accountNumber,
    this.upiId,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      bankName: json['bankName'] as String?,
      bankAddress: json['bankAddress'] as String?,
      ifscCode: json['ifscCode'] as String?,
      accountNumber: json['accountNumber'] as String?,
      upiId: json['upiId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobile': mobile,
    'points': points,
    if (bankName != null) 'bankName': bankName,
    if (bankAddress != null) 'bankAddress': bankAddress,
    if (ifscCode != null) 'ifscCode': ifscCode,
    if (accountNumber != null) 'accountNumber': accountNumber,
    if (upiId != null) 'upiId': upiId,
  };

  ProfileModel copyWith({
    String? id,
    String? name,
    String? mobile,
    int? points,
    String? bankName,
    String? bankAddress,
    String? ifscCode,
    String? accountNumber,
    String? upiId,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      points: points ?? this.points,
      bankName: bankName ?? this.bankName,
      bankAddress: bankAddress ?? this.bankAddress,
      ifscCode: ifscCode ?? this.ifscCode,
      accountNumber: accountNumber ?? this.accountNumber,
      upiId: upiId ?? this.upiId,
    );
  }
}
