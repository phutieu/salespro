import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../admin/models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class PdfService {
  static Future<void> generateInvoice(Order order) async {
    try {
      final pdf = pw.Document();
      // Nếu là đơn trả hàng, lấy lý do trả hàng từ returns collection
      String? returnReason;
      if (order.status == OrderStatus.Return) {
        try {
          final returns = await firestore.FirebaseFirestore.instance
              .collection('returns')
              .where('orderId', isEqualTo: order.id)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          if (returns.docs.isNotEmpty) {
            final items = returns.docs.first.data()['items'] as List?;
            if (items != null && items.isNotEmpty) {
              returnReason = items.first['reason'] as String?;
            }
          }
        } catch (e) {
          returnReason = null;
        }
      }
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (order.status == OrderStatus.Return)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Text('ĐƠN TRẢ HÀNG',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange)),
                  ),
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'HÓA ĐƠN BÁN HÀNG',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Mã đơn hàng: ${order.id.substring(0, 8)}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'SalesPro',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Hệ thống quản lý bán hàng',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Customer Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'THÔNG TIN KHÁCH HÀNG',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Tên cửa hàng: ${order.customer.storeName}'),
                      pw.Text('Địa chỉ: ${order.customer.address}'),
                      pw.Text('Liên hệ: ${order.customer.contactPerson}'),
                      pw.Text('SĐT: ${order.customer.phoneNumber}'),
                      pw.Text('Khu vực: ${order.customer.area}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Items Table
                pw.Text(
                  'CHI TIẾT ĐƠN HÀNG',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Sản phẩm',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('SL',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Đơn giá',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Thành tiền',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Items
                    ...order.items.map((item) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(item.product.name),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  '${item.quantity} ${item.product.unit}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  NumberFormat.decimalPattern('vi_VN')
                                      .format(item.unitPrice)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  NumberFormat.decimalPattern('vi_VN')
                                      .format(item.totalPrice)),
                            ),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'TỔNG TIỀN: ${NumberFormat.decimalPattern('vi_VN').format(order.totalAmount)} ₫',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Đã trả: ${NumberFormat.decimalPattern('vi_VN').format(order.amountPaid)} ₫',
                            style: pw.TextStyle(color: PdfColors.green),
                          ),
                          pw.Text(
                            'Còn nợ: ${NumberFormat.decimalPattern('vi_VN').format(order.amountDue)} ₫',
                            style: pw.TextStyle(color: PdfColors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Trước phần chữ ký, nếu là đơn trả hàng và có lý do
                if (order.status == OrderStatus.Return &&
                    returnReason != null &&
                    returnReason.isNotEmpty)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
                    child: pw.Text('Lý do trả hàng: $returnReason',
                        style: pw.TextStyle(
                            color: PdfColors.orange,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Chữ ký khách hàng'),
                        pw.SizedBox(height: 30),
                        pw.Container(
                          width: 150,
                          height: 1,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Chữ ký nhân viên'),
                        pw.SizedBox(height: 30),
                        pw.Container(
                          width: 150,
                          height: 1,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // Handle different platforms
      if (kIsWeb) {
        // Web platform - show success message only
        print('PDF generated successfully for web');
        print('PDF size: ${pdfBytes.length} bytes');
        // Note: Web download requires additional setup
      } else {
        // Mobile/Desktop platform
        try {
          Directory outputDir;
          String filePath;

          try {
            // Try path_provider first
            outputDir = await getTemporaryDirectory();
            filePath =
                '${outputDir.path}/invoice_${order.id.substring(0, 8)}.pdf';
          } catch (e) {
            print('path_provider failed, trying alternatives...');
            try {
              // Try current directory
              outputDir = Directory.current;
              filePath =
                  '${outputDir.path}/invoice_${order.id.substring(0, 8)}.pdf';
            } catch (e) {
              try {
                // Try Documents directory
                outputDir = Directory('/storage/emulated/0/Download');
                filePath =
                    '${outputDir.path}/invoice_${order.id.substring(0, 8)}.pdf';
              } catch (e) {
                // Last resort: use app documents directory
                outputDir = Directory('/data/data/com.example.salespro/files');
                filePath =
                    '${outputDir.path}/invoice_${order.id.substring(0, 8)}.pdf';
              }
            }
          }

          // Ensure directory exists
          if (!await outputDir.exists()) {
            await outputDir.create(recursive: true);
          }

          final file = File(filePath);
          await file.writeAsBytes(pdfBytes);

          print('PDF saved to: $filePath');

          // Try to open PDF
          try {
            await OpenFile.open(file.path);
          } catch (e) {
            print('Could not open PDF automatically: $e');
          }
        } catch (e) {
          print('Error saving PDF to file: $e');
          // Fallback: show success message
          print('PDF generated successfully but could not save to file');
        }
      }
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }
}
