import 'package:flutter/material.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentQuizScreen extends StatefulWidget {
  final StudentSubject subject;
  final SubjectQuiz quiz;

  // Legacy constructor support: if called with assignment, convert
  final SubjectAssignment? assignment;

  const StudentQuizScreen({
    super.key,
    required this.subject,
    SubjectQuiz? quiz,
    this.assignment,
  }) : quiz = quiz ?? const SubjectQuiz(id: '', title: '', questions: []);

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  final StudentRepository _repo = const StudentRepository();

  bool _loading = true;
  bool _alreadyAnswered = false;
  Map<String, dynamic>? _previousAnswer;

  late SubjectQuiz _quiz;
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  int _score = 0;
  bool _showResult = false;
  bool _isReviewing = false;
  bool _submitting = false;

  // Answers tracked per question index
  List<int?> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _loading = true);
    try {
      // Resolve quiz metadata (title/deadline). Questions are NOT taken from the
      // passed object anymore — they're loaded via secure RPCs.
      final quizId = widget.quiz.id.isNotEmpty ? widget.quiz.id : (widget.assignment?.id ?? '');
      SubjectQuiz meta = widget.quiz;
      if (meta.id.isEmpty || meta.title.isEmpty) {
        final quizzes = await _repo.fetchQuizzes(widget.subject.id);
        final match = quizzes.where((q) => q.id == quizId).toList();
        if (match.isNotEmpty) {
          meta = match.first;
        } else if (quizzes.isNotEmpty) {
          meta = quizzes.first;
        }
      }

      final resolvedId = meta.id.isNotEmpty ? meta.id : quizId;

      // Has the student already submitted?
      _previousAnswer = resolvedId.isNotEmpty ? await _repo.fetchQuizAnswer(resolvedId) : null;
      _alreadyAnswered = _previousAnswer != null;

      // Load questions: review version (with correct answers) if already
      // submitted, otherwise the taking version (no correct answers).
      List<QuizQuestion> questions;
      if (_alreadyAnswered) {
        questions = await _repo.fetchQuizReview(resolvedId);
        _score = (_previousAnswer!['score'] as num?)?.toInt() ?? 0;
      } else {
        questions = await _repo.fetchQuizQuestionsForTaking(resolvedId);
      }

      _quiz = SubjectQuiz(
        id: resolvedId,
        title: meta.title.isNotEmpty ? meta.title : 'Quiz',
        description: meta.description,
        deadline: meta.deadline,
        moduleId: meta.moduleId,
        questions: questions,
      );

      _userAnswers = List.filled(_quiz.questions.length, null);

      // Reconstruct previous answers for review
      if (_alreadyAnswered) {
        final prevAnswers = _previousAnswer!['answers'];
        if (prevAnswers is List) {
          for (int i = 0; i < _quiz.questions.length && i < prevAnswers.length; i++) {
            final ans = prevAnswers[i]?.toString() ?? '';
            final optIdx = _quiz.questions[i].options.indexOf(ans);
            _userAnswers[i] = optIdx >= 0 ? optIdx : null;
          }
        }
      }
    } catch (_) {
      _quiz = const SubjectQuiz(id: '', title: 'Error loading quiz', questions: []);
      _userAnswers = [];
    }
    if (mounted) setState(() => _loading = false);
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
                  Flexible(
                    child: Text(
                      widget.subject.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _quiz.questions.isEmpty
                    ? _buildEmptyState()
                    : _alreadyAnswered && !_showResult && !_isReviewing
                        ? _buildAlreadyAnsweredState()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _showResult
                                ? (_isReviewing
                                    ? _buildReviewScreen(key: const ValueKey('review'))
                                    : _buildResultScreen(key: const ValueKey('result')))
                                : _buildQuizContent(key: const ValueKey('quiz')),
                          ),
          ),
          const StudentFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No questions available for this quiz.',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5C36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyAnsweredState() {
    final maxScore = (_previousAnswer?['max_score'] as num?)?.toInt() ?? _quiz.questions.length;
    final percentage = maxScore > 0 ? (_score / maxScore * 100) : 0.0;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36).withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A5C36).withOpacity(0.12), width: 4),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$_score', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0A5C36))),
                  Text('of $maxScore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quiz Already Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
            const SizedBox(height: 8),
            Text('You scored ${percentage.toStringAsFixed(0)}% on this quiz.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C36),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _showResult = true;
                    _isReviewing = true;
                  });
                },
                label: const Text('Review My Answers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent({Key? key}) {
    final int totalQuestions = _quiz.questions.length;
    final int questionNum = _currentQuestionIndex + 1;
    final question = _quiz.questions[_currentQuestionIndex];

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Text(
          _quiz.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: Text('$questionNum/$totalQuestions',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
        ),
        const SizedBox(height: 10),
        Text(
          question.question,
          style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 30),
        ...question.options.asMap().entries.map((entry) {
          final int index = entry.key;
          final String optionText = entry.value;
          final bool isSelected = _selectedOptionIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0A5C36).withOpacity(0.1) : Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFF0A5C36) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () => setState(() => _selectedOptionIndex = index),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(optionText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF0A5C36) : Colors.black87,
                    )),
              ),
            ),
          );
        }),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentQuestionIndex > 0)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                    _selectedOptionIndex = _userAnswers[_currentQuestionIndex];
                  });
                },
                child: const Text('Back'),
              )
            else
              const SizedBox.shrink(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C36),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF0A5C36).withOpacity(0.4),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _selectedOptionIndex != null ? _handleNext : null,
              child: Text(
                _submitting
                    ? 'Submitting...'
                    : (_currentQuestionIndex == totalQuestions - 1 ? 'Submit' : 'Next'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleNext() async {
    final totalQuestions = _quiz.questions.length;
    _userAnswers[_currentQuestionIndex] = _selectedOptionIndex;

    if (_currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = _userAnswers[_currentQuestionIndex];
      });
    } else {
      // Submit quiz — scored SERVER-SIDE; correct answers never sent here.
      setState(() => _submitting = true);
      final answers = <String>[];
      for (int i = 0; i < _quiz.questions.length; i++) {
        final q = _quiz.questions[i];
        final userIdx = _userAnswers[i];
        answers.add(userIdx != null && userIdx < q.options.length ? q.options[userIdx] : '');
      }
      try {
        final result = await _repo.submitQuizAnswers(
          quizId: _quiz.id,
          answers: answers,
        );
        _score = result['score'] as int;

        // Now that we've submitted, load the review version (with correct
        // answers) so the review screen can highlight right/wrong.
        try {
          final reviewQs = await _repo.fetchQuizReview(_quiz.id);
          if (reviewQs.isNotEmpty) {
            _quiz = SubjectQuiz(
              id: _quiz.id,
              title: _quiz.title,
              description: _quiz.description,
              deadline: _quiz.deadline,
              moduleId: _quiz.moduleId,
              questions: reviewQs,
            );
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _submitting = false;
            _showResult = true;
            _alreadyAnswered = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade700,
              content: Text('Could not save your answers: ${e.toString().replaceAll('Exception: ', '')}. Please try again.'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Widget _buildResultScreen({Key? key}) {
    final totalQuestions = _quiz.questions.length;
    final double percentage = totalQuestions > 0 ? (_score / totalQuestions) * 100 : 0;
    return Container(
      key: key,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
              border: Border.all(color: Colors.grey.shade100),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A5C36).withOpacity(0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0A5C36).withOpacity(0.12), width: 4),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_score', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF0A5C36))),
                      Text('of $totalQuestions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _score >= totalQuestions * 0.8 ? 'Outstanding!' : _score >= totalQuestions * 0.5 ? 'Good Job!' : 'Nice Try!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
                ),
                const SizedBox(height: 8),
                Text('You scored ${percentage.toInt()}% correct answers.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A5C36),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _isReviewing = true),
                    label: const Text('Review Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Modules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewScreen({Key? key}) {
    final totalQuestions = _quiz.questions.length;
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Quiz Review', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Score: $_score/$totalQuestions',
                  style: const TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...List.generate(totalQuestions, (qIndex) {
          final question = _quiz.questions[qIndex];
          final int? userAns = _userAnswers[qIndex];
          final String userAnswerText = (userAns != null && userAns < question.options.length)
              ? question.options[userAns]
              : '';
          final bool isCorrect = userAnswerText == question.correctAnswer;
          final int correctIdx = question.options.indexOf(question.correctAnswer);

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${qIndex + 1} of $totalQuestions',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: isCorrect ? Colors.green : Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(isCorrect ? 'Correct' : 'Incorrect',
                              style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(question.question,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.4)),
                const SizedBox(height: 16),
                ...question.options.asMap().entries.map((optionEntry) {
                  final int optIndex = optionEntry.key;
                  final String optText = optionEntry.value;

                  Color cardBgColor = Colors.white;
                  Color borderColor = const Color(0xFFE0E0E0);
                  Color textColor = Colors.black87;
                  Widget? statusIcon;

                  if (optIndex == correctIdx) {
                    cardBgColor = const Color(0xFFE2F0D9);
                    borderColor = const Color(0xFF0A5C36);
                    textColor = const Color(0xFF0A5C36);
                    statusIcon = const Icon(Icons.check_circle, color: Color(0xFF0A5C36), size: 18);
                  } else if (userAns == optIndex) {
                    cardBgColor = const Color(0xFFFCE4D6);
                    borderColor = Colors.redAccent;
                    textColor = Colors.red;
                    statusIcon = const Icon(Icons.cancel, color: Colors.red, size: 18);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      border: Border.all(color: borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(optText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor))),
                        if (statusIcon != null) statusIcon,
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5C36),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _isReviewing = false),
            child: const Text('Back to Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
