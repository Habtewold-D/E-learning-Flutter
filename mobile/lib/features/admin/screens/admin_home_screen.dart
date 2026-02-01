import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/admin_bottom_nav.dart';
import '../models/admin_stats_model.dart';
import '../services/admin_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final AdminService _adminService;
  AdminStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(ApiClient());
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _adminService.fetchStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
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
                        onPressed: _loadStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle('Users'),
                      const SizedBox(height: 8),
                      _buildGrid([
                        _buildStatCard('Total Users', _stats?.totalUsers ?? 0, Icons.people),
                        _buildStatCard('Students', _stats?.totalStudents ?? 0, Icons.school),
                        _buildStatCard('Teachers', _stats?.totalTeachers ?? 0, Icons.person),
                        _buildStatCard('Admins', _stats?.totalAdmins ?? 0, Icons.security),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Courses'),
                      const SizedBox(height: 8),
                      _buildGrid([
                        _buildStatCard('Courses', _stats?.totalCourses ?? 0, Icons.book),
                        _buildStatCard('Content', _stats?.totalContentItems ?? 0, Icons.description),
                        _buildStatCard('Exams', _stats?.totalExams ?? 0, Icons.quiz),
                        _buildStatCard('Live Classes', _stats?.totalLiveClasses ?? 0, Icons.video_call),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Enrollments'),
                      const SizedBox(height: 8),
                      _buildGrid([
                        _buildStatCard('Total', _stats?.enrollmentsTotal ?? 0, Icons.group_add),
                        _buildStatCard('Pending', _stats?.enrollmentsPending ?? 0, Icons.hourglass_empty),
                        _buildStatCard('Approved', _stats?.enrollmentsApproved ?? 0, Icons.check_circle),
                        _buildStatCard('Rejected', _stats?.enrollmentsRejected ?? 0, Icons.cancel),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Live Classes'),
                      const SizedBox(height: 8),
                      _buildGrid([
                        _buildStatCard('Scheduled', _stats?.liveClassesScheduled ?? 0, Icons.schedule),
                        _buildStatCard('Active', _stats?.liveClassesActive ?? 0, Icons.play_circle),
                        _buildStatCard('Ended', _stats?.liveClassesEnded ?? 0, Icons.stop_circle),
                      ]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: children,
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
