import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase & Chat UI
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// تأكد من مسار الاستيراد الخاص بك هنا
import '../beytei_re/re.dart';

// =============================================================================
// 🚀 الدالة الذكية لفتح الدعم الفني (بدون أي تأخير أو تحميل)
// =============================================================================
class SupportSystemHelper {
  static Future<void> openSmartSupportChat(BuildContext context) async {
    String tName = '';
    String tPhone = '';
    String oName = '';
    String oPhone = '';
    String oId = '';

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. جلب بيانات التكسي
      tName = prefs.getString('firstname') ?? '';
      tPhone = prefs.getString('mobile') ?? '';

      // 2. جلب بيانات المطاعم/المسواك
      final orders = await OrderHistoryService().getOrders();
      if (orders.isNotEmpty) {
        final lastOrder = orders.first;
        oName = lastOrder.customerName;
        oPhone = lastOrder.phone;
        oId = lastOrder.id.toString();
      }
    } catch (e) {
      print("خطأ في جلب بيانات الدعم: $e");
    }

    if (context.mounted) {
      // فتح الشاشة فوراً بدون أي مؤشر تحميل
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportUserChatScreen(
            taxiName: tName,
            taxiPhone: tPhone,
            orderName: oName,
            orderPhone: oPhone,
            orderId: oId,
          ),
        ),
      );
    }
  }
}

// =============================================================================
// 💬 شاشة دردشة الزبون (التصميم العصري بدون تسجيل)
// =============================================================================
class SupportUserChatScreen extends StatefulWidget {
  final String taxiName;
  final String taxiPhone;
  final String orderName;
  final String orderPhone;
  final String orderId;

  const SupportUserChatScreen({
    super.key,
    required this.taxiName,
    required this.taxiPhone,
    required this.orderName,
    required this.orderPhone,
    required this.orderId,
  });

  @override
  State<SupportUserChatScreen> createState() => _SupportUserChatScreenState();
}

class _SupportUserChatScreenState extends State<SupportUserChatScreen> {
  List<types.Message> _messages = [];
  types.User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _silentLoginAndInitChat();
  }

  Future<void> _silentLoginAndInitChat() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      String firebaseUid = userCredential.user!.uid;

      setState(() {
        _user = types.User(id: firebaseUid);
      });

      // تحديد الاسم والرقم الأساسي للواجهة
      String primaryName = widget.taxiName.isNotEmpty ? widget.taxiName : (widget.orderName.isNotEmpty ? widget.orderName : 'زبون بيتي');
      String primaryPhone = widget.taxiPhone.isNotEmpty ? widget.taxiPhone : (widget.orderPhone.isNotEmpty ? widget.orderPhone : 'غير متوفر');

      await FirebaseFirestore.instance.collection('support_users').doc(firebaseUid).set({
        'name': primaryName,
        'phone': primaryPhone,
        'taxiName': widget.taxiName,
        'taxiPhone': widget.taxiPhone,
        'orderName': widget.orderName,
        'orderPhone': widget.orderPhone,
        'orderId': widget.orderId,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _initNotifications(firebaseUid);
      _loadMessages(firebaseUid);
    } catch (e) {
      print("Error in silent login: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initNotifications(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('support_users').doc(userId).set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  void _loadMessages(String firebaseUid) {
    FirebaseFirestore.instance.collection('support_chats').doc(firebaseUid).collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots().listen((snapshot) {
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        final updatedData = {...data, 'author': {'id': data['authorId'] ?? ''}, 'id': doc.id};
        switch (data['type']) {
          case 'image': return types.ImageMessage.fromJson(updatedData);
          default: return types.TextMessage.fromJson(updatedData);
        }
      }).toList();
      if (mounted) setState(() { _messages = newMessages; });
    });
  }

  void _addMessage(types.Message message) {
    setState(() { _messages.insert(0, message); });
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    if (_user == null) return;
    final textMessage = types.TextMessage(
        author: _user!, createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(), text: message.text, status: types.Status.sending
    );
    _addMessage(textMessage);
    await _saveAndNotify(textMessage, textMessage.text);
  }

  Future<void> _handleImageSelection() async {
    if (_user == null) return;
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result == null) return;

    final bytes = await result.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final message = types.ImageMessage(
        author: _user!, id: const Uuid().v4(), createdAt: DateTime.now().millisecondsSinceEpoch,
        name: result.name, size: bytes.length, uri: result.path,
        width: image.width.toDouble(), height: image.height.toDouble(), status: types.Status.sending
    );
    _addMessage(message);

    const String uploadUrl = 'https://iraqed.beytei.com/wp-json/beytei-chat/v1/upload-file';
    const String secretKey = 'beytei93@beytei';
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..headers['X-Auth-Token'] = secretKey
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: result.name));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        final updatedMessage = message.copyWith(uri: jsonResponse['file_url'], status: types.Status.sent);
        await _saveAndNotify(updatedMessage, '📷 مرفق صورة');
      } else {
        _updateMessageStatus(message.id, types.Status.error);
      }
    } catch (e) {
      _updateMessageStatus(message.id, types.Status.error);
    }
  }

  void _updateMessageStatus(String id, types.Status status) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) _messages[index] = _messages[index].copyWith(status: status);
    });
  }

  Future<void> _saveAndNotify(types.Message message, String lastMessageText) async {
    if (_user == null) return;

    // 1. تجهيز بيانات الرسالة وحفظها
    Map<String, dynamic> messageJson = message.toJson();
    messageJson.removeWhere((key, value) => key == 'author' || key == 'id');
    messageJson['authorId'] = message.author.id;

    await FirebaseFirestore.instance.collection('support_chats').doc(_user!.id).collection('messages').doc(message.id).set(messageJson);

    // تحديث حالة الرسالة
    await FirebaseFirestore.instance.collection('support_chats').doc(_user!.id).collection('messages').doc(message.id).update({'status': types.Status.sent.name});

    // تحضير بيانات المستخدم للإشعار
    String primaryName = widget.taxiName.isNotEmpty ? widget.taxiName : (widget.orderName.isNotEmpty ? widget.orderName : 'زبون بيتي');
    String primaryPhone = widget.taxiPhone.isNotEmpty ? widget.taxiPhone : (widget.orderPhone.isNotEmpty ? widget.orderPhone : 'غير متوفر');

    // تحديث آخر رسالة في وثيقة الشات الرئيسية
    await FirebaseFirestore.instance.collection('support_chats').doc(_user!.id).set({
      'userName': primaryName,
      'userPhone': primaryPhone,
      'taxiName': widget.taxiName,
      'taxiPhone': widget.taxiPhone,
      'orderName': widget.orderName,
      'orderPhone': widget.orderPhone,
      'orderId': widget.orderId,
      'lastMessage': {'text': lastMessageText, 'timestamp': FieldValue.serverTimestamp(), 'authorId': _user!.id}
    }, SetOptions(merge: true));

    // 2. إرسال الإشعار للسيرفر مع معالجة الأخطاء بوضوح
    try {
      final response = await http.post(
        Uri.parse('https://iraqed.beytei.com/wp-json/beytei-chat/v1/notify-admin-on-reply'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': 'beytei93@beytei'
        },
        body: jsonEncode({
          'userName': primaryName,
          'userPhone': primaryPhone, // إضافة الرقم للمساعدة في التحديد
          'messageText': lastMessageText,
          'chatId': _user!.id // إرسال معرف الشات لتحديد المستقبل بدقة
        }),
      );

      if (response.statusCode == 200) {
        print("✅ تم إرسال إشعار الدعم بنجاح");
      } else {
        print("❌ فشل إرسال إشعار الدعم. الكود: ${response.statusCode}");
        print(" رد السيرفر: ${response.body}");
        // هنا يمكنك إظهار تنبيه للمستخدم إذا أردت
      }
    } catch (e) {
      print(" خطأ في الاتصال بسيرفر الإشعارات: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String primaryName = widget.taxiName.isNotEmpty ? widget.taxiName : (widget.orderName.isNotEmpty ? widget.orderName : 'زبون بيتي');

    return Scaffold(
      appBar: AppBar(
        title: const Text('دعم بيتي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onLongPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportAdminLoginScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.security, color: Colors.white.withOpacity(0.15), size: 18),
            ),
          )
        ],
      ),
      body: Chat(
        messages: _messages,
        onAttachmentPressed: _handleImageSelection,
        onSendPressed: _handleSendPressed,
        user: _user!,
        theme: DefaultChatTheme(
            primaryColor: Colors.teal.shade600,
            secondaryColor: Colors.grey.shade200,
            inputBackgroundColor: Colors.white,
            inputTextColor: Colors.black87,
            attachmentButtonIcon: Icon(Icons.add_photo_alternate_outlined, color: Colors.teal.shade600),
            sendButtonIcon: Icon(Icons.send_rounded, color: Colors.teal.shade600),
            backgroundColor: const Color(0xFFF5F7FA)
        ),
        l10n: const ChatL10nEn(inputPlaceholder: 'اكتب رسالتك لفريق الدعم...'),
        emptyState: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 15),
                Text('أهلاً بك $primaryName!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                const SizedBox(height: 5),
                const Text('فريقنا متواجد لخدمتك، كيف يمكننا مساعدتك؟', style: TextStyle(color: Colors.grey)),
              ],
            )
        ),
      ),
    );
  }
}

// =============================================================================
// 🔐 بوابة دخول المشرفين (Admin Login مع تسجيل الدخول التلقائي)
// =============================================================================
class SupportAdminLoginScreen extends StatefulWidget {
  const SupportAdminLoginScreen({super.key});
  @override State<SupportAdminLoginScreen> createState() => _SupportAdminLoginScreenState();
}

class _SupportAdminLoginScreenState extends State<SupportAdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  // ✨ التحقق مما إذا كان الإدمن مسجلاً مسبقاً لمنع خروجه
  Future<void> _checkExistingLogin() async {
    User? user = FirebaseAuth.instance.currentUser;
    // التأكد أن المستخدم مسجل دخول وأنه ليس زبوناً (الزبون مجهول Anonymous)
    if (user != null && !user.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SupportAdminListScreen()));
        }
      });
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      // 1. تسجيل الدخول عبر Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim()
      );

      String adminUid = userCredential.user!.uid;
      String adminEmail = _emailController.text.trim();

      // 2. جلب توكن الإشعارات (FCM Token)
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        // أ. حفظ التوكن في Firestore تحت مجموعة 'support_admins' (ضروري لعمل الإشعارات المباشرة)
        await FirebaseFirestore.instance.collection('support_admins').doc(adminUid).set({
          'email': adminEmail,
          'fcmToken': fcmToken,
          'lastLogin': FieldValue.serverTimestamp(),
          'name': adminEmail.split('@')[0], // اسم بسيط مشتق من الإيميل
          'isActive': true
        }, SetOptions(merge: true));

        print("✅ تم حفظ توكن المشرف في Firestore بنجاح");

        // ب. إرسال التوكن للسيرفر الخارجي (WordPress Endpoint) كخطوة إضافية
        try {
          final response = await http.post(
              Uri.parse('https://iraqed.beytei.com/wp-json/beytei-chat/v1/update-admin-fcm-token'),
              headers: {'Content-Type': 'application/json', 'X-Auth-Token': 'beytei93@beytei'},
              body: jsonEncode({'email': adminEmail, 'fcmToken': fcmToken})
          );

          if (response.statusCode == 200) {
            print("✅ تم تحديث التوكن في السيرفر الخارجي بنجاح");
          } else {
            print("️ تحذير: فشل تحديث التوكن في السيرفر الخارجي. الكود: ${response.statusCode} | الرد: ${response.body}");
          }
        } catch (e) {
          print("⚠️ خطأ في الاتصال بالسيرفر الخارجي لتحديث التوكن: $e");
          // لا نوقف العملية هنا لأن التوكن محفوظ بالفعل في Firestore
        }
      } else {
        print("️ تحذير: فشل الحصول على FCM Token للمشرف. تأكد من إعدادات Firebase.");
      }

      // 3. الانتقال إلى شاشة القائمة إذا كانت الواجهة نشطة
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SupportAdminListScreen()));
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'بيانات الدخول غير صحيحة';

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'هذا البريد الإلكتروني غير مسجل، أو البيانات خاطئة.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'كلمة المرور التي أدخلتها خاطئة.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'تم حظر هذا الحساب من قبل الإدارة.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'خدمة الدخول بالبريد غير مفعلة في Firebase.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ غير متوقع: $e'), backgroundColor: Colors.red)
        );
      }
      print("❌ خطأ عام في عملية تسجيل الدخول: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF1E3C72),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
        body: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, size: 90, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text("بوابة الدعم الفني", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 40),
                      TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              hintText: 'البريد الإلكتروني',
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                      ),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                              hintText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text('تسجيل الدخول للمركز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                        ),
                      )
                    ]
                )
            )
        )
    );
  }
}

// =============================================================================
// 📋 قائمة محادثات الدعم (Admin Dashboard)
// =============================================================================
class SupportAdminListScreen extends StatelessWidget {
  const SupportAdminListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('تذاكر الدعم الفني', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.pop(context);
          })
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('support_chats').orderBy('lastMessage.timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, size: 70, color: Colors.grey.shade400), const SizedBox(height: 10), const Text('لا توجد طلبات دعم في الوقت الحالي', style: TextStyle(color: Colors.grey))]));
          }
          return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final lastMessage = (data['lastMessage'] as Map<String, dynamic>?) ?? {};
                final timestamp = lastMessage['timestamp'] as Timestamp?;
                final bool isImage = lastMessage['text'] == '📷 مرفق صورة';
                final String userName = data['userName'] ?? 'مستخدم مجهول';
                final String userPhone = data['userPhone'] ?? 'بدون رقم';

                return Card(
                  elevation: 2, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                        backgroundColor: isImage ? Colors.teal.shade100 : Colors.blue.shade100,
                        radius: 25,
                        child: Icon(isImage ? Icons.image_outlined : Icons.person, color: isImage ? Colors.teal : Colors.blue.shade700)
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (timestamp != null) Text(DateFormat('hh:mm a').format(timestamp.toDate()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(userPhone, style: TextStyle(fontSize: 12, color: Colors.teal.shade600, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(lastMessage['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupportAdminChatScreen(chatId: doc.id))),
                  ),
                );
              }
          );
        },
      ),
    );
  }
}

// =============================================================================
// 💬 شاشة رد المشرف على الزبون (مع التحديث الشامل للمعلومات)
// =============================================================================
class SupportAdminChatScreen extends StatefulWidget {
  final String chatId;

  const SupportAdminChatScreen({super.key, required this.chatId});

  @override State<SupportAdminChatScreen> createState() => _SupportAdminChatScreenState();
}

class _SupportAdminChatScreenState extends State<SupportAdminChatScreen> {
  List<types.Message> _messages = [];
  final _user = const types.User(id: 'admin');

  // تخزين بيانات الزبون المنفصلة
  String _currentUserName = '';
  String _currentUserPhone = '';
  String _taxiName = '';
  String _taxiPhone = '';
  String _orderName = '';
  String _orderPhone = '';
  String _orderId = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToUserInfo();
  }

  void _listenToUserInfo() {
    FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentUserName = data['userName'] ?? _currentUserName;
          _currentUserPhone = data['userPhone'] ?? _currentUserPhone;
          _taxiName = data['taxiName'] ?? '';
          _taxiPhone = data['taxiPhone'] ?? '';
          _orderName = data['orderName'] ?? '';
          _orderPhone = data['orderPhone'] ?? '';
          _orderId = data['orderId'] ?? '';
        });
      }
    });
  }

  Future<void> _refreshUserInfo() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('support_chats').doc(widget.chatId).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserName = data['userName'] ?? _currentUserName;
          _currentUserPhone = data['userPhone'] ?? _currentUserPhone;
          _taxiName = data['taxiName'] ?? '';
          _taxiPhone = data['taxiPhone'] ?? '';
          _orderName = data['orderName'] ?? '';
          _orderPhone = data['orderPhone'] ?? '';
          _orderId = data['orderId'] ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات'), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل التحديث'), backgroundColor: Colors.red));
    }
  }

  void _loadMessages() {
    FirebaseFirestore.instance.collection('support_chats').doc(widget.chatId).collection('messages').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] is Timestamp) data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        final updatedData = {...data, 'author': {'id': data['authorId'] ?? ''}, 'id': doc.id};
        switch (data['type']) {
          case 'image': return types.ImageMessage.fromJson(updatedData);
          default: return types.TextMessage.fromJson(updatedData);
        }
      }).toList();
      if (mounted) setState(() => _messages = newMessages);
    });
  }

  void _addMessage(types.Message message) => setState(() => _messages.insert(0, message));

  Future<void> _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(author: _user, createdAt: DateTime.now().millisecondsSinceEpoch, id: const Uuid().v4(), text: message.text, status: types.Status.sending);
    _addMessage(textMessage);
    await _addMessageAndNotify(textMessage, null);
  }

  Future<void> _handleImageSelection() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final message = types.ImageMessage(author: _user, id: const Uuid().v4(), createdAt: DateTime.now().millisecondsSinceEpoch, name: result.name, size: bytes.length, uri: result.path, width: image.width.toDouble(), height: image.height.toDouble(), status: types.Status.sending);
    _addMessage(message);
    await _addMessageAndNotify(message, bytes);
  }

  Future<void> _addMessageAndNotify(types.Message message, dynamic imageBytes) async {
    String lastMessageText = (message is types.TextMessage) ? message.text : '📷 مرفق صورة';

    if (message is types.ImageMessage && imageBytes != null) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse('https://iraqed.beytei.com/wp-json/beytei-chat/v1/upload-file'))
          ..headers['X-Auth-Token'] = 'beytei93@beytei'
          ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: message.name));
        final response = await request.send();
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(await response.stream.bytesToString());
          message = message.copyWith(uri: jsonResponse['file_url'], status: types.Status.sent);
        } else throw Exception();
      } catch (e) {
        setState(() { final index = _messages.indexWhere((m) => m.id == message.id); if (index != -1) _messages[index] = message.copyWith(status: types.Status.error); });
        return;
      }
    } else if (message is types.TextMessage) {
      message = message.copyWith(status: types.Status.sent);
    }

    Map<String, dynamic> messageJson = message.toJson();
    messageJson.removeWhere((key, value) => key == 'author' || key == 'id');
    messageJson['authorId'] = message.author.id;

    await FirebaseFirestore.instance.collection('support_chats').doc(widget.chatId).collection('messages').doc(message.id).set(messageJson);
    await FirebaseFirestore.instance.collection('support_chats').doc(widget.chatId).update({'lastMessage.text': lastMessageText, 'lastMessage.timestamp': FieldValue.serverTimestamp(), 'lastMessage.authorId': message.author.id});

    try {
      final userDoc = await FirebaseFirestore.instance.collection('support_users').doc(widget.chatId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken != null) {
        await http.post(
            Uri.parse('https://iraqed.beytei.com/wp-json/beytei-chat/v1/notify-on-reply'),
            headers: {'Content-Type': 'application/json', 'X-Auth-Token': 'beytei93@beytei'},
            body: jsonEncode({'authorId': 'admin', 'fcmToken': fcmToken, 'messageText': lastMessageText})
        );
      }
    } catch (e) {}
  }

  void _showUserInfo() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(children: [Icon(Icons.person, color: Colors.teal), SizedBox(width: 10), Text('بيانات العميل الشاملة')]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // عرض قسم التكسي إن وجد
              if (_taxiName.isNotEmpty || _taxiPhone.isNotEmpty) ...[
                const Text('🚕 بيانات التكسي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                ListTile(leading: const Icon(Icons.person_outline), title: const Text('الاسم'), subtitle: Text(_taxiName.isNotEmpty ? _taxiName : 'غير متوفر')),
                ListTile(leading: const Icon(Icons.phone_android), title: const Text('رقم الهاتف'), subtitle: Text(_taxiPhone.isNotEmpty ? _taxiPhone : 'غير متوفر')),
                const Divider(),
              ],

              // عرض قسم المطعم إن وجد
              if (_orderName.isNotEmpty || _orderPhone.isNotEmpty) ...[
                const Text('🍔 بيانات المطعم/المسواك', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ListTile(leading: const Icon(Icons.person_outline), title: const Text('الاسم'), subtitle: Text(_orderName.isNotEmpty ? _orderName : 'غير متوفر')),
                ListTile(leading: const Icon(Icons.phone_android), title: const Text('رقم الهاتف'), subtitle: Text(_orderPhone.isNotEmpty ? _orderPhone : 'غير متوفر')),
                ListTile(leading: const Icon(Icons.receipt_long), title: const Text('رقم آخر طلب'), subtitle: Text(_orderId.isNotEmpty ? _orderId : 'غير متوفر')),
              ],

              // في حال لم يكن مسجلاً في أي منهما
              if (_taxiName.isEmpty && _orderName.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text('الزبون ضيف جديد ولم يقم بأي طلب أو تسجيل بعد.', style: TextStyle(color: Colors.grey)),
                ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_currentUserPhone, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'تحديث البيانات', onPressed: _refreshUserInfo),
          IconButton(icon: const Icon(Icons.info_outline), tooltip: 'بيانات العميل', onPressed: _showUserInfo)
        ],
      ),
      body: Chat(
          messages: _messages, onAttachmentPressed: _handleImageSelection, onSendPressed: _handleSendPressed, user: _user,
          theme: DefaultChatTheme(
              primaryColor: Colors.blueAccent,
              attachmentButtonIcon: Icon(Icons.add_photo_alternate_outlined, color: Colors.blueAccent),
              sendButtonIcon: Icon(Icons.send_rounded, color: Colors.blue)
          )
      ),
    );
  }
}
