import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Chat UI Imports
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// هام: تأكد من وجود ملف إعدادات فايربيس
import 'package:cosmetic_store/firebase_options.dart';

// ---------------------------------------------------------------------------
// 1. الإعدادات الرئيسية (Main)
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // طلب إذن الإشعارات فور فتح التطبيق
  FirebaseMessaging.instance.requestPermission();

  runApp(const BeyteiApp());
}

class BeyteiApp extends StatelessWidget {
  const BeyteiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة بيتي',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Tajawal', // تأكد من إضافة الخط
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: false,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo)),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthDispatcher(),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. الموجه (AuthDispatcher)
// ---------------------------------------------------------------------------

class AuthDispatcher extends StatelessWidget {
  const AuthDispatcher({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        // 1. إذا لم يسجل الدخول -> شاشة دخول الزبون الجديدة
        if (user == null) {
          return const CustomerLoginScreen();
        }

        // 2. فحص نوع المستخدم في قاعدة البيانات
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;

              // تحديث التوكن في الخلفية لضمان وصول الإشعارات
              _updateMyToken();

              // التوجيه حسب الدور
              if (data['role'] == 'provider') {
                return const ProviderDashboardScreen();
              } else {
                return const HomeScreen(); // دور client
              }
            }

            // في حال وجود مستخدم بالخطأ بدون بيانات
            return const CustomerLoginScreen();
          },
        );
      },
    );
  }

  Future<void> _updateMyToken() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await FirebaseMessaging.instance.getToken();
    if (user != null && token != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
    }
  }
}

// ---------------------------------------------------------------------------
// 3. شاشة دخول الزبون (الجديدة والبسيطة)
// ---------------------------------------------------------------------------

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});
  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // تسجيل دخول مجهول (ولكن نربطه ببيانات)
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (user != null) {
        // حفظ بيانات الزبون الحقيقية
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(), // للتواصل
          'role': 'client',
          'fcmToken': fcmToken,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // دمج لتجنب مسح البيانات القديمة إذا وجد
      }

      // سينقله الـ AuthDispatcher تلقائياً للرئيسية
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الدخول')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.maps_home_work_outlined, size: 80, color: Colors.indigo),
                const SizedBox(height: 16),
                const Text('أهلاً بك في منصة بيتي', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 8),
                const Text('سجل دخولك البسيط وابدأ طلب الخدمات', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),

                // حقل الاسم
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المستخدم (الاسم الثلاثي)', prefixIcon: Icon(Icons.person)),
                  validator: (val) => val!.isEmpty ? 'يرجى كتابة الاسم' : null,
                ),
                const SizedBox(height: 16),

                // حقل الهاتف (التحقق العراقي)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11, // الحد الأقصى
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_iphone),
                    hintText: '077xxxxxxxx',
                    counterText: "", // إخفاء عداد الأحرف
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'يرجى كتابة رقم الهاتف';
                    if (val.length != 11) return 'يجب أن يتكون الرقم من 11 مرتبة';
                    if (!val.startsWith('077') && !val.startsWith('078')) {
                      return 'يجب أن يبدأ الرقم بـ 077 أو 078';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // زر الدخول
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _loginCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('دخول مباشر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 30),
                const Divider(),

                // رابط دخول المزودين
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderLoginScreen()));
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: 'هل أنت مزود خدمة (محامي/مهندس)؟ ',
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(text: 'اضغط هنا', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. شاشة دخول المزود (البريد وكلمة المرور)
// ---------------------------------------------------------------------------

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({super.key});
  @override State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginProvider() async {
    setState(() => _isLoading = true);
    try {
      // 1. يجب تسجيل الخروج من أي حساب سابق
      await FirebaseAuth.instance.signOut();

      // 2. الدخول ببيانات الأدمن
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // 3. تحديث التوكن لضمان وصول الإشعارات للمزود
      final token = await FirebaseMessaging.instance.getToken();
      if (FirebaseAuth.instance.currentUser != null && token != null) {
        await FirebaseFirestore.instance.collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'fcmToken': token});
      }

      if(mounted) {
        // العودة للبداية ليقوم الـ Dispatcher بالتوجيه للوحة التحكم
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => const AuthDispatcher()), (route) => false);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في المعلومات. تأكد من البريد وكلمة المرور المسلمة لك.')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بوابة الشركاء")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, size: 70, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text("تسجيل دخول المزودين", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  onPressed: _loginProvider,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.indigo),
                  child: const Text("دخول")
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. الشاشة الرئيسية للزبون (Home)
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> services = const [
    {'id': 'lawyer', 'name': 'محامي', 'icon': Icons.gavel, 'color': Colors.brown},
    {'id': 'engineer', 'name': 'مهندس', 'icon': Icons.architecture, 'color': Colors.blueGrey},
    {'id': 'cleaning', 'name': 'تنظيف', 'icon': Icons.cleaning_services, 'color': Colors.purple},
    {'id': 'ac', 'name': 'تكييف', 'icon': Icons.ac_unit, 'color': Colors.blue},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الخدمات المتاحة"),
        actions: [
          IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // عند الخروج يرجع لشاشة الدخول البسيطة
              }
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                builder: (context, snapshot) {
                  String name = "عزيزي العميل";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    name = snapshot.data!['name'] ?? name;
                  }
                  return Text("مرحباً $name، ماذا تحتاج اليوم؟", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                }
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceProvidersScreen(
                          serviceId: services[index]['id'],
                          serviceName: services[index]['name']
                      )));
                    },
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(services[index]['icon'], size: 50, color: services[index]['color']),
                          const SizedBox(height: 10),
                          Text(services[index]['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. قائمة المزودين (Service Providers)
// ---------------------------------------------------------------------------

class ServiceProvidersScreen extends StatelessWidget {
  final String serviceId;
  final String serviceName;
  const ServiceProvidersScreen({super.key, required this.serviceId, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("خبراء $serviceName")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
            .where('role', isEqualTo: 'provider')
            .where('serviceType', isEqualTo: serviceId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا يوجد مزودين متاحين حالياً"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.indigo.shade50, child: Text(data['name'][0])),
                  title: Text(data['name']),
                  subtitle: Text(data['price'] ?? 'السعر عند الاتفاق'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _openChat(context, doc.id, data['name']);
                    },
                    child: const Text("تواصل"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, String providerId, String providerName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
      conversationId: '${FirebaseAuth.instance.currentUser!.uid}_$providerId',
      otherUserId: providerId,
      otherUserName: providerName,
      isProvider: false,
    )));
  }
}

// ---------------------------------------------------------------------------
// 7. لوحة تحكم المزود (Dashboard)
// ---------------------------------------------------------------------------

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("الطلبات الواردة"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats')
            .where('providerId', isEqualTo: myId)
            .orderBy('lastMessage.timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد محادثات نشطة"));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final lastMsg = data['lastMessage'] ?? {};

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['userName'] ?? 'زبون'),
                subtitle: Text(lastMsg['text'] ?? 'مرفق', maxLines: 1),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                    conversationId: doc.id,
                    otherUserId: data['userId'],
                    otherUserName: data['userName'],
                    isProvider: true,
                  )));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. شاشة الشات الموحدة (نظام الإشعارات المزدوج)
// ---------------------------------------------------------------------------

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final bool isProvider;

  const ChatScreen({super.key, required this.conversationId, required this.otherUserId, required this.otherUserName, required this.isProvider});

  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late final types.User _currentUser;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = types.User(id: FirebaseAuth.instance.currentUser!.uid);
    _loadMessages();
  }

  void _loadMessages() {
    FirebaseFirestore.instance.collection('chats').doc(widget.conversationId).collection('messages')
        .orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      if(mounted) {
        setState(() {
          _messages = snapshot.docs.map((doc) {
            final data = doc.data();
            final updatedData = {
              ...data,
              'createdAt': (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch : data['createdAt'],
              'author': {'id': data['authorId']},
              'id': doc.id
            };
            if (data['type'] == 'image') return types.ImageMessage.fromJson(updatedData);
            return types.TextMessage.fromJson(updatedData);
          }).toList();
        });
      }
    });
  }

  // --- إرسال الإشعارات (للطرفين) ---
  Future<void> _sendNotification(String messageText, bool isImage) async {
    const String secretKey = 'beytei93@beytei';
    final textToSend = isImage ? '📷 صورة جديدة' : messageText;

    try {
      if (!widget.isProvider) {
        // 1. أنا زبون -> أرسل للمزود
        // نستخدم رابط إشعار الأدمن/المزود
        await http.post(
            Uri.parse(' https://iraqed.beytei.com/chat-api.php?action=notify-admin-on-reply'),
            headers: {'Content-Type': 'application/json', 'X-Auth-Token': secretKey},
            body: jsonEncode({
              'userName': 'زبون', // أو جلب الاسم الحقيقي
              'messageText': textToSend,
              'providerId': widget.otherUserId // مهم: ليعرف السيرفر لمن يرسل
            })
        );
      } else {
        // 2. أنا مزود -> أرسل للزبون
        // نحتاج FCM Token للزبون
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get();
        final fcmToken = userDoc.data()?['fcmToken'];

        if (fcmToken != null) {
          await http.post(
              Uri.parse('https://iraqed.beytei.com/wp-json/beytei-chat/v1/notify-on-reply'),
              headers: {'Content-Type': 'application/json', 'X-Auth-Token': secretKey},
              body: jsonEncode({
                'authorId': 'provider',
                'fcmToken': fcmToken,
                'messageText': textToSend
              })
          );
        }
      }
    } catch (e) {
      print("Notification Failed: $e");
    }
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    await _addMessageToFirestore(textMessage, message.text, false);
    _sendNotification(message.text, false);
  }

  Future<void> _handleImageSelection() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result == null) return;
    setState(() => _isUploading = true);

    try {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // رفع الصورة
      const String uploadUrl = 'https://iraqed.beytei.com/wp-json/beytei-chat/v1/upload-file';
      const String secretKey = 'beytei93@beytei';

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..headers['X-Auth-Token'] = secretKey
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: result.name));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final fileUrl = jsonDecode(respStr)['file_url'];

        final imgMsg = types.ImageMessage(
          author: _currentUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          name: result.name,
          size: bytes.length,
          uri: fileUrl,
          width: image.width.toDouble(),
          height: image.height.toDouble(),
        );

        await _addMessageToFirestore(imgMsg, '📷 صورة', true);
        _sendNotification('', true);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل رفع الصورة')));
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _addMessageToFirestore(types.Message message, String lastText, bool isImage) async {
    Map<String, dynamic> msgJson = message.toJson();
    msgJson['authorId'] = _currentUser.id;
    msgJson.remove('author');
    if (isImage) msgJson['type'] = 'image';

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.conversationId);
    await chatRef.collection('messages').doc(message.id).set(msgJson);

    final Map<String, dynamic> metadata = {
      'lastMessage': {'text': lastText, 'timestamp': FieldValue.serverTimestamp()},
    };

    if (!widget.isProvider) {
      // إذا كنت زبوناً، احفظ معلوماتي
      // نحتاج جلب الاسم الذي سجله الزبون في شاشة الدخول
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.id).get();
      final myName = userDoc.data()?['name'] ?? 'زبون';

      metadata['userId'] = _currentUser.id;
      metadata['userName'] = myName;
      metadata['providerId'] = widget.otherUserId;
      metadata['providerName'] = widget.otherUserName;
    }

    await chatRef.set(metadata, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: _isUploading ? [const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white))] : [],
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        onAttachmentPressed: _handleImageSelection,
        user: _currentUser,
        theme: DefaultChatTheme(
          primaryColor: widget.isProvider ? Colors.indigo : Colors.purple, // أزرق للمزود، بنفسجي للزبون
          attachmentButtonIcon: const Icon(Icons.add_a_photo, color: Colors.indigo),
        ),
      ),
    );
  }
}
