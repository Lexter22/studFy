import 'package:flutter/material.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  final StudentSubject subject;
  final SubjectAssignment assignment;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.subject,
    required this.assignment,
  });

  @override
  State<StudentAssignmentDetailScreen> createState() => _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState extends State<StudentAssignmentDetailScreen> {
  final StudentRepository _repo = const StudentRepository();
  bool _submitting = false;
  bool _submitted = false;
  String? _selectedFile;

  @override
  void initState() {
    super.initState();
    _checkPreviousSubmission();
  }

  Future<void> _checkPreviousSubmission() async {
    final hasSubmitted = await _repo.checkSubmission(widget.assignment.id);
    if (hasSubmitted && mounted) {
      setState(() {
        _submitted = true;
        _selectedFile = 'presentation.pptx';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a file first!')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.submitAssignment(
        widget.assignment.id,
        _selectedFile!,
        'https://supabase.com/mock/presentation.pptx',
      );
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    widget.subject.name.toUpperCase(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    children: [
                      // Assignment Title e.g., "Activity 1: PPT"
                      Text(
                        widget.assignment.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A5C36),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Container(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      const SizedBox(height: 16),

                      // Instructions text
                      Text(
                        widget.assignment.description ?? 'Make a power point presentation about dilemma',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // File upload card with "Add" and "Submit"
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (_selectedFile != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0A5C36), size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedFile!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                  if (!_submitted)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => setState(() => _selectedFile = null),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Add Button
                            if (!_submitted)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0A5C36), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = 'presentation.pptx';
                                    });
                                  },
                                  child: const Text(
                                    'Add File',
                                    style: TextStyle(
                                      color: Color(0xFF0A5C36),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            if (!_submitted) const SizedBox(height: 12),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _submitted ? Colors.grey : const Color(0xFF0A5C36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: _submitted || _submitting || _selectedFile == null
                                    ? null
                                    : _handleSubmit,
                                child: _submitting
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        _submitted ? 'Submitted' : 'Submit',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Green Success Banner popup matching Screenshot 5 exactly!
          if (_submitted && !_submitting)
            _buildSuccessOverlay(),

          const StudentFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }



  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black26, // Semi-transparent overlay
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A5C36), // Green color matching Screenshot 5
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Success!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your submission has been recorded.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0A5C36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
