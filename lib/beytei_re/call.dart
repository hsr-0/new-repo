import 'dart:async'; // ✅ إصلاح مشكلة Timer
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerCallPage extends StatefulWidget {
  final String channelName;
  final String driverName;
  final String agoraAppId;

  const CustomerCallPage({
    super.key,
    required this.channelName,
    required this.driverName,
    this.agoraAppId = "3924f8eebe7048f8a65cb3bd4a4adcec",
  });

  @override
  State<CustomerCallPage> createState() => _CustomerCallPageState();
}

class _CustomerCallPageState extends State<CustomerCallPage> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _speaker = false;
  int _callDuration = 0;
  Timer? _timer; // ✅ الآن سيعمل لأننا أضفنا مكتبة dart:async
  bool _isCallEnded = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startTimer();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: widget.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("✅ Joined: ${connection.channelId}");
          if (mounted) setState(() => _localUserJoined = true);
        },
        // ✅ تم الإصلاح: الدالة تتطلب معاملين (connection, stats)
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("👋 Left Channel");
        },
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint("🚫 Driver Left");
          _onCallEndedByRemote();
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.setEnableSpeakerphone(_speaker);

    await _engine.joinChannel(
      // ✅ تم الإصلاح: Agora تتطلب String وليس Null، نمرر نص فارغ في حالة عدم وجود توكين
      token: "",
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onCallEndedByRemote() {
    if (_isCallEnded) return;
    _isCallEnded = true;
    _timer?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("انتهت المكالمة من قبل السائق"), backgroundColor: Colors.red),
      );
      Future.delayed(const Duration(seconds: 2), () {
        _leaveChannel();
      });
    }
  }

  Future<void> _leaveChannel() async {
    _timer?.cancel();
    await _engine.leaveChannel();
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveChannel();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF202124),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.lock, color: Colors.white54, size: 16),
                    Text(
                      _localUserJoined ? _formatDuration(_callDuration) : "جاري الاتصال...",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.driverName,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _localUserJoined ? "في مكالمة" : "يرن...",
                    style: TextStyle(color: _localUserJoined ? Colors.green : Colors.white54),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 50, left: 30, right: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => _muted = !_muted);
                        _engine.muteLocalAudioStream(_muted);
                      },
                      icon: Icon(_muted ? Icons.mic_off : Icons.mic, color: Colors.white, size: 30),
                    ),
                    FloatingActionButton(
                      onPressed: _leaveChannel,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _speaker = !_speaker);
                        _engine.setEnableSpeakerphone(_speaker);
                      },
                      icon: Icon(_speaker ? Icons.volume_up : Icons.volume_down, color: Colors.white, size: 30),
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