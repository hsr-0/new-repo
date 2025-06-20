import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
          ? json['images'][0]['src'].replaceAll('.jpg', '-300x300.jpg')
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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  double totalPrice = 0.0;
  List<dynamic> mainCategories = [];
  int? _currentCategoryId;
  bool _isConnected = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  List<String> bannerImages = [
    'https://beytei.com/wp-content/uploads/2023/05/banner1.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner2.jpg',
    'https://beytei.com/wp-content/uploads/2023/05/banner3.jpg',
  ];
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _checkConnection();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() => _isConnected = connectivityResult != ConnectivityResult.none);

    if (_isConnected) {
      await Future.wait([
        _fetchProducts(),
        _fetchMainCategories(),
      ]);
    }
  }

  Future<void> _fetchProducts({String searchQuery = '', int? categoryId, bool loadMore = false}) async {
    if (!loadMore) {
      _page = 1;
      _hasMore = true;
      setState(() => isLoading = true);
    } else {
      if (!_hasMore) return;
      _page++;
      setState(() => _isLoadingMore = true);
    }

    try {
      const consumerKey = 'ck_86b62f6fe8a298a5f9d564d70d689db81b9255ed';
      const consumerSecret = 'cs_b2de9b284f6245c8297caaf37976d899d6789ab2';

      String apiUrl = 'https://beytei.com/wp-json/wc/v3/products?page=$_page&per_page=10';
      if (searchQuery.isNotEmpty) apiUrl += '&search=$searchQuery';
      if (categoryId != null && categoryId != 0) apiUrl += '&category=$categoryId';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final fetchedProducts = data.map((json) => Product.fromJson(json)).toList();

        setState(() {
          if (loadMore) {
            products.addAll(fetchedProducts);
          } else {
            products = fetchedProducts;
          }
          _hasMore = fetchedProducts.length == 10;
          isLoading = false;
          _isLoadingMore = false;
          _currentCategoryId = categoryId;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
      });
      if (!loadMore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
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
        setState(() => mainCategories = json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _fetchProducts(
        searchQuery: _searchController.text,
        categoryId: _currentCategoryId,
        loadMore: true,
      );
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
      builder: (context) => AlertDialog(
        title: const Text("تمت الإضافة إلى السلة"),
        content: Text("${product.name} تمت إضافته إلى سلة التسوق"),
        actions: [
          TextButton(
            child: const Text("مواصلة التسوق"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("إتمام الطلب"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400]),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                showCart = true;
                showCheckout = true;
              });
            },
          ),
        ],
      ),
    );
  }

  void removeFromCart(Product product) {
    setState(() {
      cartItems.removeWhere((item) => item.id == product.id);
      _calculateTotal();
      if (cartItems.isEmpty) showCart = false;
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
      if (cartItems.isEmpty) showCart = false;
    });
  }

  void _calculateTotal() {
    totalPrice = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _showCheckoutForm() => setState(() => showCheckout = true);
  void _hideCheckoutForm() => setState(() => showCheckout = false);

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
      final response = await http.post(
        Uri.parse('https://beytei.com/wp-json/wc/v3/orders'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
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
          "line_items": cartItems.map((product) => {
            "product_id": product.id,
            "quantity": product.quantity,
          }).toList(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد طلبك بنجاح انتظر اتصال المندوب !')),
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
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider(
            items: bannerImages.map((imageUrl) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )).toList(),
            options: CarouselOptions(
              height: 140,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.92,
              onPageChanged: (index, _) => setState(() => _currentBannerIndex = index),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              children: bannerImages.map((url) {
                int index = bannerImages.indexOf(url);
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index
                        ? Colors.blue[800]
                        : Colors.white.withOpacity(0.7),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategories() {
    if (mainCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mainCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  setState(() => _currentCategoryId = null);
                  _fetchProducts();
                },
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _currentCategoryId == null
                            ? Colors.blue[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.all_inclusive, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'الكل',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentCategoryId == null
                            ? Colors.blue[800]
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          var category = mainCategories[index - 1];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () {
                setState(() => _currentCategoryId = category['id']);
                _fetchProducts(categoryId: category['id']);
              },
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _currentCategoryId == category['id']
                          ? Colors.blue[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: category['image'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: CachedNetworkImage(
                        imageUrl: category['image']['src'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 1.5)),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.category, color: Colors.blue),
                      ),
                    )
                        : const Icon(Icons.category, color: Colors.blue),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _currentCategoryId == category['id']
                          ? Colors.blue[800]
                          : Colors.black,
                    ),
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
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[100],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
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
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 1.0)),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 20, color: Colors.grey),
              ),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) => _buildCartItem(cartItems[index]),
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
                onPressed: () => setState(() => showCart = false),
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
            ...cartItems.map((product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(child: Text('${product.name} (${product.quantity})')),
                  Text(
                    '${(product.price * product.quantity).toStringAsFixed(2)} دينار',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )).toList(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${totalPrice.toStringAsFixed(2)} دينار',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 20,
                      width: 80,
                      color: Colors.grey[200],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isConnected ? Icons.search_off : Icons.wifi_off,
            size: 80,
            color: Colors.blue[200],
          ),
          const SizedBox(height: 20),
          Text(
            _isConnected ? 'لم يتم العثور على منتجات' : 'لا يوجد اتصال بالإنترنت',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _isConnected
                ? 'حاول البحث باستخدام مصطلحات أخرى'
                : 'يرجى التحقق من اتصالك بالإنترنت',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!_isConnected)
            ElevatedButton(
              onPressed: _checkConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('إعادة المحاولة'),
            ),
        ],
      ),
    );
  }

  Widget _buildCartFab() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          onPressed: () => setState(() => showCart = true),
          backgroundColor: Colors.blue[800],
          child: const Icon(Icons.shopping_cart),
          elevation: 6,
        ),
        if (cartItems.isNotEmpty)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                cartItems.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسواك بيتي', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[600]!],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'شنو محتاج اليوم ؟...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    _fetchProducts();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (query) {
                if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                  _fetchProducts(
                    searchQuery: query,
                    categoryId: _currentCategoryId,
                  );
                });
              },
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => setState(() => showCart = !showCart),
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
              _buildBannerSlider(),
              _buildMainCategories(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _fetchProducts(
                      searchQuery: _searchController.text,
                      categoryId: _currentCategoryId,
                    );
                  },
                  child: isLoading
                      ? _buildShimmerLoading()
                      : products.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildProductCard(products[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
          if (showCart && cartItems.isNotEmpty && !showCheckout)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCartSummary(),
            ),
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
      floatingActionButton: cartItems.isNotEmpty && !showCart ? _buildCartFab() : null,
    );
  }
}