import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';

class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  int? _hoveredIndex;
  int? _hoveredSubjectIndex;

  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _professorController = TextEditingController();

  // Subject list (bottom section)
  final List<Map<String, String>> _allSubjects = [
    {'name': 'Computer Programming', 'course': 'BSIT', 'section': '3-1', 'professor': 'Juan Dela Cruz'},
    {'name': 'Data Structures',       'course': 'BSIT', 'section': '3-2', 'professor': 'Juan Dela Cruz'},
    {'name': 'Web Development',       'course': 'BSIT', 'section': '2-1', 'professor': 'Ricardo Dalisay'},
    {'name': 'Networking',            'course': 'BSIT', 'section': '2-2', 'professor': 'Ricardo Dalisay'},
    {'name': 'Database Management',   'course': 'BSCS', 'section': '3-1', 'professor': 'Maria Santos'},
    {'name': 'Algorithms',            'course': 'BSCS', 'section': '3-2', 'professor': 'Maria Santos'},
    {'name': 'Mathematics',           'course': 'BSIE', 'section': '1-1', 'professor': 'Pedro'},
    {'name': 'Calculus',              'course': 'BSIE', 'section': '1-2', 'professor': 'Pedro'},
    {'name': 'Communication',         'course': 'DIT',  'section': '2-1', 'professor': 'Jose'},
    {'name': 'Technical Writing',     'course': 'DIT',  'section': '2-2', 'professor': 'Jose'},
    {'name': 'Ethics',                'course': 'BSHM', 'section': '1-1', 'professor': 'Ana Reyes'},
  ];

  final List<String> _courseList = ['BSIT', 'BSIE', 'DIT', 'BSCS', 'BSHM'];
  final List<String> _professorList = [
    'Juan Dela Cruz',
    'Pedro',
    'Jose',
    'Maria Santos',
    'Ricardo Dalisay',
    'Ana Reyes',
  ];

  late List<Map<String, String>> _filteredSubjects;

  @override
  void initState() {
    super.initState();
    _filteredSubjects = _allSubjects;
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _courseController.dispose();
    _professorController.dispose();
    super.dispose();
  }

  void _filterList() {
    setState(() {
      _filteredSubjects = _allSubjects.where((subject) {
        final nameMatch = subject['name']!
            .toLowerCase()
            .contains(_subjectNameController.text.toLowerCase());
        final courseMatch = subject['course']!
            .toLowerCase()
            .contains(_courseController.text.toLowerCase());
        final professorMatch = subject['professor']!
            .toLowerCase()
            .contains(_professorController.text.toLowerCase());
        return nameMatch && courseMatch && professorMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    _subjectNameController.clear();
    _courseController.clear();
    _professorController.clear();
    setState(() {
      _filteredSubjects = _allSubjects;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.adminPageBackground,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Pending Requests', null),
                      
                      // DYNAMIC PENDING REQUESTS
                      ValueListenableBuilder<List<Map<String, String>>>(
                        valueListenable: context.read<AppState>().pendingSubjectRequestsNotifier,
                        builder: (context, pendingRequests, child) {
                          if (pendingRequests.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'No pending request',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 350),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: pendingRequests
                                    .map((s) => _buildSubjectItem(s['name']!, s['status']!))
                                    .toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildSectionTitle('Subject List', null),
                            Row(
                              children: [
                                const Text(
                                  'Total: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${_filteredSubjects.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.adminPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildSearchArea(),
                      const SizedBox(height: 16),
                      _buildSubjectListArea(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      width: double.infinity,
      color: AppColors.adminPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: Colors.white, size: 28),
              Text('STUDFY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          Text('Admin 1',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? trailingText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimary)),
          if (trailingText != null)
            Text(trailingText,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminPrimary)),
        ],
      ),
    );
  }

  Widget _buildSubjectItem(String name, String status) {
    return _PendingSubjectCard(name: name, status: status);
  }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _subjectNameController,
                    onChanged: (_) => _filterList(),
                    decoration: InputDecoration(
                      hintText: 'Subject Name',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 14),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSearchButton(),
              const SizedBox(width: 8),
              _buildClearFilterButton(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _buildComboField(
                      'Course', _courseController, _courseList)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildComboField(
                      'Professor', _professorController, _professorList)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Material(
      color: const Color(0xFF1A46A0),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _filterList,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(children: [
              Icon(Icons.search, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text('Search', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))
            ])),
      ),
    );
  }

  Widget _buildClearFilterButton() {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _clearFilters,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.filter_alt_off, color: Colors.black54)),
      ),
    );
  }

  Widget _buildComboField(
      String hint, TextEditingController controller, List<String> items) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => _filterList(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onSelected: (val) {
              controller.text = val;
              _filterList();
            },
            itemBuilder: (ctx) => items
                .map((choice) =>
                    PopupMenuItem(value: choice, child: Text(choice)))
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getCoursesForSubject(String subjectName) {
    return _allSubjects
        .where((s) => s['name'] == subjectName)
        .map((s) => '${s['course']!} ${s['section']!}')
        .toSet()
        .toList();
  }

  Widget _buildSubjectListArea() {
    if (_filteredSubjects.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text(
            'No subjects in the list',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_filteredSubjects.length, (index) {
        final subject = _filteredSubjects[index];
        final isHovered = _hoveredSubjectIndex == index;
        final courses = _getCoursesForSubject(subject['name']!);

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredSubjectIndex = index),
          onExit: (_) => setState(() => _hoveredSubjectIndex = null),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isHovered ? Colors.grey.shade100 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await context.pushNamed(
                    AppRoutes.adminSubjectsProfile,
                    extra: {
                      'subjectName': subject['name']!,
                      'courseSection': '${subject['course']!} ${subject['section']!}',
                      'professor': subject['professor']!,
                    },
                  );

                  if (result == true) {
                    setState(() {
                      // Remove from the master list
                      _allSubjects.removeWhere((s) => s['name'] == subject['name']);
                      _filterList();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          subject['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isHovered ? AppColors.adminPrimary : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildTableDropdown(
                          '${subject['course']!} ${subject['section']!}',
                          courses,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 32,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Text(
                            subject['professor']!,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTableDropdown(String value, List<String> items) {
    String currentValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 32,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(6)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          onChanged: (val) {},
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 800
                ? 650
                : MediaQuery.of(context).size.width - 20,
          ),
          child: Container(
            height: 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.layers, 'INSTRUCTOR', 0),
                _buildNavItem(Icons.group, 'STUDENTS', 1),
                _buildNavItem(Icons.home, 'DASHBOARD', 2),
                _buildNavItem(Icons.book, 'SUBJECTS', 3),
                _buildNavItem(Icons.logout, 'LOGOUT', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          if (index == 4) {
            context.read<AppState>().logout();
            context.goNamed(AppRoutes.login);
          } else if (index == 0) {
            context.goNamed(AppRoutes.adminInstructors);
          } else if (index == 1) {
            context.goNamed(AppRoutes.adminStudents);
          } else if (index == 2) {
            context.goNamed(AppRoutes.adminDashboard);
          } else if (index == 3) {
            context.goNamed(AppRoutes.adminSubjects);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingSubjectCard extends StatefulWidget {
  final String name;
  final String status;

  const _PendingSubjectCard({required this.name, required this.status});

  @override
  State<_PendingSubjectCard> createState() => _PendingSubjectCardState();
}

class _PendingSubjectCardState extends State<_PendingSubjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? Colors.black.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _isHovered ? 15 : 10,
              offset: _isHovered ? const Offset(0, 6) : const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark_outline,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(widget.status,
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildViewDetailsBtn(() {
                  context.pushNamed(
                    AppRoutes.adminSubjectsProfile,
                    extra: {
                      'subjectName': widget.name,
                      'courseSection': 'Pending',
                      'professor': 'Admin',
                      'pendingRequest': widget.status,
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF7DC6F)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFB8860B)),
          SizedBox(width: 6),
          Text('Pending',
              style: TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildViewDetailsBtn(VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Details',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey)
                ])),
      ),
    );
  }
}
