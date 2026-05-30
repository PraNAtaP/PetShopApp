import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';

class PdfInvoiceService {
  static final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static Future<void> generateOrderInvoice(OrderModel order, String customerName) async {
    final pdf = pw.Document();
    
    // Load logo image
    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('lib/assets/img/1776076564947.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Could not load logo image: $e');
    }

    final dateStr = order.createdAt != null 
        ? DateFormat('dd MMM yyyy HH:mm').format(order.createdAt!) 
        : DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 60, height: 60),
                ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('PET POINT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('Nota Pembayaran Pesanan', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 12),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No Nota:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('#${order.orderId.substring(0, 8).toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pelanggan:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(customerName, style: const pw.TextStyle(fontSize: 9)),
                ]
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text('Produk Fisik', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 4),
              ...order.items.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('${item.nama} (${item.jumlah}x)', style: const pw.TextStyle(fontSize: 9))),
                    pw.Text(currencyFormatter.format(item.hargaSatuan * item.jumlah), style: const pw.TextStyle(fontSize: 9)),
                  ],
                );
              }).toList(),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bayar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(currencyFormatter.format(order.totalHarga), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Metode:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(order.metodePembayaran, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Status:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(order.statusBayar, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Terima kasih!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Barang yang sudah dibeli tidak dapat ditukar', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700))),
            ],
          );
        },
      ),
    );

    await _downloadPdf(pdf, 'Nota_Pesanan_${order.orderId.substring(0, 8)}.pdf');
  }

  static Future<void> generateGroomingInvoice(GroomingBookingModel booking) async {
    final pdf = pw.Document();
    
    // Load logo image
    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('lib/assets/img/1776076564947.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Could not load logo image: $e');
    }

    final dateStr = DateFormat('dd MMM yyyy HH:mm').format(booking.createdAt);
    final bookingDateStr = DateFormat('dd MMM yyyy').format(booking.bookingDate);
    final shortId = booking.bookingId.length > 8 ? booking.bookingId.substring(0, 8).toUpperCase() : booking.bookingId.toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 60, height: 60),
                ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('PET POINT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('Nota Grooming', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 12),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No Nota:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('#$shortId', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Dibuat Tgl:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pelanggan:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(booking.customerName, style: const pw.TextStyle(fontSize: 9)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Hewan:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(booking.petName, style: const pw.TextStyle(fontSize: 9)),
                ]
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text('Layanan Grooming', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Jadwal: $bookingDateStr - ${booking.timeSlot}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text(booking.serviceType, style: const pw.TextStyle(fontSize: 9))),
                  pw.Text(currencyFormatter.format(booking.totalPrice), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bayar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(currencyFormatter.format(booking.totalPrice), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Metode:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(booking.metodePembayaran, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Status:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(booking.status, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Terima kasih!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            ],
          );
        },
      ),
    );

    await _downloadPdf(pdf, 'Nota_Grooming_$shortId.pdf');
  }

  static Future<void> _downloadPdf(pw.Document pdf, String filename) async {
    try {
      final bytes = await pdf.save();
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch(e) {
      debugPrint("Error saving PDF: $e");
    }
  }
}
