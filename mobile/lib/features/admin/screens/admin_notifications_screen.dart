import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/admin_drawer.dart';
import '../../../core/widgets/admin_bottom_nav.dart';
import '../services/admin_notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _sendPush = true;
  bool _sendInApp = true;
  String _targetRole = 'all';
  bool _isSending = false;

  late final AdminNotificationService _service;

  @override
  void initState() {
    super.initState();
    _service = AdminNotificationService(ApiClient());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_sendPush && !_sendInApp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one channel'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _service.sendNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        targetRole: _targetRole,
        sendPush: _sendPush,
        sendInApp: _sendInApp,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification sent'),
          backgroundColor: Colors.green,
        ),
      );
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Send Notification',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bodyController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Message is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _targetRole,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All users')),
                          DropdownMenuItem(value: 'teacher', child: Text('Teachers only')),
                          DropdownMenuItem(value: 'student', child: Text('Students only')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _targetRole = value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Target audience',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Send Push Notification'),
                        value: _sendPush,
                        onChanged: (value) => setState(() => _sendPush = value),
                      ),
                      SwitchListTile(
                        title: const Text('Send In-App Notification'),
                        value: _sendInApp,
                        onChanged: (value) => setState(() => _sendInApp = value),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _send,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(_isSending ? 'Sending...' : 'Send'),
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
    );
  }
}
