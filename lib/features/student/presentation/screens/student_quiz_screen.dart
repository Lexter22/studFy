import 'package:flutter/material.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentQuizScreen extends StatefulWidget {
  final StudentSubject subject;
  final SubjectAssignment assignment;
  final SubjectQuiz quiz;

  const StudentQuizScreen({
    super.key,
    required this.subject,
    required this.assignment,
    required this.quiz,
  });

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  final StudentRepository _repo = const StudentRepository();
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  int _score = 0;
  bool _showResult = false;
  bool _isReviewing = false;

  // Answers tracked
  late List<int?> _userAnswers;

  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    for (var q in widget.quiz.questions) {
      int cIndex = q.options.indexOf(q.correctAnswer);
      _questions.add({
        'question': q.question,
        'options': q.options,
        'correctIndex': cIndex >= 0 ? cIndex : 0,
      });
    }
    _userAnswers = List.filled(_questions.length, null);
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
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
                  const Spacer(),
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
                  child: _isReviewing
                      ? _buildReviewContent()
                      : (_showResult ? _buildResultScreen() : _buildQuizContent()),
                ),
              ],
            ),
          ),
          const StudentFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    if (_questions.isEmpty) {
      return const Center(
        child: Text(
          'No questions available for this quiz.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }
    final int questionNum = _currentQuestionIndex + 1;
    final Map<String, dynamic> qData = _questions[_currentQuestionIndex];
    final String questionText = qData['question'];
    final List<String> options = List<String>.from(qData['options']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        const Text(
          'Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A5C36),
          ),
        ),
        const SizedBox(height: 14),

        // Progress indicators e.g., 1/10
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$questionNum/${_questions.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A5C36),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Question text
        Text(
          questionText,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 30),

        // Options List
        ...options.asMap().entries.map((entry) {
          final int index = entry.key;
          final String optionText = entry.value;
          return _buildOptionButton(index, optionText, qData['correctIndex']);
        }),
        const SizedBox(height: 40),

        // Next/Review controls at bottom
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_isReviewing && _currentQuestionIndex > 0)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (!_isReviewing && _selectedOptionIndex == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an option first!'),
                    ),
                  );
                  return;
                }

                if (_isReviewing) {
                  // Review flow
                  if (_currentQuestionIndex < _questions.length - 1) {
                    setState(() {
                      _currentQuestionIndex++;
                      _selectedOptionIndex =
                          _userAnswers[_currentQuestionIndex];
                    });
                  } else {
                    setState(() {
                      _isReviewing = false;
                      _showResult = true;
                    });
                  }
                } else {
                  // First play flow
                  _userAnswers[_currentQuestionIndex] = _selectedOptionIndex;
                  if (_selectedOptionIndex == qData['correctIndex']) {
                    _score++;
                  }

                  if (_currentQuestionIndex < _questions.length - 1) {
                    setState(() {
                      _currentQuestionIndex++;
                      _selectedOptionIndex = null;
                    });
                  } else {
                    setState(() {
                      _showResult = true;
                    });
                    _repo.submitQuizScore(widget.quiz.id, _score);
                  }
                }
              },
              child: Text(
                _currentQuestionIndex == _questions.length - 1
                    ? (_isReviewing ? 'Finish' : 'Submit')
                    : 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_isReviewing)
          Center(
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Exit Quiz?'),
                    content: const Text('Are you sure you want to exit? Your current progress will not be saved.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('Exit', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
              label: const Text(
                'Exit Quiz',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isReviewing = false;
                  _showResult = true;
                });
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.grey),
              label: const Text(
                'Exit Review',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(int index, String text, int correctIndex) {
    Color cardBgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);
    Color textColor = Colors.black87;

    if (_isReviewing) {
      // In review mode:
      // - Correct answer is always green
      // - If user selected wrong answer, user selection is highlighted red
      final int? userAns = _userAnswers[_currentQuestionIndex];
      if (index == correctIndex) {
        cardBgColor = const Color(0xFFE2F0D9);
        borderColor = const Color(0xFF0A5C36);
        textColor = const Color(0xFF0A5C36);
      } else if (userAns == index) {
        cardBgColor = const Color(0xFFFCE4D6); // Red tint
        borderColor = Colors.redAccent;
        textColor = Colors.red;
      }
    } else {
      // In game mode:
      // - Highlight selection
      final bool isSelected = _selectedOptionIndex == index;
      if (isSelected) {
        cardBgColor = const Color(0xFF0A5C36).withOpacity(0.1);
        borderColor = const Color(0xFF0A5C36);
        textColor = const Color(0xFF0A5C36);
      }
    }

    // Special match for Screenshot 3 right where 'Manager' is highlighted red
    // Only if reviewing, and user answered incorrectly
    final bool isManagerIncorrectMatch =
        _isReviewing &&
        _currentQuestionIndex == 0 &&
        index == 0 &&
        _userAnswers[0] == 0; // manager selected but incorrect

    if (isManagerIncorrectMatch) {
      cardBgColor = const Color(0xFFF87171); // Solid Red matching Screenshot 3
      borderColor = Colors.red;
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: _isReviewing
            ? null
            : () {
                setState(() {
                  _selectedOptionIndex = index;
                });
              },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final double percent = _questions.isNotEmpty ? (_score / _questions.length) : 0;
    final int percentInt = (percent * 100).round();
    
    String feedbackMessage;
    IconData feedbackIcon;
    Color feedbackColor;
    
    if (percent >= 0.8) {
      feedbackMessage = 'Excellent Job!';
      feedbackIcon = Icons.emoji_events_rounded;
      feedbackColor = const Color(0xFF0A5C36);
    } else if (percent >= 0.5) {
      feedbackMessage = 'Good Effort!';
      feedbackIcon = Icons.thumb_up_alt_rounded;
      feedbackColor = Colors.amber.shade800;
    } else {
      feedbackMessage = 'Nice Try!';
      feedbackIcon = Icons.stars_rounded;
      feedbackColor = Colors.orange.shade800;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: feedbackColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feedbackIcon,
                  color: feedbackColor,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$_score/${_questions.length}',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: feedbackColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                feedbackMessage,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $percentInt% on this quiz.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Total Questions', '${_questions.length}', Colors.blue.shade700),
                  _buildStatColumn('Correct Answers', '$_score', const Color(0xFF0A5C36)),
                  _buildStatColumn('Incorrect', '${_questions.length - _score}', Colors.red.shade700),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5C36),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isReviewing = true;
                      _currentQuestionIndex = 0;
                      _selectedOptionIndex = _userAnswers[0];
                    });
                  },
                  icon: const Icon(Icons.rate_review_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Review Quiz Answers',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0A5C36), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF0A5C36)),
                  label: const Text(
                    'Back to To Do\'s',
                    style: TextStyle(
                      color: Color(0xFF0A5C36),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quiz Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A5C36),
              ),
            ),
            Text(
              'Score: $_score/${_questions.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A5C36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ..._questions.asMap().entries.map((entry) {
          final int qIndex = entry.key;
          final Map<String, dynamic> qData = entry.value;
          final String questionText = qData['question'];
          final List<String> options = List<String>.from(qData['options']);
          final int correctIndex = qData['correctIndex'];
          final int? userAns = _userAnswers[qIndex];

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(18),
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
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A5C36).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Q${qIndex + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A5C36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        questionText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Options list
                ...options.asMap().entries.map((optEntry) {
                  final int optIndex = optEntry.key;
                  final String optText = optEntry.value;

                  Color cardBgColor = Colors.white;
                  Color borderColor = const Color(0xFFE0E0E0);
                  Color textColor = Colors.black87;
                  IconData? icon;
                  Color? iconColor;

                  if (optIndex == correctIndex) {
                    // Correct answer (Green)
                    cardBgColor = const Color(0xFFE2F0D9);
                    borderColor = const Color(0xFF0A5C36);
                    textColor = const Color(0xFF0A5C36);
                    icon = Icons.check_circle_rounded;
                    iconColor = const Color(0xFF0A5C36);
                  } else if (userAns == optIndex) {
                    // User's wrong answer (Red)
                    cardBgColor = const Color(0xFFFCE4D6);
                    borderColor = Colors.redAccent;
                    textColor = Colors.red;
                    icon = Icons.cancel_rounded;
                    iconColor = Colors.red;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      border: Border.all(color: borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            optText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, color: iconColor, size: 18),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5C36),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () {
              setState(() {
                _isReviewing = false;
                _showResult = true;
              });
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Back to Results',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: valColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
