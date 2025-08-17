class Address {
  final String id;
  final String name;
  final String phone;
  final String flatNo;
  final String buildingName;
  final String? landmark;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.flatNo,
    required this.buildingName,
    this.landmark,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'],
    name: json['name'],
    phone: json['phone'],
    flatNo: json['flatNo'],
    buildingName: json['buildingName'],
    landmark: json['landmark'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'flatNo': flatNo,
    'buildingName': buildingName,
    if (landmark != null) 'landmark': landmark,
  };
} 