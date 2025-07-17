import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salespro/admin/models/product.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order.dart';
import 'package:salespro/admin/models/order_item.dart';
import 'package:salespro/admin/models/user.dart';
import 'package:salespro/admin/models/sales_route.dart';
import 'package:salespro/admin/models/payment.dart';
import 'package:salespro/admin/models/purchase_order.dart';
import 'package:salespro/admin/models/purchase_order_item.dart';
import 'package:salespro/admin/models/check_in_record.dart';

final List<Product> mockProducts = [
  Product(
    id: 'SP001',
    name: 'Nước ngọt Coca-Cola',
    description: 'Nước giải khát có gas',
    unit: 'Chai',
    salePrice: 10000,
    purchasePrice: 8000,
    stockQuantity: 150,
    category: 'Đồ uống',
  ),
  Product(
    id: 'SP002',
    name: 'Bánh mì Sandwich',
    description: 'Bánh mì kẹp thịt nguội và rau',
    unit: 'Cái',
    salePrice: 25000,
    purchasePrice: 20000,
    stockQuantity: 50,
    category: 'Đồ ăn nhanh',
  ),
  Product(
    id: 'SP003',
    name: 'Sữa tươi Vinamilk',
    description: 'Sữa tươi tiệt trùng không đường',
    unit: 'Hộp',
    salePrice: 7000,
    purchasePrice: 6000,
    stockQuantity: 200,
    category: 'Sữa & Sản phẩm từ sữa',
  ),
  Product(
    id: 'SP004',
    name: 'Mì gói Hảo Hảo',
    description: 'Mì ăn liền vị tôm chua cay',
    unit: 'Gói',
    salePrice: 3500,
    purchasePrice: 3000,
    stockQuantity: 500,
    category: 'Thực phẩm khô',
  ),
  Product(
    id: 'SP005',
    name: 'Dầu ăn Tường An',
    description: 'Dầu ăn cao cấp, chai 1 lít',
    unit: 'Chai',
    salePrice: 40000,
    purchasePrice: 35000,
    stockQuantity: 80,
    category: 'Gia vị & Dầu ăn',
  ),
];

final List<Customer> mockCustomers = [
  Customer(
    id: 'KH001',
    storeName: 'Tạp hóa bà Lan',
    address: '123 Đường ABC, Quận 1, TP.HCM',
    contactPerson: 'Bà Lan',
    phoneNumber: '0909123456',
    area: 'Tuyến 1',
  ),
  Customer(
    id: 'KH002',
    storeName: 'Siêu thị mini An An',
    address: '456 Đường XYZ, Quận 3, TP.HCM',
    contactPerson: 'Anh An',
    phoneNumber: '0987654321',
    area: 'Tuyến 2',
  ),
  Customer(
    id: 'KH003',
    storeName: 'Cửa hàng tiện lợi 24/7',
    address: '789 Đường LMN, Quận Gò Vấp, TP.HCM',
    contactPerson: 'Chị Bảy',
    phoneNumber: '0912345678',
    area: 'Tuyến 1',
  ),
];

// Define payments before orders
final List<Payment> mockPayments = [
  Payment(
      id: 'TT001',
      orderId: 'DH001',
      amount: 37500,
      paymentDate: DateTime.now().subtract(const Duration(days: 1)),
      method: PaymentMethod.Cash),
  Payment(
      id: 'TT002',
      orderId: 'DH002',
      amount: 50000,
      paymentDate: DateTime.now(),
      method: PaymentMethod.BankTransfer),
];

final List<Order> mockOrders = [
  Order(
    id: 'DH001',
    customer: mockCustomers[0],
    orderDate: DateTime.now().subtract(const Duration(days: 2)),
    status: OrderStatus.Delivered,
    items: [
      OrderItem(product: mockProducts[0], quantity: 2, unitPrice: 10000),
      OrderItem(product: mockProducts[3], quantity: 5, unitPrice: 3500),
    ],
    payments: mockPayments.where((p) => p.orderId == 'DH001').toList(),
  ),
  Order(
    id: 'DH002',
    customer: mockCustomers[1],
    orderDate: DateTime.now().subtract(const Duration(days: 1)),
    status: OrderStatus.Confirmed,
    items: [
      OrderItem(product: mockProducts[1], quantity: 1, unitPrice: 25000),
      OrderItem(product: mockProducts[2], quantity: 10, unitPrice: 7000),
    ],
    payments: mockPayments.where((p) => p.orderId == 'DH002').toList(),
  ),
  Order(
    id: 'DH003',
    customer: mockCustomers[0],
    orderDate: DateTime.now(),
    status: OrderStatus.Pending,
    items: [
      OrderItem(product: mockProducts[4], quantity: 2, unitPrice: 40000),
    ],
  ),
  Order(
    id: 'DH004',
    customer: mockCustomers[2],
    orderDate: DateTime.now().subtract(const Duration(hours: 4)),
    status: OrderStatus.Cancelled,
    items: [
      OrderItem(product: mockProducts[0], quantity: 10, unitPrice: 10000),
      OrderItem(product: mockProducts[1], quantity: 2, unitPrice: 25000),
      OrderItem(product: mockProducts[2], quantity: 5, unitPrice: 7000),
    ],
  ),
];

final List<User> mockUsers = [
  User(
    id: 'U001',
    name: 'Admin User',
    phoneNumber: '0123456789',
    email: 'admin@salespro.com',
    role: UserRole.Admin,
  ),
  User(
    id: 'U002',
    name: 'Sales Person 1',
    phoneNumber: '0987654321',
    email: 'sales1@salespro.com',
    role: UserRole.Sales,
  ),
  User(
    id: 'U003',
    name: 'Accountant User',
    phoneNumber: '0911223344',
    email: 'accountant@salespro.com',
    role: UserRole.Accountant,
  ),
  User(
    id: 'U004',
    name: 'Inactive Sales',
    phoneNumber: '0955667788',
    email: 'sales2@salespro.com',
    role: UserRole.Sales,
    isActive: false,
  ),
];

final List<SalesRoute> mockRoutes = [
  SalesRoute(
    id: 'T01',
    name: 'Tuyến Quận 1 - Quận 3',
    salesperson: mockUsers
        .firstWhere((user) => user.role == UserRole.Sales && user.isActive),
    customers: [mockCustomers[0], mockCustomers[1]],
  ),
  SalesRoute(
    id: 'T02',
    name: 'Tuyến Gò Vấp',
    salesperson: mockUsers
        .firstWhere((user) => user.role == UserRole.Sales && user.isActive),
    customers: [mockCustomers[2]],
  ),
];

final List<PurchaseOrder> mockPurchaseOrders = [
  PurchaseOrder(
    id: 'PN001',
    supplier: 'Nhà Cung Cấp A',
    orderDate: DateTime.now().subtract(const Duration(days: 5)),
    status: PurchaseOrderStatus.Received,
    items: [
      PurchaseOrderItem(
          product: mockProducts[0], quantity: 100, purchasePrice: 7900),
      PurchaseOrderItem(
          product: mockProducts[1], quantity: 50, purchasePrice: 19500),
    ],
  ),
  PurchaseOrder(
    id: 'PN002',
    supplier: 'Nhà Cung Cấp B',
    orderDate: DateTime.now().subtract(const Duration(days: 1)),
    status: PurchaseOrderStatus.Ordered,
    items: [
      PurchaseOrderItem(
          product: mockProducts[3], quantity: 200, purchasePrice: 2900),
      PurchaseOrderItem(
          product: mockProducts[4], quantity: 100, purchasePrice: 34000),
    ],
  ),
];

final List<CheckInRecord> mockCheckIns = [
  CheckInRecord(
    user: mockUsers[1], // Sales Person 1
    checkInTime: DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
    checkOutTime: DateTime.now().subtract(const Duration(hours: 1)),
    location: const LatLng(10.8231, 106.6297), // Ho Chi Minh City
    address: '123 Main St, Ho Chi Minh City',
  ),
  CheckInRecord(
    user: mockUsers[3], // Inactive Sales
    checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
    location: const LatLng(21.0285, 105.8542), // Hanoi
    address: '456 Second Ave, Hanoi',
  ),
  CheckInRecord(
    user: mockUsers[1], // Sales Person 1
    checkInTime:
        DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 5)),
    checkOutTime:
        DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 20)),
    location: const LatLng(10.8231, 106.6297), // Ho Chi Minh City
    address: '789 Third Blvd, Ho Chi Minh City',
  ),
];
