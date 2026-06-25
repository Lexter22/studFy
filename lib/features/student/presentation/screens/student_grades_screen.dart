import 'package:flutter/material.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentGradesScreen extends StatefulWidget {
  final StudentSubject? subject; // If null, shows all subjects
  const StudentGradesScreen({super.key, this.subject});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  final StudentRepository _repo = const StudentRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _grades = [];
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _currentPage = 0;
    });
    try {
      if (widget.subject != null) {
        _grades = await _repo.fetchMyGradesForSubject(widget.subject!.id);
      } else {
        _grades = await _repo.fetchMyGrades();
      }
    } catch (_) {
      _grades = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _overallAverage {
    if (_grades.isEmpty) return 0;
    double totalScore = 0;
    double totalMax = 0;
    for (final g in _grades) {
      totalScore += (g['score'] as num?)?.toDouble() ?? 0;
      totalMax += (g['maxScore'] as num?)?.toDouble() ?? 100;
    }
    return totalMax > 0 ? (totalScore / totalMax) * 100 : 0;
  }

  /// Letter grade from an overall percentage (simple US-style scale).
  String _letterGrade(double pct) {
    if (pct >= 90) return 'A';
    if (pct >= 85) return 'B+';
    if (pct >= 80) return 'B';
    if (pct >= 75) return 'C';
    if (pct >= 70) return 'D';
    return 'F';
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'quiz': return const Color(0xFF7C3AED);
      case 'assignment': return const Color(0xFF2563EB);
      case 'exam': return const Color(0xFFDC2626);
      case 'project': return const Color(0xFF059669);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg = _overallAverage;
    final isPassing = avg >= 75;

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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.school, color: Colors.white, size: 28),
                      SizedBox(height: 2),
                      Text(
                        'STUDFY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'My Grades',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                        // Back navigation row
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                  border: Border.all(color: Colors.grey.shade200, width: 1),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Color(0xFF0A5C36),
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'My Grades',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A5C36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Subject title if specific subject
                        if (widget.subject != null) ...[
                          Text(widget.subject!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
                          Text('${widget.subject!.courseCode} ${widget.subject!.yearLevel}-${widget.subject!.section}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 16),
                        ],

                        // Final Grade banner
                        if (_grades.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPassing
                                    ? [const Color(0xFF0A5C36), const Color(0xFF13A05F)]
                                    : [const Color(0xFFB91C1C), const Color(0xFFDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('FINAL GRADE',
                                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text('${avg.toStringAsFixed(1)}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(_letterGrade(avg),
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(isPassing ? 'PASSED' : 'FAILED',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Summary card
                        if (_grades.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem('Average', '${avg.toStringAsFixed(1)}%', isPassing ? Colors.green : Colors.red),
                                _buildSummaryItem('Items', '${_grades.length}', const Color(0xFF0A5C36)),
                                _buildSummaryItem('Status', isPassing ? 'Passing' : 'Failing', isPassing ? Colors.green : Colors.red),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Grade items
                        if (_grades.isEmpty)
                          _buildEmptyState()
                        else ...[
                          ..._grades
                              .skip(_currentPage * _pageSize)
                              .take(_pageSize)
                              .map((g) => _buildGradeCard(g)),
                          const SizedBox(height: 16),
                          _buildPagination(
                            totalItems: _grades.length,
                            pageCount: (_grades.length / _pageSize).ceil(),
                            currentPage: _currentPage,
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          const StudentFloatingNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> g) {
    final score = (g['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (g['maxScore'] as num?)?.toDouble() ?? 100;
    final pct = maxScore > 0 ? (score / maxScore) * 100 : 0.0;
    final category = g['category']?.toString() ?? 'general';
    final isPassing = pct >= 75;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _categoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category == 'quiz' ? Icons.edit_rounded
                  : category == 'assignment' ? Icons.assignment_rounded
                  : category == 'exam' ? Icons.school_rounded
                  : category == 'project' ? Icons.folder_rounded
                  : Icons.star_rounded,
              color: _categoryColor(category),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _categoryColor(category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(category.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _categoryColor(category))),
                    ),
                    if (g['subjectName'] != null && (g['subjectName'] as String).isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(g['subjectName'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1)}/${maxScore.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPassing ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPassing ? Colors.green.shade700 : Colors.red.shade700)),
              ),
            ],
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
          Icon(Icons.grade_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No grades recorded yet.', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPagination({required int totalItems, required int pageCount, required int currentPage}) {
    if (totalItems == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${currentPage + 1} of $pageCount',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () => setState(() => _currentPage = currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 0 ? const Color(0xFFF5F6F9) : Colors.transparent,
                  foregroundColor: currentPage > 0 ? Colors.black87 : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentPage < pageCount - 1
                    ? () => setState(() => _currentPage = currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < pageCount - 1 ? const Color(0xFFF5F6F9) : Colors.transparent,
                  foregroundColor: currentPage < pageCount - 1 ? Colors.black87 : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
