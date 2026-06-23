import 'package:flutter/material.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final StudentSubject? subject; // If null, shows all subjects
  const StudentAttendanceScreen({super.key, this.subject});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final StudentRepository _repo = const StudentRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _records = [];
  Map<String, Map<String, int>> _summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _records = await _repo.fetchMyAttendance();
      _summary = await _repo.fetchMyAttendanceSummary();

      // Filter by subject if specified
      if (widget.subject != null) {
        _records = _records.where((r) => r['subjectId'] == widget.subject!.id).toList();
      }
    } catch (_) {
      _records = [];
      _summary = {};
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, int> get _totalSummary {
    if (widget.subject != null) {
      return _summary[widget.subject!.id] ?? {'present': 0, 'late': 0, 'absent': 0, 'total': 0};
    }
    int present = 0, late = 0, absent = 0, total = 0;
    for (final s in _summary.values) {
      present += s['present'] ?? 0;
      late += s['late'] ?? 0;
      absent += s['absent'] ?? 0;
      total += s['total'] ?? 0;
    }
    return {'present': present, 'late': late, 'absent': absent, 'total': total};
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return const Color(0xFF059669);
      case 'late': return const Color(0xFFD97706);
      case 'absent': return const Color(0xFFDC2626);
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present': return Icons.check_circle_rounded;
      case 'late': return Icons.access_time_rounded;
      case 'absent': return Icons.cancel_rounded;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _totalSummary;
    final total = summary['total'] ?? 0;
    final present = summary['present'] ?? 0;
    final late = summary['late'] ?? 0;
    final absent = summary['absent'] ?? 0;
    final rate = total > 0 ? ((present + late) / total * 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: const Color(0xFF0A5C36),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.school, color: Colors.white, size: 28),
                          SizedBox(height: 2),
                          Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                  const Text('My Attendance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        // Subject title if specific
                        if (widget.subject != null) ...[
                          Text(widget.subject!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
                          Text('${widget.subject!.courseCode} ${widget.subject!.yearLevel}-${widget.subject!.section}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 16),
                        ],

                        // Summary card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCircle('${rate.toStringAsFixed(0)}%', 'Rate', rate >= 80 ? Colors.green : Colors.orange),
                                  _buildStatCircle('$present', 'Present', const Color(0xFF059669)),
                                  _buildStatCircle('$late', 'Late', const Color(0xFFD97706)),
                                  _buildStatCircle('$absent', 'Absent', const Color(0xFFDC2626)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('$total total sessions recorded',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Records list
                        const Text('Attendance Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),

                        if (_records.isEmpty)
                          _buildEmptyState()
                        else
                          ..._records.map((r) => _buildRecordCard(r)),
                      ],
                    ),
                  ),
          ),
          const StudentFloatingNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          alignment: Alignment.center,
          child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> r) {
    final status = r['status']?.toString() ?? 'present';
    final date = r['date']?.toString() ?? '';
    final subjectName = r['subjectName']?.toString() ?? '';

    // Format date
    String displayDate = date;
    final dt = DateTime.tryParse(date);
    if (dt != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      displayDate = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_statusIcon(status), color: _statusColor(status), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                if (widget.subject == null && subjectName.isNotEmpty)
                  Text(subjectName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(status)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No attendance records yet.', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
