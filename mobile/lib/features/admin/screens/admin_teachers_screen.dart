import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/widgets/admin_bottom_nav.dart';
import '../../../core/widgets/admin_drawer.dart';
import '../../auth/models/user_model.dart';
import '../services/admin_service.dart';

class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  late final AdminService _adminService;
  bool _isLoading = true;
  String? _error;
  List<User> _teachers = [];

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(ApiClient());
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    const cacheKey = 'cache:admin:teachers';
    var hadCache = false;

    final cached = await CacheService.getJson(cacheKey);
    if (cached is List) {
      hadCache = true;
      if (!mounted) return;
      setState(() {
        _teachers = cached
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
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
      final teachers = await _adminService.fetchTeachers();
      if (!mounted) return;
      setState(() {
        _teachers = teachers;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!hadCache) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showTeacherForm({User? teacher}) async {
    final nameController = TextEditingController(text: teacher?.name ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(teacher == null ? 'Create Teacher' : 'Edit Teacher'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: teacher == null ? 'Password' : 'New Password (optional)',
                ),
                obscureText: true,
                validator: (value) {
                  if (teacher == null && (value == null || value.isEmpty)) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              await _saveTeacher(
                teacher: teacher,
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                password: passwordController.text,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTeacher({
    User? teacher,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (teacher == null) {
        final created = await _adminService.createTeacher(
          name: name,
          email: email,
          password: password,
        );
        if (!mounted) return;
        setState(() {
          _teachers.add(created);
        });
      } else {
        final updated = await _adminService.updateTeacher(
          teacherId: teacher.id,
          name: name,
          email: email,
          password: password.isNotEmpty ? password : null,
        );
        if (!mounted) return;
        setState(() {
          _teachers = _teachers.map((t) => t.id == updated.id ? updated : t).toList();
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmDelete(User teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Delete ${teacher.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteTeacher(teacher.id);
      if (!mounted) return;
      setState(() {
        _teachers.removeWhere((t) => t.id == teacher.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTeacherForm(),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeachers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeachers,
                  child: _teachers.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Icon(Icons.people_outline, size: 72, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'No teachers found',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = _teachers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(teacher.name),
                                subtitle: Text(teacher.email),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showTeacherForm(teacher: teacher);
                                    } else if (value == 'delete') {
                                      _confirmDelete(teacher);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
