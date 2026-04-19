import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../domain/models/instructor.dart';

class AdminInstructorScreen extends StatefulWidget {
  const AdminInstructorScreen({super.key});

  @override
  State<AdminInstructorScreen> createState() => _AdminInstructorScreenState();
}

class _AdminInstructorScreenState extends State<AdminInstructorScreen> {
  int? _hoveredIndex;

  // Controllers & State for Filtering
  final TextEditingController _profNameController = TextEditingController();
  String? _selectedCourse;
  String? _selectedSubject;

  final List<Instructor> _allInstructors = const [
    Instructor(name: 'Juan Dela Cruz', course: 'BSIT', subject: 'Programming'),
    Instructor(name: 'Pedro', course: 'BSIE', subject: 'Mathematics'),
    Instructor(name: 'Jose', course: 'DIT', subject: 'Communication'),
    Instructor(name: 'Maria Santos', course: 'BSCS', subject: 'Data Structures'),
    Instructor(name: 'Ricardo Dalisay', course: 'BSIT', subject: 'Networking'),
  ];

  final List<String> _courseList = ['BSIT', 'BSIE', 'DIT', 'BSCS', 'BSHM'];
  final List<String> _subjectList = ['Programming', 'Mathematics', 'Communication', 'Data Structures', 'Networking'];

  late List<Instructor> _filteredInstructors;

  @override
  void initState() {
    super.initState();
    _filteredInstructors = List.from(_allInstructors);
  }

  @override
  void dispose() {
    _profNameController.dispose();
    super.dispose();
  }

  // --- CORE FILTER LOGIC ---
  void _filterList() {
    setState(() {
      _filteredInstructors = _allInstructors.where((instructor) {
        final nameMatch = instructor.name
            .toLowerCase()
            .contains(_profNameController.text.toLowerCase());
        
        final courseMatch = _selectedCourse == null || 
            _selectedCourse!.isEmpty || 
            instructor.course == _selectedCourse;
        
        final subjectMatch = _selectedSubject == null || 
            _selectedSubject!.isEmpty || 
            instructor.subject == _selectedSubject;

        return nameMatch && courseMatch && subjectMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    _profNameController.clear();
    setState(() {
      _selectedCourse = null;
      _selectedSubject = null;
      _filteredInstructors = List.from(_allInstructors);
    });
  }

  void _navigateToInstructorProfile(String name, String? request) {
    final instructor = _allInstructors.firstWhere(
      (i) => i.name == name,
      orElse: () => _allInstructors.first,
    );

    context.pushNamed(
      AppRoutes.adminInstructorProfile,
      extra: {
        'instructor': instructor,
        'request': request,
      },
    );
  }

  void _showActionDialog(String action, String name, String request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action Request?'),
        content: Text('Are you sure you want to $action the "$request" from $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request $action-ed successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'Approve' ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      _buildSectionLabel('Pending Requests'),
                      _buildRequestsArea(),
                      const SizedBox(height: 12),
                      _buildSectionLabel('Instructor List'),
                      _buildSearchFilterArea(),
                      const SizedBox(height: 16),
                      _buildInstructorTableArea(),
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

  // --- UI COMPONENTS ---

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
    );
  }

  Widget _buildRequestsArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildPendingCard('Pedro', 'Account Edit Request'),
          _buildPendingCard('Juan Dela Cruz', 'Class Creation Request'),
        ],
      ),
    );
  }

  Widget _buildPendingCard(String name, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionBtn('Approve', Icons.check, const Color(0xFFD4EDDA), const Color(0xFF28A745), () => _showActionDialog('Approve', name, subtitle))),
              const SizedBox(width: 8),
              Expanded(child: _buildActionBtn('Reject', Icons.close, const Color(0xFFF8D7DA), const Color(0xFFDC3545), () => _showActionDialog('Reject', name, subtitle))),
              const SizedBox(width: 8),
              Expanded(child: _buildViewDetailsBtn(() => _navigateToInstructorProfile(name, subtitle))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _profNameController,
                  onChanged: (_) => _filterList(),
                  decoration: InputDecoration(
                    hintText: 'Professor Name',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              Expanded(child: _buildGlobalDropdown('Course', _courseList, _selectedCourse, (val) => setState(() => _selectedCourse = val))),
              const SizedBox(width: 10),
              Expanded(child: _buildGlobalDropdown('Subject', _subjectList, _selectedSubject, (val) => setState(() => _selectedSubject = val))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorTableArea() {
    return Column(
      children: _filteredInstructors.map((instructor) {
        List<String> specificCourses = (instructor.name == 'Juan Dela Cruz') ? ['BSIT', 'BSIE'] : [instructor.course];
        List<String> specificSubjects = (instructor.name == 'Juan Dela Cruz') ? ['Mathematics', 'Networking', 'Communication'] : [instructor.subject];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToInstructorProfile(instructor.name, null),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(instructor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.adminPrimary))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _buildTableDropdown(instructor.course, specificCourses)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildTableDropdown(instructor.subject, specificSubjects)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- REUSABLE HELPERS ---

  Widget _buildActionBtn(String label, IconData icon, Color bg, Color text, VoidCallback onTap) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(height: 38, alignment: Alignment.center, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 14, color: text), const SizedBox(width: 4), Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold))])),
      ),
    );
  }

  Widget _buildViewDetailsBtn(VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(height: 38, alignment: Alignment.center, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('View Details', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)), SizedBox(width: 2), Icon(Icons.chevron_right, size: 16, color: Colors.grey)])),
      ),
    );
  }

  Widget _buildGlobalDropdown(String hint, List<String> items, String? currentValue, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          value: currentValue,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {
            onChanged(val);
            _filterList();
          },
        ),
      ),
    );
  }

  Widget _buildTableDropdown(String value, List<String> items) {
    String currentValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(6)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          onChanged: (val) {},
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
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
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: const [Icon(Icons.search, color: Colors.white, size: 18), SizedBox(width: 4), Text('Search', style: TextStyle(color: Colors.white))])),
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
        child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.filter_alt_off, color: Colors.black54)),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(20)),
      child: const Text('● Pending', style: TextStyle(color: Color(0xFFB8860B), fontSize: 11, fontWeight: FontWeight.bold)),
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
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.school, color: Colors.white, size: 28), Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
          Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
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
            // Already on students
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