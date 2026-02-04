import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/teacher_drawer.dart';
import '../../../core/widgets/student_drawer.dart';
import '../models/in_app_notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isTeacher;

  const NotificationsScreen({
    super.key,
    required this.isTeacher,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notificationService;
  bool _loading = true;
  String? _error;
  List<InAppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(ApiClient());
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _notificationService.fetchInAppNotifications();
      if (!mounted) return;
      await _notificationService.markAllRead();
      setState(() {
        _notifications = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteNotification(InAppNotification item) async {
    try {
      await _notificationService.deleteInAppNotification(item.id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.where((n) => n.id != item.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _markRead(InAppNotification item, bool isRead) async {
    try {
      final updated = await _notificationService.markAsRead(item.id, isRead);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => n.id == item.id ? updated : n)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isTeacher
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      drawer: widget.isTeacher ? const TeacherDrawer() : const StudentDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(Icons.notifications_off, size: 48, color: Colors.grey[500]),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  )
                : _notifications.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Icon(Icons.notifications_none, size: 48, color: Colors.grey[500]),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          return Dismissible(
                            key: ValueKey('notif-${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.red.shade400,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _deleteNotification(item),
                            child: _NotificationTile(
                              item: item,
                              accentColor: color,
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: _notifications.length,
                      ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final InAppNotification item;
  final Color accentColor;

  const _NotificationTile({
    required this.item,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, h:mm a');
    final timeLabel = formatter.format(item.createdAt);

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final unreadColor = accentColor.withOpacity(0.12);
    final borderColor = theme.dividerColor;
    final bodyColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final captionColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isRead ? cardColor : unreadColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead ? borderColor : accentColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!item.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
          if (!item.isRead) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: TextStyle(
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
