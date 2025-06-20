import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مسواك بيتي',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      debugShowCheckedModeBanner: false,
      home: const MiswakStoreScreen(),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.tryParse(json['price'] ?? '0.0') ?? 0.0,
      imageUrl: json['images'] != null && json['images'].isNotEmpty
          ? json['images'][0]['src']
          : 'https://via.placeholder.com/150',
    );
  }
}

class MiswakStoreScreen extends StatefulWidget {
  const MiswakStoreScreen({Key? key}) : super(key: key);

  @override
  State<MiswakStoreScreen> createState() => _MiswakStoreScreenState();
}

class _MiswakStoreScreenState extends State<MiswakStoreScreen> {
  List<Product> products = [];
  List<Product> cartItems = [];
  bool isLoading = true;
  bool showCart = false;
  bool showCheckout = false;
  double totalPrice = 0.0;
  int selectedCategory = 0;
  List<dynamic> mainCategories = [];
  List<String> bannerImages = [
    'https://beytei.com/wp-content/uploads/2023/05/banner1.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner2.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner3.jpg',
  ];
  int _currentBannerIndex = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final List<Map<String, dynamic>> categories = [
    {'id': 0, 'name': 'الكل'},
    {'id': 15, 'name': 'مساويك فردية'},
    {'id': 16, 'name': 'عبوات عائلية'},
    {'id': 17, 'name': 'هدايا'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchMainCategories();
  }

  Future<void> _fetchProducts() async {
    try {
      const consumerKey = 'ck_86b62f6fe8a298a5f9d564d70d689db81b9255ed';
      const consumerSecret = 'cs_b2de9b284f6245c8297caaf37976d899d6789ab2';
      String categoryFilter = selectedCategory > 0 ? '&category=$selectedCategory' : '';

      final response = await http.get(
        Uri.parse('https://beytei.com/wp-json/wc/v3/products?$categoryFilter'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل المنتجات: $e')),
      );
    }
  }

  Future<void> _fetchMainCategories() async {
    try {
      const consumerKey = 'ck_86b62f6fe8a298a5f9d564d70d689db81b9255ed';
      const consumerSecret = 'cs_b2de9b284f6245c8297caaf37976d899d6789ab2';

      final response = await http.get(
        Uri.parse('https://beytei.com/wp-json/wc/v3/products/categories?parent=0&per_page=3'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          mainCategories = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void addToCart(Product product) {
    setState(() {
      final existingIndex = cartItems.indexWhere((item) => item.id == product.id);
      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          quantity: 1,
        ));
      }
      _calculateTotal();
      showCart = true;
    });

    _showAddToCartDialog(product);
  }

  void _showAddToCartDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("تمت الإضافة إلى السلة"),
          content: Text("${product.name} تمت إضافته إلى سلة التسوق"),
          actions: [
            TextButton(
              child: Text("مواصلة التسوق"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("إتمام الطلب"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  showCart = true;
                  showCheckout = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void removeFromCart(Product product) {
    setState(() {
      cartItems.removeWhere((item) => item.id == product.id);
      _calculateTotal();
      if (cartItems.isEmpty) {
        showCart = false;
      }
    });
  }

  void updateQuantity(Product product, int newQuantity) {
    setState(() {
      final index = cartItems.indexWhere((item) => item.id == product.id);
      if (index >= 0) {
        if (newQuantity > 0) {
          cartItems[index].quantity = newQuantity;
        } else {
          cartItems.removeAt(index);
        }
        _calculateTotal();
      }
      if (cartItems.isEmpty) {
        showCart = false;
      }
    });
  }

  void _calculateTotal() {
    totalPrice = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _showCheckoutForm() {
    setState(() {
      showCheckout = true;
    });
  }

  void _hideCheckoutForm() {
    setState(() {
      showCheckout = false;
    });
  }

  void _submitOrder() {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول')),
      );
      return;
    }

    _sendOrderToWooCommerce();
  }

  Future<void> _sendOrderToWooCommerce() async {
    const consumerKey = 'ck_86b62f6fe8a298a5f9d564d70d689db81b9255ed';
    const consumerSecret = 'cs_b2de9b284f6245c8297caaf37976d899d6789ab2';

    try {
      Map<String, dynamic> orderData = {
        "payment_method": "cod",
        "payment_method_title": "الدفع عند الاستلام",
        "customer_note": "طلب من تطبيق مسواك بيتي",
        "billing": {
          "first_name": _nameController.text,
          "phone": _phoneController.text,
        },
        "shipping": {
          "address_1": _addressController.text,
        },
        "line_items": cartItems.map((product) {
          return {
            "product_id": product.id,
            "quantity": product.quantity,
          };
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('https://beytei.com/wp-json/wc/v3/orders'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد طلبك بنجاح!')),
        );

        setState(() {
          cartItems.clear();
          totalPrice = 0.0;
          showCart = false;
          showCheckout = false;
          _nameController.clear();
          _phoneController.clear();
          _addressController.clear();
        });
      } else {
        throw Exception('فشل إرسال الطلب: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في إرسال الطلب: $e')),
      );
    }
  }

  Widget _buildBannerSlider() {
    return Column(
      children: [
        CarouselSlider(
          items: bannerImages.map((imageUrl) {
            return Container(
              margin: EdgeInsets.all(5.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 2.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerImages.map((url) {
            int index = bannerImages.indexOf(url);
            return Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerIndex == index
                    ? Colors.blue[800]
                    : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMainCategories() {
    if (mainCategories.isEmpty) return SizedBox.shrink();

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mainCategories.length,
        itemBuilder: (context, index) {
          var category = mainCategories[index];
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedCategory = category['id'];
                  isLoading = true;
                });
                _fetchProducts();
              },
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: category['image'] != null
                        ? Image.network(category['image']['src'], fit: BoxFit.cover)
                        : Icon(Icons.category),
                  ),
                  SizedBox(height: 5),
                  Text(
                    category['name'],
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              product.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  product.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(2)} دينار',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => addToCart(product),
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 20, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.price.toStringAsFixed(2)} × ${product.quantity}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: () => updateQuantity(product, product.quantity - 1),
              ),
              Text(product.quantity.toString()),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => updateQuantity(product, product.quantity + 1),
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () => removeFromCart(product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'السلة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${totalPrice.toStringAsFixed(2)} دينار',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(cartItems[index]);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _showCheckoutForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('إتمام الطلب', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  setState(() {
                    showCart = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إتمام الطلب',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _hideCheckoutForm,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 15),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'ملخص الطلب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ...cartItems.map((product) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${product.name} (${product.quantity})'),
                    ),
                    Text(
                      '${(product.price * product.quantity).toStringAsFixed(2)} دينار',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${totalPrice.toStringAsFixed(2)} دينار',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'معلومات العميل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'عنوان التوصيل',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('تأكيد الطلب', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسواك بيتي', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    showCart = !showCart;
                  });
                },
                icon: const Icon(Icons.shopping_cart),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cartItems.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // البنر القلاب
              _buildBannerSlider(),

              // الفئات الرئيسية
              _buildMainCategories(),

              // فئات المنتجات
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ChoiceChip(
                        label: Text(categories[index]['name']),
                        selected: selectedCategory == categories[index]['id'],
                        selectedColor: Colors.blue[800],
                        labelStyle: TextStyle(
                          color: selectedCategory == categories[index]['id']
                              ? Colors.white
                              : Colors.black,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = categories[index]['id'];
                            isLoading = true;
                          });
                          _fetchProducts();
                        },
                      ),
                    );
                  },
                ),
              ),

              // قائمة المنتجات
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                    ? const Center(child: Text('لا توجد منتجات متاحة'))
                    : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
              ),
            ],
          ),

          // سلة التسوق
          if (showCart && cartItems.isNotEmpty && !showCheckout)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCartSummary(),
            ),

          // نموذج الدفع
          if (showCheckout)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: _buildCheckoutForm(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}