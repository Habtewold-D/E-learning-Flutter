import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/widgets/admin_bottom_nav.dart';
import '../../../core/widgets/admin_drawer.dart';
import '../models/admin_analytics_model.dart';
import '../models/admin_trends_model.dart';
import '../services/admin_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late final AdminService _adminService;
  bool _isLoading = true;
  String? _error;
  AdminAnalytics? _analytics;
  AdminTrends? _trends;
  String _period = 'weekly';

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(ApiClient());
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final analyticsKey = 'cache:admin:analytics';
    final trendsKey = 'cache:admin:trends:$_period';
    var hadCache = false;

    final cachedAnalytics = await CacheService.getJson(analyticsKey);
    final cachedTrends = await CacheService.getJson(trendsKey);
    if (cachedAnalytics is Map<String, dynamic> || cachedTrends is Map<String, dynamic>) {
      hadCache = true;
      if (!mounted) return;
      setState(() {
        if (cachedAnalytics is Map<String, dynamic>) {
          _analytics = AdminAnalytics.fromJson(cachedAnalytics);
        }
        if (cachedTrends is Map<String, dynamic>) {
          _trends = AdminTrends.fromJson(cachedTrends);
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
      final results = await Future.wait([
        _adminService.fetchAnalytics(),
        _adminService.fetchTrends(period: _period),
      ]);
      final analytics = results[0] as AdminAnalytics;
      final trends = results[1] as AdminTrends;
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _trends = trends;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        elevation: 0,
      ),
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
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
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Enrollment Trends'),
                      const SizedBox(height: 8),
                      _buildTrendCard(
                        title: 'Enrollments',
                        labels: _trends?.labels ?? [],
                        values: _trends?.enrollments ?? [],
                        change: _trends?.enrollmentsChange ?? 0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Live Class Trends'),
                      const SizedBox(height: 8),
                      _buildTrendCard(
                        title: 'Live Classes',
                        labels: _trends?.labels ?? [],
                        values: _trends?.liveClasses ?? [],
                        change: _trends?.liveClassesChange ?? 0,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Enrollment Requests'),
                      const SizedBox(height: 8),
                      _buildInfoTile('Pending', _analytics?.enrollmentsPending ?? 0, Icons.hourglass_empty),
                      _buildInfoTile('Approved', _analytics?.enrollmentsApproved ?? 0, Icons.check_circle),
                      _buildInfoTile('Rejected', _analytics?.enrollmentsRejected ?? 0, Icons.cancel),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Live Classes'),
                      const SizedBox(height: 8),
                      _buildInfoTile('Scheduled', _analytics?.liveClassesScheduled ?? 0, Icons.schedule),
                      _buildInfoTile('Active', _analytics?.liveClassesActive ?? 0, Icons.play_circle),
                      _buildInfoTile('Ended', _analytics?.liveClassesEnded ?? 0, Icons.stop_circle),
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

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'weekly', label: Text('Weekly')),
        ButtonSegment(value: 'monthly', label: Text('Monthly')),
        ButtonSegment(value: 'yearly', label: Text('Yearly')),
      ],
      selected: {_period},
      onSelectionChanged: (value) {
        final next = value.first;
        if (next == _period) return;
        setState(() {
          _period = next;
        });
        _loadAnalytics();
      },
    );
  }

  Widget _buildTrendCard({
    required String title,
    required List<String> labels,
    required List<int> values,
    required double change,
    required Color color,
  }) {
    if (values.isEmpty || labels.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('No data available', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i].toDouble()));
    }

    final changeLabel = change.isNaN ? '0%' : '${change.toStringAsFixed(1)}%';
    final changeColor = change >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(change >= 0 ? Icons.trending_up : Icons.trending_down, color: changeColor),
                    const SizedBox(width: 4),
                    Text(changeLabel, style: TextStyle(color: changeColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: labels.length > 6 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(labels[index], style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: spots,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, int value, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
