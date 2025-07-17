import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// --- نقطة الدخول إلى قسم الاستشارات ---
// من تطبيقك الرئيسي "منصة بيتي"، قم بالانتقال إلى هذه الصفحة
// Navigator.of(context).push(MaterialPageRoute(builder: (_) => MedicalChatEntryPage()));
class MedicalChatEntryPage extends StatelessWidget {
  const MedicalChatEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          FirebaseAuth.instance.signInAnonymously();
        }
        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          return UserChatScreen(userId: snapshot.data!.uid);
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
        );
      },
    );
  }
}

// --- خدمة إدارة الإشعارات ---
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _fcm.requestPermission();
    final token = await _fcm.getToken();
    print('FCM Token: $token');
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }
}

// --- شاشة الاستشارة للمستخدم (بدون إرسال الصور) ---
class UserChatScreen extends StatefulWidget {
  final String userId;
  const UserChatScreen({super.key, required this.userId});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  List<types.Message> _messages = [];
  late final types.User _user;

  // [تم التبسيط] تمت إزالة التحكم اليدوي بـ FocusNode

  @override
  void initState() {
    super.initState();
    _user = types.User(id: widget.userId);
    NotificationService().initNotifications();
    _loadMessages();
  }

  // --- [تم الإصلاح] تحميل الرسائل مع معالجة التاريخ بشكل صحيح ---
  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        // بناء الرسالة يدوياً لتجنب أخطاء تحويل التاريخ
        return types.TextMessage(
          author: types.User(id: data['authorId'] ?? ''),
          // تحويل Timestamp من Firestore إلى الصيغة التي يفهمها التطبيق
          createdAt: (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
          id: doc.id,
          text: data['text'] ?? '',
        );
      }).toList();
      if (mounted) setState(() => _messages = messages);
    });
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    // [تم الإصلاح] إضافة الرسالة إلى الواجهة فوراً
    _addMessage(textMessage);
  }

  void _handleStickerPressed(String sticker) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: sticker,
    );
    // [تم الإصلاح] إضافة الرسالة إلى الواجهة فوراً
    _addMessage(textMessage);
  }

  // --- [تم التحسين] إرسال الرسالة ببيانات واضحة ومنظمة ---
  void _addMessage(types.TextMessage message) {
    // [تم الإصلاح] إضافة الرسالة إلى الواجهة فوراً (تحديث متفائل)
    setState(() {
      _messages.insert(0, message);
    });

    // بناء البيانات يدوياً لضمان التوافق مع قاعدة البيانات
    final messageData = {
      'authorId': message.author.id,
      'createdAt': FieldValue.serverTimestamp(), // استخدام وقت السيرفر
      'text': message.text,
      'type': types.MessageType.text.name,
    };

    // إرسال الرسالة إلى Firestore في الخلفية
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .add(messageData);

    FirebaseFirestore.instance.collection('chats').doc(widget.userId).set({
      'userName': 'مستخدم ${widget.userId.substring(0, 6)}',
      'lastMessage': {
        'text': message.text,
        'timestamp': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استشارة بيتي الطبية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
          ),
        ],
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        customBottomWidget: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.white,
          child: Row(
            children: [
              // زر الملصقات لا يزال موجوداً
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.indigo),
                onPressed: () => _showStickerSheet(context),
              ),
              Expanded(
                child: Input(
                    onSendPressed: _handleSendPressed,
                    // [تم الإصلاح] استخدام خاصية التركيز التلقائي لفتح لوحة المفاتيح
                    options: const InputOptions(
                        autofocus: true,
                        sendButtonVisibilityMode: SendButtonVisibilityMode.always
                    )),
              ),
            ],
          ),
        ),
        theme: const DefaultChatTheme(
          primaryColor: Colors.indigo,
          secondaryColor: Color(0xFFE3F2FD),
        ),
        l10n: const ChatL10nEn(inputPlaceholder: 'ابدأ استشارتك هنا...'),
        emptyState: const Center(child: Text('مرحباً بك! ابدأ استشارتك الآن')),
      ),
    );
  }

  void _showStickerSheet(BuildContext context) {
    final stickers = ['💊', '🩹', '🩺', '❤️‍🩹', '💉', '🚑', '👍', '✅'];
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: stickers.length,
            itemBuilder: (BuildContext context, int index) {
              return IconButton(
                icon: Text(stickers[index], style: const TextStyle(fontSize: 30)),
                onPressed: () {
                  _handleStickerPressed(stickers[index]);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        );
      },
    );
  }
}

// --- شاشة تسجيل دخول المسؤول ---
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const AdminChatListScreen(),
        ));
      }
    } on FirebaseAuthException catch (e) {
      final message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بوابة الأطباء')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _login, child: const Text('تسجيل الدخول')),
            ],
          ),
        ),
      ),
    );
  }
}

// --- شاشة قائمة محادثات المسؤول ---
class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MedicalChatEntryPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة المحادثات'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').orderBy('lastMessage.timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final lastMessage = (doc['lastMessage'] as Map<String, dynamic>?) ?? {};
              final timestamp = lastMessage['timestamp'] as Timestamp?;
              return ListTile(
                title: Text(doc['userName'] ?? 'مستخدم'),
                subtitle: Text(lastMessage['text'] ?? ''),
                trailing: Text(timestamp != null ? DateFormat('h:mm a').format(timestamp.toDate()) : ''),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AdminChatScreen(chatId: doc.id, userName: doc['userName']),
                )),
              );
            },
          );
        },
      ),
    );
  }
}

// --- شاشة الدردشة الخاصة بالمسؤول ---
class AdminChatScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  const AdminChatScreen({super.key, required this.chatId, required this.userName});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  List<types.Message> _messages = [];
  final _user = const types.User(id: 'admin');

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // --- [تم الإصلاح] تحميل الرسائل مع معالجة التاريخ بشكل صحيح ---
  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return types.TextMessage(
          author: types.User(id: data['authorId'] ?? ''),
          createdAt: (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
          id: doc.id,
          text: data['text'] ?? '',
        );
      }).toList();
      if (mounted) setState(() => _messages = messages);
    });
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    _addMessage(textMessage);
  }

  // --- [تم التحسين] إرسال الرسالة ببيانات واضحة ومنظمة ---
  void _addMessage(types.TextMessage message) {
    setState(() {
      _messages.insert(0, message);
    });

    final messageData = {
      'authorId': message.author.id,
      'createdAt': FieldValue.serverTimestamp(),
      'text': message.text,
      'type': types.MessageType.text.name,
    };
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add(messageData);
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage.text': message.text,
      'lastMessage.timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('محادثة مع ${widget.userName}')),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
      ),
    );
  }
}
