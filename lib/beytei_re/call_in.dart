// 📞 شاشة المكالمة الخاصة بالسائق (محدثة مع LiveKit)
// =============================================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class DriverCallPage extends StatefulWidget {
  final String roomName;
  final String livekitUrl;
  final String token;
  final String customerName;
  final String customerPhone;
  final String orderId;
  final String sourceType;

  const DriverCallPage({
    super.key,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    required this.customerName,
    required this.customerPhone,
    required this.orderId,
    required this.sourceType,
  });

  @override
  State<DriverCallPage> createState() => _DriverCallPageState();
}

class _DriverCallPageState extends State<DriverCallPage> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnected = false;
  bool _isCustomerConnected = false;
  bool _muted = false;
  bool _speaker = true;
  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initLiveKit();

    // إغلاق المكالمة تلقائياً بعد 45 ثانية إذا لم يرد الزبون
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_isCustomerConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الزبون لا يرد حالياً، جاري إنهاء المكالمة'), backgroundColor: Colors.orange),
        );
        _endCall();
      }
    });
  }

  Future<void> _initLiveKit() async {
    if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 500);

    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _hasError = true;
        _errorMessage = "يرجى منح صلاحية المايكروفون من إعدادات الجهاز";
      });
      return;
    }

    try {
      _room = Room();
      _listener = _room!.createListener();

      // 🆕 الاستماع للأحداث بالطريقة الحديثة
      _listener!.on<ParticipantConnectedEvent>((event) {
        if (!mounted) return;
        _timeoutTimer?.cancel();
        setState(() => _isCustomerConnected = true);
        _startDurationTimer();
      });

      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (!mounted) return;
        if (_isConnected) {
          _showCallEndedDialog("الزبون أنهى المكالمة");
        }
      });

      _listener!.on<RoomDisconnectedEvent>((event) {
        if (!mounted) return;
        _showCallEndedDialog("انقطع الاتصال");
      });

      // الاتصال بالغرفة
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
      await Hardware.instance.setSpeakerphoneOn(_speaker);

    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "فشل في بدء المكالمة: ${e.toString()}";
        });
      }
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
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
          title: const Row(children: [Icon(Icons.call_end, color: Colors.red), SizedBox(width: 10), Text("انتهت المكالمة")]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 10),
              Text("المدة: ${_formatDuration(_callDuration)}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
    setState(() => _muted = !_muted);
    await _room?.localParticipant?.setMicrophoneEnabled(!_muted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speaker = !_speaker);
    await Hardware.instance.setSpeakerphoneOn(_speaker);
  }

  Future<void> _sendCancelSignalToServer() async {
    try {
      String cancelUrl = 'https://re.beytei.com/wp-json/beytei-calls/v1/cancel';
      if (widget.sourceType == 'market' || widget.sourceType == 'store' || widget.sourceType == 'pharmacy') {
        cancelUrl = 'https://beytei.com/wp-json/beytei-calls/v1/cancel';
      }

      await http.post(
        Uri.parse(cancelUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'secret_key': 'BEYTEI_SECURE_2025',
          'order_id': widget.orderId,
          'channel_name': widget.roomName,
        }),
      );
    } catch (e) {
      print("Error cancelling call: $e");
    }
  }

  Future<void> _endCall() async {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      await _listener?.dispose();
      await _room?.disconnect();
      _room = null;
    } catch (e) {
      print("Error releasing LiveKit room: $e");
    }

    await _sendCancelSignalToServer();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  String getCallStatusText() {
    if (_hasError) return _errorMessage;
    if (_isCustomerConnected) return "متصل الآن 🟢";
    if (_isConnected) return "يرن عند الزبون... 🔵";
    return "جاري الاتصال بالسيرفر... ⏳";
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
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _endCall),
                    Text(_formatDuration(_callDuration), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(_speaker ? Icons.volume_up : Icons.volume_off, color: _speaker ? Colors.green : Colors.white70, size: 28),
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
                      child: const Icon(Icons.person, size: 70, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(widget.customerName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(widget.customerPhone, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasError ? Colors.red.withOpacity(0.2) : (_isCustomerConnected ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _hasError ? Colors.red : (_isCustomerConnected ? Colors.green : Colors.blue),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasError ? Icons.error : (_isCustomerConnected ? Icons.check_circle : Icons.access_time),
                          color: _hasError ? Colors.red : (_isCustomerConnected ? Colors.green : Colors.blue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          getCallStatusText(),
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: 5)],
                ),
                child: Row(
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
                              color: _muted ? Colors.red.withOpacity(0.2) : Colors.white10,
                              shape: BoxShape.circle,
                              border: Border.all(color: _muted ? Colors.red : Colors.white70, width: 1.5),
                            ),
                            child: Icon(_muted ? Icons.mic_off : Icons.mic, color: _muted ? Colors.red : Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(_muted ? "إلغاء الكتم" : "كتم", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)],
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
                              color: _speaker ? Colors.green.withOpacity(0.2) : Colors.white10,
                              shape: BoxShape.circle,
                              border: Border.all(color: _speaker ? Colors.green : Colors.white70, width: 1.5),
                            ),
                            child: Icon(_speaker ? Icons.volume_up : Icons.volume_down, color: _speaker ? Colors.green : Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(_speaker ? "إيقاف السماعة" : "تفعيل السماعة", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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
