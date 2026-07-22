import 'dart:async';
import 'dart:io'; // ✅ ضروري للتحقق من نظام التشغيل
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState;
import 'package:audio_session/audio_session.dart'; // ✅ ضروري جداً للآيفون
class ActiveVoiceCallScreen extends StatefulWidget {
  final String roomName;
  final String livekitUrl;
  final String token;
  final String remoteName;
  final String? orderId; // ✅ أضف هذا السطر

  const ActiveVoiceCallScreen({
    super.key,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    required this.remoteName,
    this.orderId, // ✅ أضف هذا السطر
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _isConnected = false;
  bool _isRemoteConnected = false;

  bool _isMuted = false;
  bool _isSpeaker = true;

  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;

  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initLiveKit();

    // إغلاق المكالمة تلقائياً بعد 45 ثانية إذا لم يرد السائق
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_isRemoteConnected && mounted) {
        print("⏳ انتهى الوقت ولم يتم الاتصال، جاري إنهاء المكالمة.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('السائق لا يرد حالياً'), backgroundColor: Colors.orange),
        );
        _endCall();
      }
    });
  }

  Future<void> _initLiveKit() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = "يرجى منح صلاحية المايكروفون في إعدادات الجهاز";
      });
      return;
    }

    try {
      // ✅ 1. إعداد جلسة الصوت للآيفون (خطوة حاسمة لمنع مشاكل الصوت)
      if (Platform.isIOS) {
        final session = await AudioSession.instance;
        await session.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        ));
      }

      _room = Room();
      _listener = _room!.createListener();

      // ✅ 2. الاستماع للأحداث (محدث ليشمل TrackSubscribedEvent لمنع التعليق)
      _listener!.on<ParticipantConnectedEvent>((event) {
        if (mounted && !_isRemoteConnected) {
          _timeoutTimer?.cancel();
          setState(() => _isRemoteConnected = true);
          _startTimer();
          print("✅ الزبون: السائق دخل الغرفة");
        }
      });

      _listener!.on<TrackSubscribedEvent>((event) {
        if (mounted && !_isRemoteConnected) {
          _timeoutTimer?.cancel();
          setState(() => _isRemoteConnected = true);
          _startTimer();
          print("✅ الزبون: تم استقبال مسار الصوت من السائق");
        }
      });

      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (mounted && _isConnected) {
          _showCallEndedDialog("أنهى السائق المكالمة");
        }
      });

      _listener!.on<RoomDisconnectedEvent>((event) {
        if (mounted) {
          _showCallEndedDialog("انقطع الاتصال");
        }
      });

      // ✅ 3. الاتصال بالغرفة
      await _room!.connect(
        widget.livekitUrl,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(),
        ),
      );

      if (mounted) {
        setState(() => _isConnected = true);

        // ✅ 4. فحص فوري: هل السائق موجود بالفعل في الغرفة؟
        // هذا يمنع مشكلة "التعليق" إذا كان السائق قد دخل قبل أن نجهز المستمع
        if (_room!.remoteParticipants.isNotEmpty) {
          setState(() => _isRemoteConnected = true);
          _timeoutTimer?.cancel();
          _startTimer();
          print("✅ الزبون: السائق موجود مسبقاً في الغرفة!");
        }

        // تفعيل المايكروفون
        await _room!.localParticipant?.setMicrophoneEnabled(true);

        // ✅ 5. تأخير بسيط لضمان استقرار الصوت قبل تفعيل السماعة
        await Future.delayed(const Duration(milliseconds: 300));
        await Hardware.instance.setSpeakerphoneOn(_isSpeaker);
      }
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
    await Hardware.instance.setSpeakerphoneOn(_isSpeaker);
  }

  void _endCall() async {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      await _listener?.dispose();
      await _room?.disconnect();
      _room = null;
    } catch (e) {
      print("Error releasing LiveKit room: $e");
    }

    if (mounted) {
      // ملاحظة: لا نحتاج لإرسال إشعار للسيرفر هنا، لأن LiveKit سيخبر السائق تلقائياً بانفصالك
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _endCall(); // ضمان تنظيف الموارد عند إغلاق الشاشة
    super.dispose();
  }

  String _getCallStatus() {
    if (_hasError) return _errorMessage;
    if (_isRemoteConnected) return "متصل الآن 🟢";
    if (_isConnected) return "يرن عند السائق... ⏳";
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
                    child: const CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 70, color: Colors.white70),
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
                        Flexible(
                          child: Text(
                            _getCallStatus(),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
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
