import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MiswakProductsScreen extends StatefulWidget {
  const MiswakProductsScreen({Key? key}) : super(key: key);

  @override
  _MiswakProductsScreenState createState() => _MiswakProductsScreenState();
}

class _MiswakProductsScreenState extends State<MiswakProductsScreen> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMiswakProducts();
  }

  Future<void> fetchMiswakProducts() async {
    final url = Uri.parse('https://your-wordpress-site.com/wp-json/wc/v3/products?category=miswak');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic YOUR_API_KEY'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسواك بيتي'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      imageUrl: json['images'][0]['src'] ?? '',
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Image.network(product.imageUrl, height: 120),
          Text(product.name),
          Text('${product.price} ريال'),
          ElevatedButton(
            onPressed: () {},
            child: const Text('أضف إلى السلة'),
          ),
        ],
      ),
    );
  }
}