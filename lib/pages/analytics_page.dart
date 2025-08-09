import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/timer_service.dart';
import '../models/session.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Weekly', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Sessions', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildWeeklyTab(), _buildSessionsTab()],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatsCards(timerService),
              const SizedBox(height: 20),
              _buildTodaysSessionsChart(timerService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(TimerService timerService) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        timerService.getTotalTimeSeconds(),
        timerService.getTotalSessionsCount(),
        timerService.getTodaysTotalSeconds(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final totalTime = snapshot.data![0] as int;
        final totalSessions = snapshot.data![1] as int;
        final todayTime = snapshot.data![2] as int;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Time',
                _formatDuration(totalTime),
                Icons.timer,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Sessions',
                '$totalSessions',
                Icons.play_circle,
                Theme.of(context).colorScheme.primary.withOpacity(0.85),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Today',
                _formatDuration(todayTime),
                Icons.today,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysSessionsChart(TimerService timerService) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Session>>(
              future: timerService.getTodaysSessions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final sessions = snapshot.data!;

                if (sessions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No sessions today yet.\nStart a timer to see your progress!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: _buildSessionsBarChart(sessions),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTab() {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildWeeklyChart(timerService),
              const SizedBox(height: 20),
              _buildWeeklyStats(timerService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart(TimerService timerService) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<DateTime, int>>(
              future: timerService.getWeeklyData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final weeklyData = snapshot.data!;

                return SizedBox(
                  height: 250,
                  child: _buildWeeklyBarChart(weeklyData),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStats(TimerService timerService) {
    return FutureBuilder<Map<DateTime, int>>(
      future: timerService.getWeeklyData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final weeklyData = snapshot.data!;
        final totalSeconds = weeklyData.values.fold(0, (a, b) => a + b);
        final averageSeconds = totalSeconds / 7;
        final maxDay = weeklyData.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeeklyStat('Total', _formatDuration(totalSeconds)),
                    _buildWeeklyStat(
                      'Average',
                      _formatDuration(averageSeconds.round()),
                    ),
                    _buildWeeklyStat(
                      'Best Day',
                      '${DateFormat('EEE').format(maxDay.key)}\n${_formatDuration(maxDay.value)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSessionsTab() {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return FutureBuilder<List<Session>>(
          future: timerService.getAllSessions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data!
                .where((session) => session.isCompleted)
                .toList();

            if (sessions.isEmpty) {
              return const Center(
                child: Text(
                  'No completed sessions yet.\nStart and complete a session to see history!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionListItem(session);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSessionListItem(Session session) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            session.durationSeconds ~/ 60 < 60
                ? '${session.durationSeconds ~/ 60}m'
                : '${session.durationSeconds ~/ 3600}h',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session.formattedDuration,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(session.startTime)),
            Text(
              '${timeFormat.format(session.startTime)} - ${timeFormat.format(session.endTime!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSessionsBarChart(List<Session> sessions) {
    final primary = Theme.of(context).colorScheme.primary;
    final data = sessions.asMap().entries.map((entry) {
      final index = entry.key;
      final session = entry.value;
      final minutes = session.durationSeconds / 60;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: minutes,
            color: primary.withOpacity(0.8),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final maxMinutes = sessions.isNotEmpty
        ? sessions
              .map((s) => s.durationSeconds / 60)
              .reduce((a, b) => a > b ? a : b)
        : 60.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxMinutes * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBorder: const BorderSide(color: Colors.grey),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final session = sessions[group.x];
              return BarTooltipItem(
                session.formattedDuration,
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt() + 1}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}m',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data,
      ),
    );
  }

  Widget _buildWeeklyBarChart(Map<DateTime, int> weeklyData) {
    final primary = Theme.of(context).colorScheme.primary;
    final sortedEntries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final data = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final dateEntry = entry.value;
      final hours = dateEntry.value / 3600;
      final isToday =
          DateFormat('yyyy-MM-dd').format(dateEntry.key) ==
          DateFormat('yyyy-MM-dd').format(DateTime.now());

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: isToday ? primary : primary.withOpacity(0.6),
            width: 25,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final maxHours = weeklyData.values.isNotEmpty
        ? weeklyData.values.map((s) => s / 3600).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxHours > 0 ? maxHours * 1.2 : 1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBorder: const BorderSide(color: Colors.grey),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = sortedEntries[group.x];
              return BarTooltipItem(
                _formatDuration(entry.value),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final date = sortedEntries[value.toInt()].key;
                return Text(
                  DateFormat('EEE').format(date),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
