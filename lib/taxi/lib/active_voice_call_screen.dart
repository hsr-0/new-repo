import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class ActiveVoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteName;

  const ActiveVoiceCallScreen({
    super.key,
    required this.channelName,
    required this.remoteName,
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {
  // ⚠️ ضع الـ App ID الخاص بك من حساب Agora هنا
  final String appId = "3924f8eebe7048f8a65cb3bd4a4adcec";

  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeaker = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. طلب صلاحية المايكروفون
    await [Permission.microphone].request();

    // 2. تهيئة محرك الصوت
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 3. الاستماع لأحداث المكالمة
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
          // ✅ تشغيل السبيكر يتم هنا بعد نجاح الاتصال بالغرفة
          _engine.setEnableSpeakerphone(_isSpeaker);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _endCall();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() => _isJoined = false);
        },
      ),
    );

    // 4. تمكين الصوت والانضمام للغرفة
    await _engine.enableAudio();
    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }
  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeaker = !_isSpeaker);
    _engine.setEnableSpeakerphone(_isSpeaker);
  }

  void _endCall() async {
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // صورة المتصل
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // اسم المتصل
            Text(
              widget.remoteName,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // حالة المكالمة
            Text(
              _remoteUid != null ? '00:00 (متصل)' : (_isJoined ? 'جاري الاتصال...' : 'تهيئة...'),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),

            // أزرار التحكم
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // المايكروفون
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.white : Colors.white24,
                    iconColor: _isMuted ? Colors.black : Colors.white,
                    onPressed: _toggleMute,
                  ),
                  // إنهاء المكالمة
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    iconColor: Colors.white,
                    size: 65,
                    onPressed: _endCall,
                  ),
                  // السبيكر
                  _buildControlButton(
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                    color: _isSpeaker ? Colors.white : Colors.white24,
                    iconColor: _isSpeaker ? Colors.black : Colors.white,
                    onPressed: _toggleSpeaker,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    double size = 55,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}