class Customer {
  final String id;
  String storeName;
  String address;
  String contactPerson;
  String phoneNumber;
  String area; // Khu vực hoặc tuyến
  bool visited; // Thêm field visited

  Customer({
    required this.id,
    required this.storeName,
    required this.address,
    required this.contactPerson,
    required this.phoneNumber,
    required this.area,
    this.visited = false, // Mặc định false
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      storeName: map['storeName'] ?? '',
      address: map['address'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      area: map['area'] ?? '',
      visited: map['visited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'address': address,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'area': area,
      'visited': visited,
    };
  }
}
