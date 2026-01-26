import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/widgets/teacher_drawer.dart';
import '../../auth/models/user_model.dart';

class LiveClassJoinScreen extends StatefulWidget {
  final String roomName;

  const LiveClassJoinScreen({
    super.key,
    required this.roomName,
  });

  @override
  State<LiveClassJoinScreen> createState() => _LiveClassJoinScreenState();
}

class _LiveClassJoinScreenState extends State<LiveClassJoinScreen> {
  final _jitsiMeet = JitsiMeet();
  User? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _setupJitsiListeners();
  }

  void _setupJitsiListeners() {
    // Note: JitsiMeet listeners might need different setup based on SDK version
    // For now, we'll handle navigation in the join method
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
    // For now, we'll use mock data. In a full implementation, we'd fetch the live class details
    final liveClass = {
      'roomName': widget.roomName,
      'courseName': 'Live Class', // TODO: Fetch from API
      'roomUrl': 'https://meet.jit.si/${widget.roomName}',
      'participants': 0, // TODO: Add participant count
      'status': 'active',
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Live Class'),
        elevation: 0,
      ),
      drawer: const TeacherDrawer(),
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
                  // Class Info Card
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
                              Icons.video_call,
                              size: 64,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            liveClass['courseName'] as String,
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
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
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

                  // Join Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _joinLiveClass(liveClass['roomName'] as String),
                      icon: const Icon(Icons.video_call),
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

                  // Room URL (for sharing)
                  Card(
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Room URL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            liveClass['roomUrl'] as String,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _copyToClipboard(liveClass['roomUrl'] as String),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy URL'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info
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
                              'The meeting opens in-app and should finish within 1 hour of start. Manage participants from the Jitsi UI.',
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
        const SnackBar(content: Text('Please wait, preparing meeting...')),
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
          // reduce prejoin friction and keep everything in-app
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
          displayName: _currentUser?.name ?? "Guest",
          email: _currentUser?.email ?? "",
        ),
      );

      await _jitsiMeet.join(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining Jitsi meeting: $e'),
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

  Future<void> _copyToClipboard(String url) async {
    // TODO: Implement clipboard functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room URL copied to clipboard')),
      );
    }
  }
}






