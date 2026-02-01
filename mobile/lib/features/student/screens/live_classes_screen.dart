import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/widgets/student_drawer.dart';
import '../../auth/models/user_model.dart';
import '../../courses/models/enrolled_course_model.dart';
import '../../teacher/models/live_class.dart';
import '../services/course_service.dart';
import '../services/live_class_service.dart';

class StudentLiveClassesScreen extends StatefulWidget {
  const StudentLiveClassesScreen({super.key});

  @override
  State<StudentLiveClassesScreen> createState() => _StudentLiveClassesScreenState();
}

class _StudentLiveClassesScreenState extends State<StudentLiveClassesScreen> {
  late final StudentLiveClassService _liveClassService;
  late final StudentCourseService _courseService;
  final _jitsiMeet = JitsiMeet();

  List<LiveClass> _liveClasses = [];
  List<EnrolledCourse> _courses = [];
  String _filter = 'all'; // 'all', 'upcoming', 'live', 'ended'
  bool _isLoading = true;
  String? _error;
  User? _currentUser;
  bool _loadingUser = true;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _liveClassService = StudentLiveClassService(ApiClient());
    _courseService = StudentCourseService(ApiClient());
    _loadUser();
    _fetchData();
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

  Future<void> _fetchData() async {
    var hadCache = false;
    final cachedLive = await CacheService.getJson('cache:student:live_classes');
    final cachedCourses = await CacheService.getJson('cache:student:enrolled_courses');

    if (cachedLive is List || cachedCourses is List) {
      hadCache = true;
      if (!mounted) return;
      setState(() {
        if (cachedLive is List) {
          _liveClasses = cachedLive
              .map((json) => LiveClass.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        if (cachedCourses is List) {
          _courses = cachedCourses
              .map((json) => EnrolledCourse.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        _error = null;
        _isLoading = false;
      });
    }

    if (!hadCache && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final liveClasses = await _liveClassService.fetchLiveClasses();
      final courses = await _courseService.fetchEnrolledCourses();

      final enrolledCourseIds = courses.map((c) => c.id).toSet();
      final filteredLiveClasses = liveClasses
          .where((liveClass) => enrolledCourseIds.contains(liveClass.courseId))
          .toList();

      setState(() {
        _liveClasses = filteredLiveClasses;
        _courses = courses;
        _isLoading = false;
        _error = null;
      });

      await CacheService.setJson(
        'cache:student:live_classes',
        filteredLiveClasses.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      if (!hadCache) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _liveClasses.where((liveClass) {
      if (_filter == 'all') return true;
      if (_filter == 'live') return liveClass.status == 'active';
      if (_filter == 'upcoming') return liveClass.status == 'scheduled';
      if (_filter == 'ended') return liveClass.status == 'ended';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Classes'),
        elevation: 0,
      ),
      drawer: const StudentDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load live classes',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _filter == 'all',
                            onSelected: (selected) => setState(() => _filter = 'all'),
                          ),
                          ChoiceChip(
                            label: const Text('Upcoming'),
                            selected: _filter == 'upcoming',
                            onSelected: (selected) => setState(() => _filter = 'upcoming'),
                          ),
                          ChoiceChip(
                            label: const Text('Live'),
                            selected: _filter == 'live',
                            onSelected: (selected) => setState(() => _filter = 'live'),
                          ),
                          ChoiceChip(
                            label: const Text('Ended'),
                            selected: _filter == 'ended',
                            onSelected: (selected) => setState(() => _filter = 'ended'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredClasses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_call_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No live classes found',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchData,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredClasses.length,
                                itemBuilder: (context, index) {
                                  final liveClass = filteredClasses[index];
                                  return _buildLiveClassCard(liveClass);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLiveClassCard(LiveClass liveClass) {
    final status = liveClass.status;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'scheduled':
        statusColor = Colors.blue;
        statusText = 'Upcoming';
        statusIcon = Icons.schedule;
        break;
      case 'active':
        statusColor = Colors.red;
        statusText = 'Live Now';
        statusIcon = Icons.videocam;
        break;
      case 'ended':
        statusColor = Colors.grey;
        statusText = 'Ended';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    final course = _courses.firstWhere(
      (c) => c.id == liveClass.courseId,
      orElse: () => EnrolledCourse(
        id: liveClass.courseId,
        title: 'Course #${liveClass.courseId}',
        description: '',
        contentCount: 0,
        completedContent: 0,
        progress: 0,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: status == 'active' ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: status == 'live'
            ? BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (status == 'active') {
            _handleJoin(liveClass);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  status == 'scheduled'
                      ? 'Class has not started yet. Please wait for the teacher.'
                      : 'This live class has ended',
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveClass.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.title,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Course ID: ${liveClass.courseId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _buildTimeText(liveClass),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _endTimeText(liveClass),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: status == 'active'
                      ? () => _handleJoin(liveClass)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'active' ? Colors.red : statusColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    status == 'active'
                        ? 'Join Now'
                        : status == 'scheduled'
                            ? 'Waiting for teacher'
                            : 'Class Ended',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTimeText(LiveClass liveClass) {
    if (liveClass.status == 'active' && liveClass.startedAt != null) {
      return 'Started: ${liveClass.startedAt!.toLocal()}';
    }
    if (liveClass.status == 'scheduled' && liveClass.scheduledTime != null) {
      return 'Starts: ${liveClass.scheduledTime!.toLocal()}';
    }
    if (liveClass.endedAt != null) {
      return 'Ended: ${liveClass.endedAt!.toLocal()}';
    }
    return 'Time not set';
  }

  String _endTimeText(LiveClass liveClass) {
    final base = liveClass.startedAt ?? liveClass.scheduledTime;
    if (base == null) return 'Ends ~1h after start';
    final end = base.add(const Duration(hours: 1));
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return 'Will end by ${formatter.format(end)} (max 1h)';
  }

  Future<void> _handleJoin(LiveClass liveClass) async {
    try {
      final joined = await _liveClassService.joinLiveClass(liveClass.id);
      if (!mounted) return;
      final tokenResponse = await _liveClassService.fetchJaasToken(joined.id);
      if (!mounted) return;
      await _joinRoomDirectly(
        tokenResponse['room'] as String,
        tokenResponse['token'] as String,
        tokenResponse['server_url'] as String,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _joinRoomDirectly(
    String roomName,
    String token,
    String serverUrl,
  ) async {
    if (_isJoining) return;
    _isJoining = true;
    if (_loadingUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing meeting...')),
        );
      }
      _isJoining = false;
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

      final options = JitsiMeetConferenceOptions(
        room: _coerceRoomName(roomName),
        serverURL: serverUrl,
        token: token,
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": true,
          "prejoinPageEnabled": false,
          "requireDisplayName": false,
          "disableLobbyMode": true,
          "knockingEnabled": false,
          "lobbyEnabled": false,
          "enableLobby": false,
          "lobby.enabled": false,
          "lobbyModeEnabled": false,
          "membersOnly": false,
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
          displayName: _buildDisplayName(),
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
    } finally {
      _isJoining = false;
    }
  }

  String _coerceRoomName(String roomName) {
    var normalized = roomName.trim();
    if (normalized.startsWith('vpaas-') && normalized.contains('/')) {
      return normalized;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      try {
        final uri = Uri.parse(normalized);
        if (uri.pathSegments.isNotEmpty) {
          normalized = uri.pathSegments.last;
        }
      } catch (_) {
        // Use original string if parsing fails
      }
    }
    if (normalized.contains('/')) {
      normalized = normalized.split('/').last;
    }
    return normalized;
  }

  String _buildDisplayName() {
    final user = _currentUser;
    if (user == null) return 'Student';
    final role = user.role.isNotEmpty ? user.role : 'student';
    return '${user.name} ($role #${user.id})';
  }

}






