import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../auth/models/user_model.dart';

class StudentLiveClassJoinScreen extends StatefulWidget {
  final String roomName;

  const StudentLiveClassJoinScreen({
    super.key,
    required this.roomName,
  });

  @override
  State<StudentLiveClassJoinScreen> createState() => _StudentLiveClassJoinScreenState();
}

class _StudentLiveClassJoinScreenState extends State<StudentLiveClassJoinScreen> {
  final _jitsiMeet = JitsiMeet();
  User? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final raw = await SecureStorage.getUserData();
      if (raw != null) {
        final jsonMap = json.decode(raw) as Map<String, dynamic>;
        setState(() {
          _currentUser = User.fromJson(jsonMap);
          _loadingUser = false;
        });
      } else {
        setState(() => _loadingUser = false);
      }
    } catch (_) {
      setState(() => _loadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomName = widget.roomName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Join Live Class'),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.secondary.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Live Class',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.videocam,
                              size: 64,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Room: $roomName',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _joinLiveClass(roomName),
                      icon: const Icon(Icons.meeting_room),
                      label: const Text('Join Class (In-App)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'The meeting opens in-app. Your display name is auto-filled.',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _joinLiveClass(String roomName) async {
    if (_loadingUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing meeting...')),
      );
      return;
    }

    try {
      // Darken status and navigation bars while Jitsi is active
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2B2B2B),
        systemNavigationBarColor: Color(0xFF2B2B2B),
        systemNavigationBarDividerColor: Color(0xFF2B2B2B),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ));

      var options = JitsiMeetConferenceOptions(
        room: roomName,
        serverURL: "https://meet.jit.si",
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": true,
          "prejoinPageEnabled": false,
          "requireDisplayName": false,
          "disableLobbyMode": true,
          "knockingEnabled": false,
          "lobbyEnabled": false,
          "enableLobby": false,
          "subject": "Live Class",
          "disableDeepLinking": true,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "ios.recording.enabled": false,
          "lobby-mode.enabled": false,
          "prejoinpage.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: _currentUser?.name ?? "Student",
          email: _currentUser?.email ?? "",
        ),
      );

      await _jitsiMeet.join(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Restore system UI overlays when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF2B2B2B),
      systemNavigationBarDividerColor: Color(0xFF2B2B2B),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }
}
