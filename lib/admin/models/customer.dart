class Customer {
  final String id;
  String storeName;
  String address;
  String contactPerson;
  String phoneNumber;
  String area; // Khu vực hoặc tuyến

  Customer({
    required this.id,
    required this.storeName,
    required this.address,
    required this.contactPerson,
    required this.phoneNumber,
    required this.area,
  });
}
