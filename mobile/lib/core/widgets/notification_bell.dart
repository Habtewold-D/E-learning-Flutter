import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../api/api_client.dart';
import '../../features/notifications/services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  final bool isTeacher;

  const NotificationBell({
    super.key,
    required this.isTeacher,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with WidgetsBindingObserver {
  late final NotificationService _notificationService;
  int _unreadCount = 0;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(ApiClient());
    WidgetsBinding.instance.addObserver(this);
    _refreshCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshCount());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCount();
    }
  }

  Future<void> _refreshCount() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final items = await _notificationService.fetchInAppNotifications();
      if (!mounted) return;
      final count = items.where((n) => !n.isRead).length;
      setState(() {
        _unreadCount = count;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openNotifications(BuildContext context) async {
    await _notificationService.markAllRead();
    if (!mounted) return;
    await _refreshCount();
    final route = widget.isTeacher ? '/teacher/notifications' : '/student/notifications';
    await context.push(route);
    if (!mounted) return;
    await _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _openNotifications(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications),
          if (_unreadCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
    );
  }
}
