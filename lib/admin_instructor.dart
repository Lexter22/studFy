import 'package:flutter/material.dart';
import '../main.dart'; 
import 'admin_instructor_profile.dart'; 

class AdminInstructorScreen extends StatefulWidget {
  const AdminInstructorScreen({super.key});

  @override
  State<AdminInstructorScreen> createState() => _AdminInstructorScreenState();
}

class _AdminInstructorScreenState extends State<AdminInstructorScreen> {
  int _selectedNavIndex = 0;
  int? _hoveredNavIndex;

  final TextEditingController _profNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final List<Map<String, String>> _allInstructors = [
    {'name': 'Juan Dela Cruz', 'course': 'BSIT', 'subject': 'Computer Programming'},
    {'name': 'Pedro', 'course': 'BSIE', 'subject': 'Mathematics'},
    {'name': 'Jose', 'course': 'DIT', 'subject': 'Communication'},
    {'name': 'Maria Santos', 'course': 'BSCS', 'subject': 'Data Structures'},
    {'name': 'Ricardo Dalisay', 'course': 'BSIT', 'subject': 'Networking'},
  ];

  List<Map<String, String>> _filteredInstructors = [];

  final List<String> _courseList = ['BSIT', 'BSIE', 'DIT', 'BSCS', 'BSHM'];
  final List<String> _subjectList = ['Computer Programming', 'Mathematics', 'Communication', 'Ethics', 'Networking'];

  final Color adminMaroon = const Color(0xFF7A1313);
  final Color adminMaroonHover = const Color(0xFFA52A2A);
  final Color pageBackground = const Color(0xFFF5F5F5);
  final Color itemBackground = const Color(0xFFD9D9D9);

  @override
  void initState() {
    super.initState();
    _filteredInstructors = _allInstructors;
  }

  void _filterList() {
    setState(() {
      _filteredInstructors = _allInstructors.where((instructor) {
        final nameMatch = instructor['name']!.toLowerCase().contains(_profNameController.text.toLowerCase());
        final courseMatch = instructor['course']!.toLowerCase().contains(_courseController.text.toLowerCase());
        final subjectMatch = instructor['subject']!.toLowerCase().contains(_subjectController.text.toLowerCase());
        return nameMatch && courseMatch && subjectMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _profNameController.clear();
      _courseController.clear();
      _subjectController.clear();
      _filteredInstructors = _allInstructors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Pending Requests'),
                  // FIXED: Wrapped in Expanded or increased height to prevent overflow
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160), 
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildRequestItem('Juan Dela Cruz', 'Class Creation'),
                          _buildRequestItem('Pedro', 'Removal of Student'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Instructor List'),
                  _buildSearchArea(), 
                  const SizedBox(height: 12),
                  _buildInstructorListArea(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      width: double.infinity,
      color: adminMaroon,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.school, color: Colors.white, size: 28),
              Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: itemBackground, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: TextField(
                    controller: _profNameController,
                    onChanged: (value) => _filterList(),
                    decoration: const InputDecoration(
                      hintText: 'Professor Name',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off, color: Colors.black54),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildComboField('Course', _courseController, _courseList)),
              const SizedBox(width: 8),
              Expanded(child: _buildComboField('Subject', _subjectController, _subjectList)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComboField(String hint, TextEditingController controller, List<String> items) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (value) => _filterList(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onSelected: (String value) { controller.text = value; _filterList(); },
            itemBuilder: (context) => items.map((choice) => PopupMenuItem(value: choice, child: Text(choice))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorListArea() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _filteredInstructors.length,
          itemBuilder: (context, index) {
            return InstructorListItem(
              instructor: _filteredInstructors[index],
              itemBackground: itemBackground,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: adminMaroon)),
    );
  }

  Widget _buildRequestItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: itemBackground, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.account_circle_outlined, size: 40, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ])),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 70,
      width: double.infinity,
      color: adminMaroon,
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
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredNavIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNavIndex = index),
      onExit: (_) => setState(() => _hoveredNavIndex = null),
      child: GestureDetector(
        onTap: () {
          if (index == 4) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
          else if (index == 2) Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovered ? adminMaroonHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructorListItem extends StatefulWidget {
  final Map<String, String> instructor;
  final Color itemBackground;

  const InstructorListItem({
    super.key,
    required this.instructor,
    required this.itemBackground,
  });

  @override
  State<InstructorListItem> createState() => _InstructorListItemState();
}

class _InstructorListItemState extends State<InstructorListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminInstructorProfileScreen(instructor: widget.instructor),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white : widget.itemBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered 
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(widget.instructor['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(widget.instructor['course']!, style: const TextStyle(fontSize: 13, color: Colors.black54))),
              Expanded(flex: 3, child: Text(widget.instructor['subject']!, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}