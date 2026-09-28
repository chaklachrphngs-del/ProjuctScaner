import 'package:flutter/material.dart';
import 'db_helper.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Map<String, dynamic>>> _productListFuture;

  @override
  void initState() {
    super.initState();
    _refreshProductList();
  }

  // ฟังก์ชันรีโหลดข้อมูลสินค้าใหม่จาก Database
  void _refreshProductList() {
    setState(() {
      _productListFuture = DBHelper.getAllProducts();
    });
  }

  // Dialog แก้ไขข้อมูลสินค้า
  void _showEditProductDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']);
    final priceController = TextEditingController(
      text: product['price'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("แก้ไขสินค้า (${product['barcode']})"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                await DBHelper.insertOrUpdateProduct(
                  product['barcode'],
                  nameController.text,
                  double.parse(priceController.text),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshProductList(); // รีโหลดข้อมูลหน้าจอ
              }
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // Dialog ยืนยันการลบสินค้า
  void _confirmDelete(String barcode, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณต้องการลบรายการ '$name' หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DBHelper.deleteProduct(barcode);
              if (!mounted) return;
              Navigator.pop(context);
              _refreshProductList(); // รีโหลดข้อมูลหน้าจอ
            },
            child: const Text("ลบ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการสินค้าทั้งหมด'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productListFuture,
        builder: (context, snapshot) {
          // 1. กำลังโหลดข้อมูลจาก Database
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. เกิดข้อผิดพลาดในการดึงข้อมูล
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาด: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 3. กรณีไม่มีข้อมูลสินค้าเลย (ข้อมูลว่างเปล่า/null)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีข้อมูลสินค้าในระบบ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กลับไปหน้าสแกนเพื่อเพิ่มสินค้าชิ้นแรกของคุณ',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 4. กรณีมีข้อมูลสินค้าใน Database
          final products = snapshot.data!;

          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent.shade100,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                title: Text(
                  item['name'] ?? 'ไม่มีชื่อสินค้า',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text('บาร์โค้ด: ${item['barcode']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '฿${item['price']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _showEditProductDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _confirmDelete(item['barcode'], item['name'] ?? ''),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
