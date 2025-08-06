import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Firebase & Chat UI
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// Helpers
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cosmetic_store/firebase_options.dart';

// --- نظام الإشعارات المركزي ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.instance.showNotificationFromMessage(message);
}

class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel('high_importance_channel','High Importance Notifications', description: 'This channel is used for important notifications.', importance: Importance.max, enableVibration: true);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await _plugin.show(
      message.hashCode,
      message.notification?.title ?? 'رسالة جديدة',
      message.notification?.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name, channelDescription: channel.description, icon: '@mipmap/ic_launcher', importance: Importance.max, priority: Priority.high, enableVibration: true),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.instance.init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      LocalNotificationService.instance.showNotificationFromMessage(message);
    }
  });
  runApp(const MedicalChatApp());
}

class MedicalChatApp extends StatelessWidget {
  const MedicalChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'استشارات بيتي ',
      theme: ThemeData(primarySwatch: Colors.indigo, fontFamily: 'Tajawal'),
      debugShowCheckedModeBanner: false,
      home: const AuthDispatcher(),
    );
  }
}

class AuthDispatcher extends StatelessWidget {
  const AuthDispatcher({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const RegistrationScreen();
          }
          if (!user.isAnonymous) {
            return const AdminChatListScreen();
          }
          return UserChatScreen(userId: user.uid);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}
class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التسجيل. يرجى المحاولة مرة أخرى.')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول للاستشارة')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('أهلاً بك في استشارات بيتي ', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('يرجى إدخال بياناتك للمتابعة', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()), validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال الاسم' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال رقم الهاتف' : null),
                const SizedBox(height: 24),
                _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: _registerUser, child: const Text('دخول')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  Future<void> initNotifications(String userId) async {
    await _fcm.requestPermission();
    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({'fcmToken': token}, SetOptions(merge: true));
    }
  }
}

class UserChatScreen extends StatefulWidget {
  final String userId;
  const UserChatScreen({super.key, required this.userId});
  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  List<types.Message> _messages = [];
  late final types.User _user;
  String _userName = 'مستخدم';

  @override
  void initState() {
    super.initState();
    _user = types.User(id: widget.userId);
    _loadUserDataAndMessages();
  }

  Future<void> _loadUserDataAndMessages() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if(mounted) setState(() { _userName = userDoc.data()?['name'] ?? 'مستخدم'; });
    NotificationService().initNotifications(widget.userId);
    _loadMessages();
  }

  void _loadMessages() {
    FirebaseFirestore.instance.collection('chats').doc(widget.userId).collection('messages').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        // ⭐ [تم الإصلاح] - لا نضيف حالة يدوياً، بل نترك fromJson يقرأها من قاعدة البيانات
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

  Future<void> _notifyAdmin({required String userName, required String messageText}) async {
    const String wordpressApiUrl = 'https://iraqed.beytei.com/wp-json/beytei-chat/v1/notify-admin-on-reply';
    const String secretKey = 'beytei93@beytei';
    try {
      await http.post(Uri.parse(wordpressApiUrl), headers: {'Content-Type': 'application/json; charset=UTF-8', 'X-Auth-Token': secretKey}, body: jsonEncode({'userName': userName, 'messageText': messageText}));
    } catch (e) { print('Error sending admin notification: $e'); }
  }

  Future<void> _updateChatMetadata(String lastMessageText) async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.userId).set({
      'userName': _userName,
      'lastMessage': {'text': lastMessageText, 'timestamp': FieldValue.serverTimestamp(), 'authorId': widget.userId}
    }, SetOptions(merge: true));
    await _notifyAdmin(userName: _userName, messageText: lastMessageText);
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(author: _user, createdAt: DateTime.now().millisecondsSinceEpoch, id: const Uuid().v4(), text: message.text, status: types.Status.sending);
    _addMessage(textMessage);

    Map<String, dynamic> messageJson = textMessage.toJson();
    messageJson.removeWhere((key, value) => key == 'author' || key == 'id');
    messageJson['authorId'] = textMessage.author.id;
    await FirebaseFirestore.instance.collection('chats').doc(widget.userId).collection('messages').doc(textMessage.id).set(messageJson);
    await FirebaseFirestore.instance.collection('chats').doc(widget.userId).collection('messages').doc(textMessage.id).update({'status': types.Status.sent.name});
    await _updateChatMetadata(textMessage.text);
  }

  Future<void> _handleImageSelection() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final message = types.ImageMessage(author: _user, id: const Uuid().v4(), createdAt: DateTime.now().millisecondsSinceEpoch, name: result.name, size: bytes.length, uri: result.path, width: image.width.toDouble(), height: image.height.toDouble(), status: types.Status.sending);
    _addMessage(message);

    const String uploadUrl = 'https://iraqed.beytei.com/wp-json/beytei-chat/v1/upload-file';
    const String secretKey = 'beytei93@beytei';
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))..headers['X-Auth-Token'] = secretKey..files.add(http.MultipartFile.fromBytes('file', bytes, filename: result.name));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        final fileUrl = jsonResponse['file_url'];
        final updatedMessage = message.copyWith(uri: fileUrl, status: types.Status.sent);
        Map<String, dynamic> messageJson = updatedMessage.toJson();
        messageJson.removeWhere((key, value) => key == 'author' || key == 'id');
        messageJson['authorId'] = updatedMessage.author.id;
        await FirebaseFirestore.instance.collection('chats').doc(widget.userId).collection('messages').doc(message.id).set(messageJson);
        await _updateChatMetadata('📷 صورة');
      } else {
        final updatedMessage = message.copyWith(status: types.Status.error);
        setState(() { final index = _messages.indexWhere((m) => m.id == message.id); if (index != -1) _messages[index] = updatedMessage; });
      }
    } catch (e) {
      final updatedMessage = message.copyWith(status: types.Status.error);
      setState(() { final index = _messages.indexWhere((m) => m.id == message.id); if (index != -1) _messages[index] = updatedMessage; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('استشارة مع: ${_userName}'), actions: [IconButton(icon: const Icon(Icons.admin_panel_settings_outlined),onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen())))]),
      body: Chat(
        messages: _messages, onAttachmentPressed: _handleImageSelection, onSendPressed: _handleSendPressed, user: _user,
        theme: const DefaultChatTheme(primaryColor: Colors.indigo, secondaryColor: Color(0xFFE3F2FD), attachmentButtonIcon: Icon(Icons.attach_file, color: Colors.indigo)),
        l10n: const ChatL10nEn(inputPlaceholder: 'ابدأ استشارتك هنا...'), emptyState: const Center(child: Text('مرحباً بك! ابدأ استشارتك الآن')),
      ),
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}
class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  Future<void> _saveAdminFCMTokenToWordPress(String email) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    const String apiUrl = 'https://iraqed.beytei.com/wp-json/beytei-chat/v1/update-admin-fcm-token';
    const String secretKey = 'beytei93@beytei';
    try {
      await http.post(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json; charset=UTF-8', 'X-Auth-Token': secretKey}, body: jsonEncode({'email': email, 'fcmToken': fcmToken}));
    } catch (e) { print('Error saving admin FCM token: $e'); }
  }
  Future<void> _login() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await _saveAdminFCMTokenToWordPress(email);
    } on FirebaseAuthException {
      const message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('بوابة الأطباء')), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress), const SizedBox(height: 16), TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true), const SizedBox(height: 24), _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _login, child: const Text('تسجيل الدخول'))]))));
  }
}

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});
  @override State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}
class _AdminChatListScreenState extends State<AdminChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قائمة المحادثات'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async { await FirebaseAuth.instance.signOut(); })]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').orderBy('lastMessage.timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد محادثات بعد.'));
          return ListView.builder(itemCount: docs.length, itemBuilder: (context, index) {
            final doc = docs[index]; final data = doc.data() as Map<String, dynamic>; final lastMessage = (data['lastMessage'] as Map<String, dynamic>?) ?? {}; final timestamp = lastMessage['timestamp'] as Timestamp?;
            final bool isImage = lastMessage['text'] == '📷 صورة';
            return ListTile(
              leading: CircleAvatar(backgroundColor: isImage ? Colors.indigo.shade100 : Colors.grey.shade200, child: Icon( isImage ? Icons.image_outlined : Icons.person_outline, color: isImage ? Colors.indigo : Colors.grey)),
              title: Text(data['userName'] ?? 'مستخدم'),
              subtitle: Text(lastMessage['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(timestamp != null ? DateFormat('h:mm a').format(timestamp.toDate()) : ''),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminChatScreen(chatId: doc.id, userName: data['userName']))),
            );
          });
        },
      ),
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  final String chatId; final String userName;
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

  void _loadMessages() {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        // ⭐ [تم الإصلاح] - لا نضيف حالة يدوياً، بل نترك fromJson يقرأها من قاعدة البيانات
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
    final textMessage = types.TextMessage(author: _user, createdAt: DateTime.now().millisecondsSinceEpoch, id: const Uuid().v4(), text: message.text, status: types.Status.sending);
    _addMessage(textMessage);
    await _addMessageAndNotify(textMessage);
  }

  Future<void> _handleImageSelection() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final message = types.ImageMessage(author: _user, id: const Uuid().v4(), createdAt: DateTime.now().millisecondsSinceEpoch, name: result.name, size: bytes.length, uri: result.path, width: image.width.toDouble(), height: image.height.toDouble(), status: types.Status.sending);
    _addMessage(message);
    await _addMessageAndNotify(message, imageBytes: bytes);
  }

  Future<void> _sendNotificationViaWordpress({required String fcmToken, required String messageText}) async {
    const String wordpressApiUrl = 'https://iraqed.beytei.com/wp-json/beytei-chat/v1/notify-on-reply';
    const String secretKey = 'beytei93@beytei';
    try {
      await http.post(Uri.parse(wordpressApiUrl), headers: {'Content-Type': 'application/json; charset=UTF-8', 'X-Auth-Token': secretKey}, body: jsonEncode({'authorId': 'admin', 'fcmToken': fcmToken, 'messageText': messageText}));
    } catch (e) {
      print('Error calling WordPress API: $e');
    }
  }

  Future<void> _addMessageAndNotify(types.Message message, {Uint8List? imageBytes}) async {
    String lastMessageText = (message is types.TextMessage) ? message.text : '📷 صورة';

    if (message is types.ImageMessage && imageBytes != null) {
      const String uploadUrl = 'https://iraqed.beytei.com/wp-json/beytei-chat/v1/upload-file';
      const String secretKey = 'beytei93@beytei';
      try {
        final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))..headers['X-Auth-Token'] = secretKey..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: message.name));
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final jsonResponse = jsonDecode(responseData);
          final fileUrl = jsonResponse['file_url'];
          message = message.copyWith(uri: fileUrl, status: types.Status.sent);
        } else {
          throw Exception('File upload failed');
        }
      } catch (e) {
        final updatedMessage = message.copyWith(status: types.Status.error);
        setState(() { final index = _messages.indexWhere((m) => m.id == message.id); if (index != -1) _messages[index] = updatedMessage; });
        return;
      }
    } else if (message is types.TextMessage) {
      message = message.copyWith(status: types.Status.sent);
    }

    Map<String, dynamic> messageJson = message.toJson();
    messageJson.removeWhere((key, value) => key == 'author' || key == 'id');
    messageJson['authorId'] = message.author.id;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(message.id).set(messageJson);
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'lastMessage.text': lastMessageText, 'lastMessage.timestamp': FieldValue.serverTimestamp(), 'lastMessage.authorId': message.author.id});

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.chatId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken != null) { await _sendNotificationViaWordpress(fcmToken: fcmToken, messageText: lastMessageText); }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _showUserInfoDialog() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.chatId).get();
    final data = userDoc.data();
    final name = data?['name'] ?? 'غير متوفر';
    final phone = data?['phone'] ?? 'غير متوفر';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات المستخدم'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الاسم: $name'), const SizedBox(height: 8), Text('رقم الهاتف: $phone')]),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('محادثة مع ${widget.userName}'), actions: [IconButton(icon: const Icon(Icons.info_outline), tooltip: 'عرض معلومات المستخدم', onPressed: _showUserInfoDialog)]),
      body: Chat(messages: _messages, onAttachmentPressed: _handleImageSelection, onSendPressed: _handleSendPressed, user: _user, theme: const DefaultChatTheme(attachmentButtonIcon: Icon(Icons.attach_file))),
    );
  }
}