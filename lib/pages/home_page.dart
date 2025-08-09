import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../models/timer_state.dart';
import 'analytics_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              );
            },
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: Consumer<TimerService>(
        builder: (context, timerService, child) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Current Session Timer Card
                    _buildCurrentSessionCard(timerService),

                    const SizedBox(height: 20),

                    // Today's Summary Card
                    _buildTodaysSummaryCard(timerService),

                    const SizedBox(height: 40),

                    // Control Buttons
                    _buildControlButtons(context, timerService),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSessionCard(TimerService timerService) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(timerService.state.status),
                  color: _getStatusColor(timerService.state.status),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(timerService.state.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                timerService.state.formattedTime,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(timerService.state.status),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysSummaryCard(TimerService timerService) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Today\'s Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: Future.wait([
                timerService.getTodaysTotalSeconds(),
                timerService.getTodaysSessions(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final totalSeconds = snapshot.data![0] as int;
                final sessions = snapshot.data![1] as List;
                final currentSessionSeconds = timerService.state.elapsedSeconds;
                final totalWithCurrent = totalSeconds + currentSessionSeconds;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total Time',
                      _formatTime(totalWithCurrent),
                      Icons.timer,
                      Colors.grey.shade800,
                    ),
                    _buildSummaryItem(
                      'Sessions',
                      '${sessions.length + (timerService.state.isRunning || timerService.state.isPaused ? 1 : 0)}',
                      Icons.play_circle,
                      Colors.grey.shade600,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context, TimerService timerService) {
    final state = timerService.state;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        // Start/Pause Button
        ElevatedButton.icon(
          onPressed: state.isRunning
              ? () => timerService.pauseTimer()
              : () => timerService.startTimer(),
          icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(state.isRunning ? 'Pause' : 'Start'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),

        // Stop Button
        ElevatedButton.icon(
          onPressed: (state.isRunning || state.isPaused)
              ? () => _showStopConfirmation(context, timerService)
              : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),

        // Reset Button
        ElevatedButton.icon(
          onPressed: (state.elapsedSeconds > 0)
              ? () => _showResetConfirmation(context, timerService)
              : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _showStopConfirmation(BuildContext context, TimerService timerService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop Session'),
          content: const Text(
            'Are you sure you want to stop this session? '
            'This will save your progress and end the current session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                timerService.stopTimer();
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, TimerService timerService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Session'),
          content: const Text(
            'Are you sure you want to reset this session? '
            'This will delete all progress for the current session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                timerService.resetTimer();
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  IconData _getStatusIcon(TimerStatus status) {
    switch (status) {
      case TimerStatus.running:
        return Icons.play_arrow;
      case TimerStatus.paused:
        return Icons.pause;
      case TimerStatus.stopped:
        return Icons.stop;
      case TimerStatus.initial:
        return Icons.timer;
    }
  }

  Color _getStatusColor(TimerStatus status) {
    switch (status) {
      case TimerStatus.running:
        return Colors.grey.shade800;
      case TimerStatus.paused:
        return Colors.grey.shade600;
      case TimerStatus.stopped:
        return Colors.grey.shade500;
      case TimerStatus.initial:
        return Colors.grey.shade400;
    }
  }

  String _getStatusText(TimerStatus status) {
    switch (status) {
      case TimerStatus.running:
        return 'Timer is running';
      case TimerStatus.paused:
        return 'Timer is paused';
      case TimerStatus.stopped:
        return 'Timer stopped';
      case TimerStatus.initial:
        return 'Ready to start';
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
