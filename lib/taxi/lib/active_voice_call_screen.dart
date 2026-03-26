import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class ActiveVoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteName;
  final String agoraAppId;

  const ActiveVoiceCallScreen({
    super.key,
    required this.channelName,
    required this.remoteName,
    this.agoraAppId = "3924f8eebe7048f8a65cb3bd4a4adcec",
  });

  @override
  State<ActiveVoiceCallScreen> createState() => _ActiveVoiceCallScreenState();
}

class _ActiveVoiceCallScreenState extends State<ActiveVoiceCallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;

  // ✅ تم توحيد أسماء المتغيرات لتصحيح الخطأ
  bool _isMuted = false;
  bool _isSpeaker = false;

  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;

  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initAgora();

    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_remoteUid == null) {
        print("⏳ انتهى الوقت ولم يتم الاتصال بالسائق، جاري إنهاء المكالمة.");
        _endCall();
      }
    });
  }

  Future<void> _initAgora() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _hasError = true;
        _errorMessage = "يرجى منح صلاحية المايكروفون في إعدادات الجهاز";
      });
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: widget.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) {
            setState(() => _localUserJoined = true);
            // ✅ هنا تم تصحيح الاسم
            _engine.setEnableSpeakerphone(_isSpeaker);
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted && !_hasError) {
            _timeoutTimer?.cancel();
            setState(() {
              _remoteUid = remoteUid;
            });
            _startTimer();
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted && _localUserJoined) {
            _showCallEndedDialog("الكابتن أنهى المكالمة");
          }
        },
        onError: (ErrorCodeType err, String msg) {
          if (mounted && !_hasError) {
            setState(() {
              _hasError = true;
              _errorMessage = "خطأ في الاتصال: $msg";
            });
          }
        },
      ));

      await _engine.enableAudio();

      const ChannelMediaOptions options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      );

      await _engine.joinChannel(
        token: "",
        channelId: widget.channelName,
        uid: 0,
        options: options,
      );

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
      if (mounted && _remoteUid != null) {
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

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeaker = !_isSpeaker);
    _engine.setEnableSpeakerphone(_isSpeaker);
  }

  void _endCall() async {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();

    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      print("Error releasing Agora engine: $e");
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();
    try {
      _engine.leaveChannel();
      _engine.release();
    } catch (e) {
      print("Error in dispose: $e");
    }
    super.dispose();
  }

  String _getCallStatus() {
    if (_hasError) return _errorMessage;
    if (_remoteUid != null) return "متصل الآن 🟢";
    if (_localUserJoined) return "جاري الاتصال بالكابتن... ⏳";
    return "تهيئة الاتصال...";
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
                    "رقم الغرفة: ${widget.channelName}",
                    style: const TextStyle(fontSize: 12, color: Colors.yellow),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasError
                          ? Colors.red.withOpacity(0.2)
                          : (_remoteUid != null ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _hasError
                            ? Colors.red
                            : (_remoteUid != null ? Colors.green : Colors.blue),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasError
                              ? Icons.error
                              : (_remoteUid != null ? Icons.check_circle : Icons.access_time),
                          color: _hasError ? Colors.red : (_remoteUid != null ? Colors.green : Colors.blue),
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
