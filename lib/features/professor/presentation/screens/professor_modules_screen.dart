import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../widgets/professor_floating_nav_bar.dart';
import 'professor_subject_screen.dart';

class ProfessorModulesScreen extends StatefulWidget {
  const ProfessorModulesScreen({super.key});

  @override
  State<ProfessorModulesScreen> createState() => _ProfessorModulesScreenState();
}

class _ProfessorModulesScreenState extends State<ProfessorModulesScreen> {
  final _repo = const ProfessorRepository();
  bool _loading = true;
  List<ProfessorSubject> _dbSubjects = [];
  List<ProfessorSubject> _filteredSubjects = [];

  // Filter values
  String? _selectedSubject;
  String? _selectedCourseSection;

  // Mock list for fallback (matching the screenshot exactly: multiple Ethics BSIT 3-1 cards)
  static final List<ProfessorSubject> _fallbackSubjects = List.generate(
    15,
    (index) => ProfessorSubject(
      id: 'mock_ethics_$index',
      name: 'Ethics',
      courseCode: 'BSIT',
      section: '1',
      yearLevel: 3,
      studentCount: 60,
    ),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final subjects = await _repo.fetchMySubjects();
      if (mounted) {
        setState(() {
          _dbSubjects = subjects;
          _loading = false;
          _applyFilters();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _applyFilters();
        });
      }
    }
  }

  List<ProfessorSubject> get _allSubjects {
    return _dbSubjects.isNotEmpty ? _dbSubjects : _fallbackSubjects;
  }

  void _applyFilters() {
    setState(() {
      _filteredSubjects = _allSubjects.where((sub) {
        // Filter by Subject Name
        if (_selectedSubject != null &&
            !sub.name.toLowerCase().contains(_selectedSubject!.toLowerCase())) {
          return false;
        }
        // Filter by Course & Section
        if (_selectedCourseSection != null) {
          final filterStr = _selectedCourseSection!.toLowerCase();
          final classCode = '${sub.courseCode} ${sub.yearLevel}-${sub.section}'.toLowerCase();
          if (!classCode.contains(filterStr)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedSubject = null;
      _selectedCourseSection = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;

    // Get unique subject names for filter
    final subjectNames = _allSubjects.map((s) => s.name).toSet().toList();
    // Get unique course codes for filter
    final courseSections = _allSubjects
        .map((s) => '${s.courseCode} ${s.yearLevel}-${s.section}')
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: AppColors.authPrimary,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text(
                    user?.displayName ?? 'Archie Arevalo',
                    style: const TextStyle(
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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Title
                      const Text(
                        'Learning Modules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.authPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Select a class label
                      const Text(
                        'Select a Class',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.authPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown<String>(
                              label: 'Subject Name',
                              value: _selectedSubject,
                              items: subjectNames,
                              onChanged: (v) => setState(() {
                                _selectedSubject = v;
                                _applyFilters();
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterDropdown<String>(
                              label: 'Course & Section',
                              value: _selectedCourseSection,
                              items: courseSections,
                              onChanged: (v) => setState(() {
                                _selectedCourseSection = v;
                                _applyFilters();
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _applyFilters,
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text('Search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.authPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          if (_selectedSubject != null || _selectedCourseSection != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.grey),
                              onPressed: _resetFilters,
                              tooltip: 'Clear Filters',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // All Classes label
                      const Text(
                        'All Classes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3-Column Grid Layout
                      if (_filteredSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No classes match the filter criteria.',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width > 800 ? 4 : (width > 500 ? 3 : 2);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredSubjects.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.25,
                              ),
                              itemBuilder: (context, index) {
                                final sub = _filteredSubjects[index];
                                return _buildModuleClassCard(sub);
                              },
                            );
                          },
                        ),
                    ],
                  ),
          ),
          const ProfessorFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    String displayText = 'All ${label}s';
    if (label.toLowerCase() == 'classname') {
      displayText = 'Class Name';
    } else if (label.toLowerCase() == 'course & section') {
      displayText = 'Course & Section';
    } else if (label.toLowerCase() == 'subject name') {
      displayText = 'Subject Names';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayText,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(displayText, style: const TextStyle(color: Colors.black54)),
            ),
            ...items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildModuleClassCard(ProfessorSubject sub) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.lightBlue.shade100, width: 1),
      ),
      color: const Color(0xFF90CAF9).withOpacity(0.7), // Light blue shade card matching 2nd image
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to ProfessorSubjectScreen with Modules tab active (index 0)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessorSubjectScreen(subject: sub, initialIndex: 0),
            ),
          ).then((_) => _load());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                sub.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF0D47A1),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${sub.courseCode} ${sub.yearLevel}-${sub.section}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
