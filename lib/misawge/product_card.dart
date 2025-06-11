import 'package:flutter/material.dart';
import 'product_model.dart'; // تأكد من استيراد نموذج المنتج

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
            child: Text('أضف إلى السلة'),
          ),
        ],
      ),
    );
  }
}