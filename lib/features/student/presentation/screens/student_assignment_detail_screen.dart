import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';
import '../../../../core/widgets/app_dialog.dart';

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
  bool _justSubmitted = false;
  String? _selectedFile;
  Uint8List? _selectedFileBytes;

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
      String fileUrl = 'https://supabase.com/mock/presentation.pptx';
      if (_selectedFileBytes != null) {
        fileUrl = await _repo.uploadSubmissionFile(
          widget.assignment.id,
          _selectedFile!,
          _selectedFileBytes!,
        );
      }
      
      await _repo.submitAssignment(
        widget.assignment.id,
        _selectedFile!,
        fileUrl,
      );
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
          _justSubmitted = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    tooltip: 'Back to Modules',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.school, color: Colors.white, size: 24),
                      SizedBox(height: 2),
                      Text(
                        'STUDFY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      widget.subject.name.toUpperCase(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      // Assignment Header Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A5C36).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Assignment',
                                    style: TextStyle(
                                      color: Color(0xFF0A5C36),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _submitted ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _submitted ? 'Submitted' : 'Pending',
                                    style: TextStyle(
                                      color: _submitted ? Colors.green : Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.assignment.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A5C36),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  widget.assignment.deadline != null
                                      ? 'Due: ${_getMonthName(widget.assignment.deadline!.month)} ${widget.assignment.deadline!.day}'
                                      : 'Due: May 09, 2026',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Instructions Section
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A5C36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          widget.assignment.description ?? 'Make a power point presentation about dilemma',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submission / File upload zone
                      const Text(
                        'My Submission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A5C36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (_selectedFile != null) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0A5C36), size: 28),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFile!,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _submitted ? 'Uploaded & Locked' : 'Ready to submit',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_submitted)
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, color: Colors.red),
                                        onPressed: () => setState(() => _selectedFile = null),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else ...[
                              // Upload placeholder
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, color: const Color(0xFF0A5C36).withOpacity(0.5), size: 48),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No file selected',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Upload your assignment document or presentation.',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Add Button
                            if (!_submitted)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0A5C36),
                                    side: const BorderSide(color: Color(0xFF0A5C36), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    try {
                                      final result = await FilePicker.platform.pickFiles(withData: true);
                                      if (result == null || result.files.isEmpty) return;
                                      final file = result.files.first;
                                      if (file.bytes == null) return;
                                      setState(() {
                                        _selectedFile = file.name;
                                        _selectedFileBytes = file.bytes;
                                      });
                                    } catch (e) {
                                      if (context.mounted) {
                                        AppDialog.alert(context, title: 'Error', message: 'Failed to pick file: $e');
                                      }
                                    }
                                  },
                                  label: const Text(
                                    'Add File',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            if (!_submitted) const SizedBox(height: 12),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _submitted ? Colors.grey : const Color(0xFF0A5C36),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _submitted || _submitting || _selectedFile == null
                                    ? null
                                    : _handleSubmit,
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        _submitted ? 'Submitted Successfully' : 'Submit Assignment',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
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

          // Green Success Banner popup — only right after a fresh submit
          if (_justSubmitted && !_submitting)
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
                  onPressed: () => setState(() => _justSubmitted = false),
                  child: const Text(
                    'View My Submission',
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
