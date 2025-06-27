import 'package:cosmetic_store/lab/viw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

// ===========================================================================
// DATA MODELS
// ===========================================================================

class LabTest {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String preparation;
  int quantity;

  LabTest({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.preparation,
    this.quantity = 1,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'],
      name: json['name'],
      description: json['short_description'] ?? '',
      price: double.tryParse(json['price'] ?? '0.0') ?? 0.0,
      imageUrl: json['images'] != null && json['images'].isNotEmpty
          ? json['images'][0]['src']
          : 'https://via.placeholder.com/150',
      category: json['categories'] != null && json['categories'].isNotEmpty
          ? json['categories'][0]['name']
          : 'عام',
      preparation: json['meta_data'] != null
          ? json['meta_data'].firstWhere(
              (meta) => meta['key'] == 'preparation', orElse: () => {'value': ''})['value']
          : '',
    );
  }
}

class TestResult {
  final int id;
  final String title;
  final String testDate;
  final String? testType;
  final String? resultFileUrl;
  final String? fileType;

  TestResult({
    required this.id,
    required this.title,
    required this.testDate,
    this.testType,
    this.resultFileUrl,
    this.fileType,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      title: json['title'],
      testDate: json['test_date'] ?? 'N/A',
      testType: json['test_type'],
      resultFileUrl: json['result_file_url'],
      fileType: json['file_type_uploaded'],
    );
  }
}

class UserProfile {
  final String? age;
  final String? weight;
  final String? height;
  final String? bloodGroup;

  UserProfile({this.age, this.weight, this.height, this.bloodGroup});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json['age'],
      weight: json['weight'],
      height: json['height'],
      bloodGroup: json['blood_group'],
    );
  }
}

// ===========================================================================
// MAIN APP ENTRY POINT
// ===========================================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مختبرنا الطبي',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[800],
          elevation: 1,
          titleTextStyle: const TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LabStoreScreen(),
    );
  }
}

enum AppView { auth, store, results, profile, loading }

// ===========================================================================
// MAIN SCREEN WIDGET
// ===========================================================================

class LabStoreScreen extends StatefulWidget {
  const LabStoreScreen({Key? key}) : super(key: key);

  @override
  State<LabStoreScreen> createState() => _LabStoreScreenState();
}

class _LabStoreScreenState extends State<LabStoreScreen> {
  // State Variables
  AppView _currentView = AppView.loading;
  int _bottomNavIndex = 0;

  // Auth State
  final _storage = const FlutterSecureStorage();
  String? _authToken;
  int? _userId;
  String? _displayName;
  bool _isNewUser = false;
  bool _isAuthLoading = false;

  // Store State
  List<LabTest> tests = [];
  List<LabTest> cartItems = [];
  bool isLoading = true;
  bool showCart = false;
  bool showCheckout = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  double totalPrice = 0.0;
  List<dynamic> testCategories = [];
  int? _currentCategoryId;
  bool _isCategoriesVisible = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<String> bannerImages = [
    'https://banner.beytei.com/imeges/banner1.jpg',
    'https://banner.beytei.com/imeges/banner2.jpg',
    'https://banner.beytei.com/imeges/banner3.jpg',
  ];

  // Test Results State
  List<TestResult> _userTestResults = [];
  UserProfile? _userProfile;
  bool _isResultsLoading = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profileAgeController = TextEditingController();
  final TextEditingController _profileWeightController = TextEditingController();
  final TextEditingController _profileHeightController = TextEditingController();
  final TextEditingController _profileBloodController = TextEditingController();

  // API Constants
  static const String _baseUrl = "https://tiby.beytei.com/wp-json";
  static const String _consumerKey = 'ck_cdfdba65d1cff59593a3f5b575ca63749f12f93c';
  static const String _consumerSecret = 'cs_955d77878c353214db64bbb82205f07c5a1a153e';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _tryAutoLogin();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _searchController.dispose();
    _profileNameController.dispose();
    _profileAgeController.dispose();
    _profileWeightController.dispose();
    _profileHeightController.dispose();
    _profileBloodController.dispose();
    super.dispose();
  }

  // ==================== AUTHENTICATION METHODS ====================

  Future<void> _tryAutoLogin() async {
    setState(() => _currentView = AppView.loading);
    String? token = await _storage.read(key: 'auth_token');
    String? userIdStr = await _storage.read(key: 'user_id');
    String? name = await _storage.read(key: 'display_name');

    if (token != null && userIdStr != null && name != null) {
      setState(() {
        _authToken = token;
        _userId = int.tryParse(userIdStr);
        _displayName = name;
        _nameController.text = name;
        _currentView = AppView.store;
      });
      _fetchStoreData();
    } else {
      setState(() => _currentView = AppView.auth);
    }
  }

  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _nameController.text.isEmpty) {
      _showErrorSnackBar('الرجاء إدخال الاسم ورقم الهاتف.');
      return;
    }
    setState(() => _isAuthLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tiby-auth/v1/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': _phoneController.text,
          'name': _nameController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'user_id', value: data['user_id'].toString());
        await _storage.write(key: 'display_name', value: data['display_name']);

        setState(() {
          _authToken = data['token'];
          _userId = data['user_id'];
          _displayName = data['display_name'];
          _isNewUser = data['is_new_user'];
          _profileNameController.text = _displayName ?? '';

          if (_isNewUser) {
            _currentView = AppView.profile;
          } else {
            _currentView = AppView.store;
            _bottomNavIndex = 0;
            _fetchStoreData();
          }
        });
      } else {
        final error = json.decode(response.body);
        _showErrorSnackBar(error['message'] ?? 'فشل تسجيل الدخول.');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في الشبكة. حاول مرة أخرى.');
    } finally {
      setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_authToken == null) return;
    setState(() => _isAuthLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tiby-lab/v1/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'display_name': _profileNameController.text,
          'age': _profileAgeController.text,
          'weight': _profileWeightController.text,
          'height': _profileHeightController.text,
          'blood_group': _profileBloodController.text,
        }),
      );

      if (response.statusCode == 200) {
        await _storage.write(key: 'display_name', value: _profileNameController.text);
        setState(() {
          _displayName = _profileNameController.text;
          if (_isNewUser) {
            _isNewUser = false;
            _currentView = AppView.store;
            _bottomNavIndex = 0;
            _fetchStoreData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح!')),
            );
          }
        });
      } else {
        _showErrorSnackBar('فشل تحديث الملف الشخصي.');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في الشبكة.');
    } finally {
      setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    setState(() {
      _authToken = null;
      _userId = null;
      _displayName = null;
      _currentView = AppView.auth;
      _bottomNavIndex = 0;
      cartItems.clear();
      tests.clear();
      _userTestResults.clear();
      _userProfile = null;
      _phoneController.clear();
      _nameController.clear();
    });
  }

  // ==================== STORE METHODS ====================

  Future<void> _fetchStoreData() async {
    await _fetchLabTests();
    await _fetchTestCategories();
  }

  Future<void> _fetchLabTests({String searchQuery = '', int? categoryId, bool loadMore = false}) async {
    if (!loadMore) {
      _page = 1;
      _hasMore = true;
      setState(() => isLoading = true);
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _page++;
      setState(() => _isLoadingMore = true);
    }

    try {
      String apiUrl = '$_baseUrl/wc/v3/products?page=$_page&per_page=10';
      if (searchQuery.isNotEmpty) apiUrl += '&search=$searchQuery';
      if (categoryId != null && categoryId != 0) apiUrl += '&category=$categoryId';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final fetchedTests = data.map((json) => LabTest.fromJson(json)).toList();

        setState(() {
          if (loadMore) {
            tests.addAll(fetchedTests);
          } else {
            tests = fetchedTests;
          }
          _hasMore = fetchedTests.length == 10;
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
        _showErrorSnackBar('حدث خطأ في جلب البيانات: $e');
      }
    }
  }

  Future<void> _fetchTestCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wc/v3/products/categories?parent=0&per_page=10'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}',
        },
      );

      if (response.statusCode == 200) {
        setState(() => testCategories = json.decode(response.body));
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في جلب الفئات.');
    }
  }

  void _scrollListener() {
    final direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.forward) {
      if (!_isCategoriesVisible) {
        setState(() => _isCategoriesVisible = true);
      }
    } else if (direction == ScrollDirection.reverse) {
      if (_isCategoriesVisible) {
        setState(() => _isCategoriesVisible = false);
      }
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _fetchLabTests(
        searchQuery: _searchController.text,
        categoryId: _currentCategoryId,
        loadMore: true,
      );
    }
  }

  void addToCart(LabTest test) {
    setState(() {
      final existingIndex = cartItems.indexWhere((item) => item.id == test.id);
      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(LabTest(
          id: test.id,
          name: test.name,
          description: test.description,
          price: test.price,
          imageUrl: test.imageUrl,
          category: test.category,
          preparation: test.preparation,
          quantity: 1,
        ));
      }
      _calculateTotal();
      showCart = true;
    });

    _showAddToCartDialog(test);
  }

  void _showAddToCartDialog(LabTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تمت إضافة الفحص"),
        content: Text("${test.name} تمت إضافته إلى سلة الفحوصات"),
        actions: [
          TextButton(
            child: const Text("مواصلة التصفح"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("إتمام الحجز"),
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

  void removeFromCart(LabTest test) {
    setState(() {
      cartItems.removeWhere((item) => item.id == test.id);
      _calculateTotal();
      if (cartItems.isEmpty) showCart = false;
    });
  }

  void updateQuantity(LabTest test, int newQuantity) {
    setState(() {
      final index = cartItems.indexWhere((item) => item.id == test.id);
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

  Future<void> _submitOrder() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _idController.text.isEmpty) {
      _showErrorSnackBar('الرجاء تعبئة جميع الحقول المطلوبة');
      return;
    }

    setState(() => _isAuthLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wc/v3/orders'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "payment_method": "cod",
          "payment_method_title": "الدفع عند الاستلام",
          "customer_note": "حجز فحوصات من تطبيق المختبر",
          "billing": {
            "first_name": _nameController.text,
            "phone": _phoneController.text,
          },
          "meta_data": [
            {
              "key": "patient_address",
              "value": _idController.text
            }
          ],
          "line_items": cartItems.map((test) => {
            "product_id": test.id,
            "quantity": test.quantity,
          }).toList(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد حجز الفحوصات بنجاح، سيتم الاتصال بك لتأكيد الموعد')),
        );

        setState(() {
          cartItems.clear();
          totalPrice = 0.0;
          showCart = false;
          showCheckout = false;
        });
      } else {
        _showErrorSnackBar('فشل في إرسال الطلب: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في إرسال الطلب: $e');
    } finally {
      setState(() => _isAuthLoading = false);
    }
  }

  // ==================== RESULTS METHODS ====================

  Future<void> _fetchTestResults() async {
    if (_userId == null || _authToken == null) return;
    setState(() => _isResultsLoading = true);
    try {
      // [تم الإصلاح] - تم تعديل هذا السطر لإضافة معرف المستخدم إلى الرابط
      final response = await http.get(
        Uri.parse('$_baseUrl/tiby-lab/v1/user-test-results/$_userId'),
        headers: { 'Authorization': 'Bearer $_authToken' },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reportsData = data['test_reports'] as List;
        final userInfoData = data['user_info'];

        setState(() {
          _userTestResults = reportsData.map((item) => TestResult.fromJson(item)).toList();
          _userProfile = UserProfile.fromJson(userInfoData);
        });
      } else {
        _showErrorSnackBar('فشل في جلب نتائج الفحوصات.');
      }
    } catch(e) {
      _showErrorSnackBar('حدث خطأ في الشبكة: $e');
    } finally {
      setState(() => _isResultsLoading = false);
    }
  }

  Future<void> _openResultFile(String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('لا يمكن فتح الملف.');
    }
  }

  // ==================== UI HELPERS ====================

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _currentView = AppView.store;
      }
      if (index == 1) {
        _currentView = AppView.results;
        _fetchTestResults();
      }
      if (index == 2) {
        _profileNameController.text = _displayName ?? '';
        _profileAgeController.text = _userProfile?.age ?? '';
        _profileWeightController.text = _userProfile?.weight ?? '';
        _profileHeightController.text = _userProfile?.height ?? '';
        _profileBloodController.text = _userProfile?.bloodGroup ?? '';
        _currentView = AppView.profile;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  AppBar _buildAppBar() {
    String title = 'المختبر';
    if (_currentView == AppView.results) title = 'نتائجي';
    if (_currentView == AppView.profile) title = 'ملفي الشخصي';

    return AppBar(
      title: Text(title),
      actions: [
        if (_currentView != AppView.auth && _currentView != AppView.loading && _currentView != AppView.profile)
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => setState(() => showCart = !showCart),
          ),
        if (_currentView == AppView.profile && !_isNewUser)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case AppView.loading:
        return const Center(child: CircularProgressIndicator());
      case AppView.auth:
        return _buildLoginView();
      case AppView.store:
        return _buildStoreView();
      case AppView.results:
        return _buildResultsView();
      case AppView.profile:
        return _buildProfileView(isSetup: _isNewUser);
      default:
        return _buildLoginView();
    }
  }

  Widget _buildLoginView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isAuthLoading ? null : _login,
            child: _isAuthLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView({bool isSetup = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (isSetup)
            const Text(
              'إكمال بيانات الملف الشخصي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _profileNameController,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _profileAgeController,
            decoration: const InputDecoration(
              labelText: 'العمر',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _profileWeightController,
            decoration: const InputDecoration(
              labelText: 'الوزن (كجم)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _profileHeightController,
            decoration: const InputDecoration(
              labelText: 'الطول (سم)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _profileBloodController,
            decoration: const InputDecoration(
              labelText: 'فصيلة الدم',
              border: OutlineInputBorder(),
              hintText: 'مثال: A+',
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isAuthLoading ? null : _updateProfile,
            child: _isAuthLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(isSetup ? 'حفظ والمتابعة' : 'تحديث البيانات',
                style: const TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreView() {
    return Column(
      children: [
        _buildBannerSlider(),
        _buildTestCategories(),
        Expanded(
          child: isLoading
              ? _buildShimmerLoading()
              : tests.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70, // Adjusted for better layout
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: tests.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == tests.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildTestCard(tests[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    if (_isResultsLoading) return const Center(child: CircularProgressIndicator());
    if (_userTestResults.isEmpty) return const Center(child: Text('لا توجد نتائج بعد.'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard('فصيلة الدم', _userProfile?.bloodGroup ?? '-', Icons.bloodtype, Colors.red),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard('الوزن', '${_userProfile?.weight ?? '-'} كجم', Icons.monitor_weight, Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('أحدث التقارير', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ..._userTestResults.map((result) => _buildResultCard(result)).toList(),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(TestResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.description_outlined, color: Colors.blue, size: 30),
        title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('تاريخ الفحص: ${result.testDate}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showReportOptions(context, result), // <-- IMPORTANT CHANGE
      ),
    );
  }

  Widget _buildBannerSlider() {
    return CarouselSlider.builder(
      itemCount: bannerImages.length,
      options: CarouselOptions(
        autoPlay: true,
        aspectRatio: 2.0,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      itemBuilder: (context, index, realIdx) {
        return Container(
          margin: const EdgeInsets.all(5.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            child: CachedNetworkImage(
              imageUrl: bannerImages[index],
              fit: BoxFit.cover,
              width: 1000.0,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestCategories() {
    if (testCategories.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isCategoriesVisible ? 100 : 0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: testCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  setState(() => _currentCategoryId = null);
                  _fetchLabTests();
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _currentCategoryId == null ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(Icons.all_inclusive, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),
                    const Text('الكل', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          var category = testCategories[index - 1];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () {
                setState(() => _currentCategoryId = category['id']);
                _fetchLabTests(categoryId: category['id']);
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _currentCategoryId == category['id'] ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: category['image'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: CachedNetworkImage(
                        imageUrl: category['image']['src'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.category),
                      ),
                    )
                        : const Icon(Icons.category, color: Colors.blue),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentCategoryId == category['id'] ? Colors.blue[800] : Colors.black,
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

  Widget _buildTestCard(LabTest test) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTestDetails(test),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: test.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.medical_services, size: 50, color: Colors.blue),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${test.price.toStringAsFixed(2)} دينار',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => addToCart(test),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
                        ),
                        child: const Text('حجز الفحص'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestDetails(LabTest test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    test.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'الفئة: ${test.category}',
                style: TextStyle(color: Colors.blue[800]),
              ),
              const SizedBox(height: 20),
              Center(
                child: CachedNetworkImage(
                  imageUrl: test.imageUrl,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'وصف الفحص:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(test.description),
              const SizedBox(height: 20),
              if (test.preparation.isNotEmpty) ...[
                const Text(
                  'تحضيرات الفحص:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(test.preparation),
                const SizedBox(height: 20),
              ],
              const Text(
                'السعر:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${test.price.toStringAsFixed(2)} دينار',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    addToCart(test);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('حجز الفحص الآن'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
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




  void _showReportOptions(BuildContext context, TestResult result) {
    // Ensure there is a URL to work with
    if (result.resultFileUrl == null || result.resultFileUrl!.isEmpty) {
      _showErrorSnackBar('ملف النتيجة غير متوفر حاليًا.');
      return;
    }

    // Determine file type, default to 'pdf' if not specified
    final fileType = result.fileType ?? 'pdf';

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('عرض النتيجة'),
                onTap: () {
                  Navigator.of(ctx).pop(); // Close the bottom sheet
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReportViewerScreen(
                        fileUrl: result.resultFileUrl!,
                        apiFileType: fileType,
                        reportTitle: result.title,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_for_offline_outlined),
                title: const Text('تنزيل / فتح خارجيًا'),
                onTap: () {
                  Navigator.of(ctx).pop(); // Close the bottom sheet
                  _openResultFile(result.resultFileUrl);
                },
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
          const Icon(
            Icons.search_off,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'لم يتم العثور على فحوصات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'حاول البحث باستخدام مصطلحات أخرى',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _fetchLabTests(),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سلة الفحوصات',
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
                  child: const Text('إتمام الحجز', style: TextStyle(fontSize: 16)),
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

  Widget _buildCartItem(LabTest test) {
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
              imageUrl: test.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${test.price.toStringAsFixed(2)} × ${test.quantity}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: () => updateQuantity(test, test.quantity - 1),
              ),
              Text(test.quantity.toString()),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => updateQuantity(test, test.quantity + 1),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () => removeFromCart(test),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'حجز الموعد',
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
                    'الفحوصات المطلوبة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                ...cartItems.map((test) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text('${test.name} (${test.quantity})')),
                      Text(
                        '${(test.price * test.quantity).toStringAsFixed(2)} دينار',
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
                    'معلومات المريض',
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
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان المنزل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                const ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('اختر موعد الحضور'),
                  subtitle: Text('سيتم تأكيد الموعد معك عبر الهاتف'),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isAuthLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isAuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تأكيد الحجز', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          child: const Icon(Icons.medical_services, color: Colors.white),
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
    bool showBottomNav = _currentView != AppView.auth &&
        _currentView != AppView.loading &&
        !(_currentView == AppView.profile && _isNewUser);

    return Scaffold(
      appBar: _currentView == AppView.auth ? null : _buildAppBar(),
      body: Stack(
        children: [
          _buildCurrentView(),
          if (showCart && cartItems.isNotEmpty && !showCheckout)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCartSummary(),
            ),
          if (showCheckout) _buildCheckoutForm(),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'المختبر'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'فحوصاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'ملفي الشخصي'),
        ],
      )
          : null,
      floatingActionButton:
      _currentView == AppView.store && cartItems.isNotEmpty && !showCart ? _buildCartFab() : null,
    );
  }
}