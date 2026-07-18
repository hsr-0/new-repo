import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState; // إخفاء ConnectionState لتجنب التعارض

class ActiveVoiceCallScreen extends StatefulWidget {
  // ✅ تم تحديث المتغيرات لتتوافق مع LiveKit
  final String roomName;
  final String livekitUrl;
  final String token;
  final String remoteName;

  const ActiveVoiceCallScreen({
    super.key,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    required this.remoteName,
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener; // 🆕 المستمع الجديد للأحداث

  bool _isConnected = false;
  bool _isRemoteConnected = false; // لمعرفة هل الطرف الآخر دخل الغرفة

  bool _isMuted = false;
  bool _isSpeaker = true; // السبيكر مفعل افتراضياً

  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;

  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initLiveKit();

    // إغلاق المكالمة تلقائياً بعد 30 ثانية إذا لم يرد الطرف الآخر
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!_isRemoteConnected && mounted) {
        print("⏳ انتهى الوقت ولم يتم الاتصال، جاري إنهاء المكالمة.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الطرف الآخر لا يرد حالياً'), backgroundColor: Colors.orange),
        );
        _endCall();
      }
    });
  }

  Future<void> _initLiveKit() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _hasError = true;
        _errorMessage = "يرجى منح صلاحية المايكروفون في إعدادات الجهاز";
      });
      return;
    }

    try {
      _room = Room();
      _listener = _room!.createListener(); // 🆕 إنشاء المستمع

      // 🆕 الاستماع للأحداث بالطريقة الحديثة في LiveKit
      _listener!.on<ParticipantConnectedEvent>((event) {
        if (!mounted) return;
        _timeoutTimer?.cancel(); // إيقاف مؤقت الانتظار
        setState(() => _isRemoteConnected = true);
        _startTimer();
      });

      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (!mounted) return;
        if (_isConnected) {
          _showCallEndedDialog("أنهى الطرف الآخر المكالمة");
        }
      });

      _listener!.on<RoomDisconnectedEvent>((event) {
        if (!mounted) return;
        _showCallEndedDialog("انقطع الاتصال");
      });

      // الاتصال بالغرفة باستخدام الـ Token الجاهز
      await _room!.connect(
        widget.livekitUrl,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(),
        ),
      );

      setState(() => _isConnected = true);

      // تفعيل المايكروفون والسماعة افتراضياً
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      await Hardware.instance.setSpeakerphoneOn(_isSpeaker); // 🆕 الطريقة الحديثة

    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "فشل في بدء المكالمة: ${e.toString()}";
        });
      }
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRemoteConnected) {
        setState(() => _callDuration++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showCallEndedDialog(String message) {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.call_end, color: Colors.red),
              SizedBox(width: 10),
              Text("انتهت المكالمة"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 10),
              Text("المدة: ${_formatDuration(_callDuration)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _endCall();
              },
              child: const Text("موافق", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _room?.localParticipant?.setMicrophoneEnabled(!_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeaker = !_isSpeaker);
    await Hardware.instance.setSpeakerphoneOn(_isSpeaker); // 🆕 الطريقة الحديثة
  }

  void _endCall() async {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      await _listener?.dispose(); // 🆕 تنظيف المستمع
      await _room?.disconnect();
      _room = null;
    } catch (e) {
      print("Error releasing LiveKit room: $e");
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _endCall(); // ضمان تنظيف الموارد
    super.dispose();
  }

  String _getCallStatus() {
    if (_hasError) return _errorMessage;
    if (_isRemoteConnected) return "متصل الآن 🟢";
    if (_isConnected) return "يرن عند الطرف الآخر... ⏳";
    return "جاري الاتصال بالسيرفر...";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _endCall,
                    ),
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSpeaker ? Icons.volume_up : Icons.volume_off,
                        color: _isSpeaker ? Colors.green : Colors.white70,
                        size: 28,
                      ),
                      onPressed: _toggleSpeaker,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey.shade800,
                      child: const Icon(Icons.local_taxi, size: 70, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Text(
                    widget.remoteName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "غرفة: ${widget.roomName}",
                    style: const TextStyle(fontSize: 12, color: Colors.yellow),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasError
                          ? Colors.red.withOpacity(0.2)
                          : (_isRemoteConnected ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _hasError
                            ? Colors.red
                            : (_isRemoteConnected ? Colors.green : Colors.blue),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasError
                              ? Icons.error
                              : (_isRemoteConnected ? Icons.check_circle : Icons.access_time),
                          color: _hasError ? Colors.red : (_isRemoteConnected ? Colors.green : Colors.blue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getCallStatus(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              Container(
                padding: const EdgeInsets.only(bottom: 40, top: 25),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _toggleMute,
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: _isMuted ? Colors.red.withOpacity(0.2) : Colors.white10,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _isMuted ? Colors.red : Colors.white70, width: 1.5),
                                ),
                                child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : Colors.white, size: 30),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(_isMuted ? "إلغاء الكتم" : "كتم", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),

                        GestureDetector(
                          onTap: _endCall,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade400,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                              ],
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 38),
                          ),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _toggleSpeaker,
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: _isSpeaker ? Colors.green.withOpacity(0.2) : Colors.white10,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _isSpeaker ? Colors.green : Colors.white70, width: 1.5),
                                ),
                                child: Icon(_isSpeaker ? Icons.volume_up : Icons.volume_down, color: _isSpeaker ? Colors.green : Colors.white, size: 30),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(_isSpeaker ? "إيقاف السماعة" : "تفعيل السماعة", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}