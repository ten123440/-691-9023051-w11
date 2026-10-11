import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// โมเดลของสินค้าแต่ละชิ้น
class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String thumbnail;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      // price อาจเป็น int หรือ double จาก API เลยแปลงให้ชัวร์ด้วย toDouble()
      price: (json['price'] as num).toDouble(),
      thumbnail: json['thumbnail'] as String,
    );
  }
}

/// โมเดลของ response ทั้งก้อน เพราะ JSON หลักมี key "products" ครอบ array อยู่
class ProductResponse {
  final List<Product> products;
  final int total;

  const ProductResponse({required this.products, required this.total});

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List;
    return ProductResponse(
      products: productsJson
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}

Future<ProductResponse> fetchProducts() async {
  final response = await http.get(
    Uri.parse('https://dummyjson.com/products'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    return ProductResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  } else {
    throw Exception('Failed to load products');
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<ProductResponse> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product List Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: FutureBuilder<ProductResponse>(
          future: futureProducts,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final products = snapshot.data!.products;
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    leading: Image.network(
                      product.thumbnail,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    ),
                    title: Text(product.title),
                    subtitle: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }

            // ระหว่างรอโหลดข้อมูล
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
