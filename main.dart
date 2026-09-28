import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db_helper.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PriceScannerScreen(),
    ),
  );
}

class PriceScannerScreen extends StatefulWidget {
  const PriceScannerScreen({super.key});

  @override
  State<PriceScannerScreen> createState() => _PriceScannerScreenState();
}

class _PriceScannerScreenState extends State<PriceScannerScreen> {
  bool isScanning = true;

  // ฟังก์ชันเมื่อสแกนเจอเจอบาร์โค้ด
  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String barcode = barcodes.first.rawValue!;

      setState(() => isScanning = false); // หยุดสแกนชั่วคราวเพื่อประมวลผล

      // ค้นหาข้อมูลใน DB
      final product = await DBHelper.getProduct(barcode);

      if (!mounted) return;

      if (product != null) {
        // กรณีเจอสินค้า -> แสดงราคา
        _showPriceDialog(product['name'], product['price'].toString());
      } else {
        // กรณีไม่เจอ -> ให้ลงทะเบียนราคาใหม่
        _showAddProductDialog(barcode);
      }
    }
  }

  // Dialog แสดงราคาขาย (ตัวใหญ่ชัดเจน)
  void _showPriceDialog(String name, String price) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ราคาขาย",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              "฿$price",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true); // กลับมาสแกนต่อ
            },
            child: const Text("ตกลง / สแกนชิ้นต่อไป"),
          ),
        ],
      ),
    );
  }

  // Dialog บันทึกสินค้าใหม่
  void _showAddProductDialog(String barcode) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("ไม่พบสินค้า ($barcode)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("กรอกข้อมูลเพื่อบันทึกราคาไว้ใช้ครั้งถัดไป"),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "ชื่อสินค้า"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "ราคาขาย (บาท)"),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true);
            },
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                await DBHelper.insertOrUpdateProduct(
                  barcode,
                  nameController.text,
                  double.parse(priceController.text),
                );
                if (!mounted) return;
                Navigator.pop(context);
                setState(() => isScanning = true);
              }
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนเช็คราคาด่วน'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // สี่เหลี่ยมมาร์กตำแหน่งสแกน
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ส่องบาร์โค้ดให้อยู่ในกรอบเพื่อเช็คราคา',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
