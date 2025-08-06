import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- إعدادات وثوابت ---
// !! هام: استبدل هذا الرابط برابط موقعك الصحيح
const String YOUR_DOMAIN = 'ph.beytei.com';
const String PHARMACY_API_URL = 'ph.beytei.com/wp-json/beytei-pharmacy/v1';










// --- 1. نماذج البيانات (Data Models) ---

class PharmacyProfile {
  final String tier;
  final int points;
  PharmacyProfile({required this.tier, required this.points});

  factory PharmacyProfile.fromJson(Map<String, dynamic> json) {
    return PharmacyProfile(
      tier: json['tier'] ?? 'غير محدد',
      points: json['points'] ?? 0,
    );
  }
}

class Pharmacy {
  final int id;
  final String name;
  final String logoUrl;
  Pharmacy({required this.id, required this.name, required this.logoUrl});

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'صيدلية غير مسماة',
      logoUrl: json['logo_url'] ?? 'https://i.ibb.co/C0d2y7V/pharma-logo.png',
    );
  }
}

class Product {
  final int id;
  final String name;
  final String imageUrl;
  final String price;
  Product({required this.id, required this.name, required this.imageUrl, required this.price});
}

class Area {
  final int id;
  final String name;
  final int parentId;
  Area({required this.id, required this.name, required this.parentId});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'منطقة غير مسماة',
      parentId: json['parent'] ?? 0,
    );
  }
}

// --- 2. مزود الحالة (Provider) ---

class PharmacyProvider with ChangeNotifier {
  PharmacyProfile? _profile;
  List<Pharmacy> _nearbyPharmacies = [];
  List<Pharmacy> _allPharmacies = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String? _error;

  PharmacyProfile? get profile => _profile;
  List<Pharmacy> get nearbyPharmacies => _nearbyPharmacies;
  List<Pharmacy> get allPharmacies => _allPharmacies;
  List<Product> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomeData({required int areaId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$PHARMACY_API_URL/home_data?area_id=$areaId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _profile = PharmacyProfile.fromJson(data['user_profile']);
        _nearbyPharmacies = (data['nearby_pharmacies'] as List).map((p) => Pharmacy.fromJson(p)).toList();
      } else {
        throw Exception('فشل تحميل البيانات الرئيسية');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPharmacies({required int areaId}) async {
    _isLoading = true;
    notifyListeners();
    // في تطبيق حقيقي، يجب إنشاء API خاص لهذه الدالة في ووردبريس يقبل areaId
    // للتبسيط، سنستخدم نفس بيانات الشاشة الرئيسية هنا
    if (_nearbyPharmacies.isEmpty) await fetchHomeData(areaId: areaId);
    _allPharmacies = _nearbyPharmacies;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllProducts({required int areaId}) async {
    _isLoading = true;
    notifyListeners();
    // في تطبيق حقيقي، يجب إنشاء API خاص لهذه الدالة أيضاً
    // سنستخدم بيانات وهمية للعرض
    _allProducts = [
      Product(id: 201, name: 'Panadol Extra', imageUrl: 'https://i.ibb.co/pW1s4XF/panadol.png', price: '2,500 د.ع'),
      Product(id: 202, name: 'Vitamin C', imageUrl: 'https://i.ibb.co/51bSrCq/vitamin-c.png', price: '7,000 د.ع'),
      Product(id: 203, name: 'Nivea Cream', imageUrl: 'https://i.ibb.co/YdKLsL3/nivea.png', price: '5,000 د.ع'),
      Product(id: 204, name: 'Crest Toothpaste', imageUrl: 'https://i.ibb.co/ZJp5wzD/crest.png', price: '3,000 د.ع'),
    ];
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitSubscription(String fullName) async {
    try {
      final response = await http.post(
        Uri.parse('$PHARMACY_API_URL/subscribe_chronic'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'full_name': fullName}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم'};
    }
  }
}


// --- 3. الودجت الرئيسي وبنية التنقل ---

// الودجت الرئيسي للموديول
class PharmacyModule extends StatelessWidget {
  const PharmacyModule({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PharmacyProvider(),
      child: MaterialApp(
        theme: ThemeData(
          textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
          primaryColor: Colors.blue.shade700,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700),
          scaffoldBackgroundColor: const Color(0xFFF0F4F8),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFFF0F4F8),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(fontFamily: 'Cairo', color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const LocationCheckWrapper(),
      ),
    );
  }
}

// ودجت التحقق من الموقع
class LocationCheckWrapper extends StatefulWidget {
  const LocationCheckWrapper({super.key});
  @override
  State<LocationCheckWrapper> createState() => _LocationCheckWrapperState();
}
class _LocationCheckWrapperState extends State<LocationCheckWrapper> {
  Future<int?> _checkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('pharmacy_selectedAreaId');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _checkLocation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const PharmacyModuleScreen();
        } else {
          return const SelectLocationScreen();
        }
      },
    );
  }
}

// شاشة اختيار الموقع
class SelectLocationScreen extends StatefulWidget {
  final bool isCancellable;
  const SelectLocationScreen({super.key, this.isCancellable = false});
  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}
class _SelectLocationScreenState extends State<SelectLocationScreen> {
  Future<List<Area>>? _areasFuture;
  int? _selectedGovernorateId;
  final String areasApiUrl = '$YOUR_DOMAIN/wp-json/wp/v2/area?per_page=100';

  @override
  void initState() {
    super.initState();
    _areasFuture = _getAreas();
  }

  Future<List<Area>> _getAreas() async {
    final response = await http.get(Uri.parse(areasApiUrl));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List).map((data) => Area.fromJson(data)).toList();
    }
    throw Exception('فشل في جلب المناطق');
  }

  Future<void> _saveSelection(int areaId, String areaName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pharmacy_selectedAreaId', areaId);
    await prefs.setString('pharmacy_selectedAreaName', areaName);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LocationCheckWrapper()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر منطقة الخدمة'), automaticallyImplyLeading: widget.isCancellable),
      body: FutureBuilder<List<Area>>(
        future: _areasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('فشل في جلب المناطق: ${snapshot.error}'));
          }
          final allAreas = snapshot.data!;
          final governorates = allAreas.where((a) => a.parentId == 0).toList();
          final cities = _selectedGovernorateId == null ? <Area>[] : allAreas.where((a) => a.parentId == _selectedGovernorateId).toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'اختر المحافظة', border: OutlineInputBorder()),
                  value: _selectedGovernorateId,
                  items: governorates.map((g) => DropdownMenuItem<int>(value: g.id, child: Text(g.name))).toList(),
                  onChanged: (v) => setState(() => _selectedGovernorateId = v),
                ),
                const SizedBox(height: 20),
                if (_selectedGovernorateId != null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cities.length,
                    itemBuilder: (ctx, i) => Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        title: Text(cities[i].name),
                        onTap: () => _saveSelection(cities[i].id, "${governorates.firstWhere((g) => g.id == _selectedGovernorateId).name} - ${cities[i].name}"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- 4. هيكل التطبيق الرئيسي (الشاشة مع الشريط السفلي) ---

class PharmacyModuleScreen extends StatefulWidget {
  const PharmacyModuleScreen({super.key});
  @override
  State<PharmacyModuleScreen> createState() => _PharmacyModuleScreenState();
}

class _PharmacyModuleScreenState extends State<PharmacyModuleScreen> {
  int _selectedIndex = 0;
  String? _selectedAreaName;
  int? _selectedAreaId;
  List<Widget> _widgetOptions = [];
  bool _isLocationLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLocationAndInitScreens();
  }

  Future<void> _loadLocationAndInitScreens() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAreaId = prefs.getInt('pharmacy_selectedAreaId');
    _selectedAreaName = prefs.getString('pharmacy_selectedAreaName');
    if (_selectedAreaId != null) {
      // استخدام ValueKey يضمن إعادة بناء الويدجت عند تغيير المنطقة
      _widgetOptions = <Widget>[
        PharmacyHomeScreen(key: ValueKey(_selectedAreaId), areaId: _selectedAreaId!),
        PharmaciesListScreen(key: ValueKey(_selectedAreaId), areaId: _selectedAreaId!),
        ProductsListScreen(key: ValueKey(_selectedAreaId), areaId: _selectedAreaId!),
      ];
    }
    setState(() {
      _isLocationLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectLocationScreen(isCancellable: true)));
            // إعادة تحميل البيانات بعد العودة وتغيير المنطقة
            _loadLocationAndInitScreens();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedAreaName ?? 'اختر منطقة', style: const TextStyle(fontSize: 16)),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, size: 28), onPressed: () {}),
        ],
      ),
      body: !_isLocationLoaded
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy_outlined), activeIcon: Icon(Icons.local_pharmacy), label: 'الصيدليات'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'المنتجات'),
        ],
      ),
    );
  }
}

// --- 5. الشاشات الداخلية ---

// 5.1 الشاشة الرئيسية (Home)
class PharmacyHomeScreen extends StatefulWidget {
  final int areaId;
  const PharmacyHomeScreen({super.key, required this.areaId});
  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PharmacyProvider>(context, listen: false).fetchHomeData(areaId: widget.areaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.error != null) return Center(child: Text('حدث خطأ: ${provider.error}'));
        return RefreshIndicator(
          onRefresh: () => provider.fetchHomeData(areaId: widget.areaId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.profile != null) PointsCard(profile: provider.profile!),
              const SizedBox(height: 20),
              const MainActionCard(),
              const SizedBox(height: 20),
              const SubscriptionButtons(),
              const SizedBox(height: 24),
              SectionHeader(title: 'صيدليات تخدم منطقتك'),
              const SizedBox(height: 12),
              NearbyPharmaciesList(pharmacies: provider.nearbyPharmacies),
            ],
          ),
        );
      },
    );
  }
}

// 5.2 شاشة قائمة كل الصيدليات
class PharmaciesListScreen extends StatefulWidget {
  final int areaId;
  const PharmaciesListScreen({super.key, required this.areaId});
  @override
  State<PharmaciesListScreen> createState() => _PharmaciesListScreenState();
}

class _PharmaciesListScreenState extends State<PharmaciesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PharmacyProvider>(context, listen: false).fetchAllPharmacies(areaId: widget.areaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PharmacyProvider>(context);
    return provider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.allPharmacies.length,
      itemBuilder: (context, index) => PharmacyListItemCard(pharmacy: provider.allPharmacies[index]),
    );
  }
}

// 5.3 شاشة قائمة المنتجات
class ProductsListScreen extends StatefulWidget {
  final int areaId;
  const ProductsListScreen({super.key, required this.areaId});
  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PharmacyProvider>(context, listen: false).fetchAllProducts(areaId: widget.areaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PharmacyProvider>(context);
    return provider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.allProducts.length,
      itemBuilder: (context, index) => ProductCard(product: provider.allProducts[index]),
    );
  }
}


// --- 6. شاشات الميزات (Features Screens) ---

// 6.1 شاشة تسجيل الاشتراك
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final provider = Provider.of<PharmacyProvider>(context, listen: false);
      final result = await provider.submitSubscription(_nameController.text);
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog(result['discount_code']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'حدث خطأ غير متوقع')),
        );
      }
    }
  }

  void _showSuccessDialog(String discountCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 تم التسجيل بنجاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('شكراً لتسجيلك في برنامج الأمراض المزمنة.'),
            const SizedBox(height: 20),
            const Text('استخدم كود الخصم التالي لطلباتك:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                discountCode,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800, letterSpacing: 2),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('حسناً'),
            onPressed: () {
              Navigator.of(ctx).pop(); // أغلق الحوار
              Navigator.of(context).pop(); // ارجع من شاشة الاشتراك
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اشتراك الأمراض المزمنة')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text('برنامج الخصومات الخاص بالأمراض المزمنة',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('الرجاء إدخال اسمك الكامل كما هو مسجل في التأمين الصحي أو الوصفة الطبية للاستفادة من الخصومات.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('تسجيل والحصول على الخصم'),
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 6.2 شاشة الدردشة (مثال توضيحي)
class ChatScreen extends StatelessWidget {
  final Pharmacy pharmacy;
  const ChatScreen({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('دردشة مع ${pharmacy.name}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                // مثال على الرسائل
                Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(label: Text('مرحباً، كيف يمكنني مساعدتك؟'), backgroundColor: Colors.white)
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: Chip(label: Text('أهلاً، هل يتوفر لديكم هذا الدواء؟'), backgroundColor: Color(0xFFD1E4FF))
                ),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('ملاحظة: هذه واجهة عرض توضيحية. لعمل الدردشة، يجب ربطها بنظام خلفية للرسائل الفورية مثل Firebase Firestore.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 5, color: Colors.grey.shade200)]),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.camera_alt), onPressed: () {}),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 7. الويدجتات المكونة للشاشات (البطاقات) ---

class PointsCard extends StatelessWidget {
  final PharmacyProfile profile;
  const PointsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(locale: 'ar');
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5)],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الفئة ${profile.tier}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCD7F32))),
          const SizedBox(height: 8),
          const Text('أنت الآن بالفئة البرونزية، أكمل الطلبات لتحصل على ميزات أفضل وأشمل.',
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي النقاط:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Icon(Icons.stars, color: Colors.blue.shade600, size: 22),
                  const SizedBox(width: 8),
                  Text('${numberFormat.format(profile.points)} ألف',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class MainActionCard extends StatelessWidget {
  const MainActionCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            children: [
              Image.network('https://i.ibb.co/C0d2y7V/pharma-logo.png', height: 60),
              const SizedBox(height: 12),
              const Text('صيدليتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionButtons extends StatelessWidget {
  const SubscriptionButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SubscriptionScreen())),
            icon: const Icon(Icons.monitor_heart_outlined, size: 28),
            label: const Text('اشتراك الأمراض المزمنة', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.2)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black87,
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.grey.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ),
        // يمكنك إضافة زر آخر هنا في المستقبل
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Icon(Icons.location_on, color: Colors.red.shade400, size: 20),
      ],
    );
  }
}

class NearbyPharmaciesList extends StatelessWidget {
  final List<Pharmacy> pharmacies;
  const NearbyPharmaciesList({super.key, required this.pharmacies});
  @override
  Widget build(BuildContext context) {
    if (pharmacies.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('لا توجد صيدليات تخدم هذه المنطقة حالياً.')));
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pharmacies.length,
        itemBuilder: (context, index) => PharmacyCard(pharmacy: pharmacies[index]),
      ),
    );
  }
}

class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;
  const PharmacyCard({super.key, required this.pharmacy});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: pharmacy.logoUrl,
                  height: 50,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                const Spacer(),
                Text(pharmacy.name, textAlign: TextAlign.center, maxLines: 2,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PharmacyListItemCard extends StatelessWidget {
  final Pharmacy pharmacy;
  const PharmacyListItemCard({super.key, required this.pharmacy});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CachedNetworkImage(imageUrl: pharmacy.logoUrl, width: 60, height: 60),
            const SizedBox(width: 16),
            Expanded(
              child: Text(pharmacy.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('دردشة'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(pharmacy: pharmacy))),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(product.price, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}