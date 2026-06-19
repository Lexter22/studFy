import 'package:flutter/material.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentQuizScreen extends StatefulWidget {
  final StudentSubject subject;
  final SubjectAssignment assignment;

  const StudentQuizScreen({
    super.key,
    required this.subject,
    required this.assignment,
  });

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  int _score = 0;
  bool _showResult = false;
  bool _isReviewing = false;

  // Answers tracked
  final List<int?> _userAnswers = List.filled(10, null);

  // Hardcoded premium quiz questions
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Managers who do not relate well to peers and other associates usually have a difficult time accomplishing their goals and moving up in the organization.',
      'options': ['Manager', 'Support', 'Communication', 'Impact'],
      'correctIndex': 0, // 'Manager'
    },
    {
      'question': 'Which ethical theory focuses on the consequences of actions, aiming for the greatest good for the greatest number?',
      'options': ['Deontology', 'Utilitarianism', 'Virtue Ethics', 'Egoism'],
      'correctIndex': 1,
    },
    {
      'question': 'A situation in which a professional has multiple interests, one of which could possibly corrupt the motivation for act in another is called:',
      'options': ['Conflict of Interest', 'Dual Loyalty', 'Moral Dilemma', 'Whistleblowing'],
      'correctIndex': 0,
    },
    {
      'question': 'What refers to the rules or principles that define right and wrong conduct within a professional environment?',
      'options': ['Legal Code', 'Code of Ethics', 'Cultural Norms', 'Company Bylaws'],
      'correctIndex': 1,
    },
    {
      'question': 'Deontological ethics is most commonly associated with which famous philosopher?',
      'options': ['Aristotle', 'John Stuart Mill', 'Immanuel Kant', 'Plato'],
      'correctIndex': 2,
    },
    {
      'question': 'An employee who reports organizational misconduct or illegal activities to external authorities is known as a:',
      'options': ['Bystander', 'Audit Officer', 'Whistleblower', 'Mediator'],
      'correctIndex': 2,
    },
    {
      'question': 'Corporate Social Responsibility (CSR) implies that a corporation is accountable to which group?',
      'options': ['Only Shareholders', 'Only Customers', 'All Stakeholders', 'Government Agencies Only'],
      'correctIndex': 2,
    },
    {
      'question': 'The study of moral principles that govern a person\'s behavior or the conducting of an activity is known as:',
      'options': ['Sociology', 'Ethics', 'Psychology', 'Anthropology'],
      'correctIndex': 1,
    },
    {
      'question': 'Which of the following describes the moral obligation to act in the best interest of another party (e.g., trustee/beneficiary)?',
      'options': ['Fiduciary Duty', 'Social Contract', 'Utilitarian Contract', 'Liability'],
      'correctIndex': 0,
    },
    {
      'question': 'Ethics that deals with moral questions about technology, computing, and information networks is:',
      'options': ['Bioethics', 'Cyberethics', 'Media Ethics', 'Environmental Ethics'],
      'correctIndex': 1,
    },
  ];

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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showResult
                        ? (_isReviewing
                            ? _buildReviewScreen(key: const ValueKey('review'))
                            : _buildResultScreen(key: const ValueKey('result')))
                        : _buildQuizContent(key: const ValueKey('quiz')),
                  ),
                ),
              ],
            ),
          ),
          const StudentFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildQuizContent({Key? key}) {
    final int questionNum = _currentQuestionIndex + 1;
    final Map<String, dynamic> qData = _questions[_currentQuestionIndex];
    final String questionText = qData['question'];
    final List<String> options = List<String>.from(qData['options']);

    return ListView(
      key: key,
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
            '$questionNum/10',
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
                disabledForegroundColor: Colors.white.withOpacity(0.6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (_isReviewing || _selectedOptionIndex != null)
                  ? () {
                      if (_isReviewing) {
                        // Review flow
                        if (_currentQuestionIndex < 9) {
                          setState(() {
                            _currentQuestionIndex++;
                            _selectedOptionIndex = _userAnswers[_currentQuestionIndex];
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

                        if (_currentQuestionIndex < 9) {
                          setState(() {
                            _currentQuestionIndex++;
                            _selectedOptionIndex = null;
                          });
                        } else {
                          setState(() {
                            _showResult = true;
                          });
                        }
                      }
                    }
                  : null,
              child: Text(
                _currentQuestionIndex == 9 ? (_isReviewing ? 'Finish' : 'Submit') : 'Next',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(int index, String text, int correctIndex) {
    Color cardBgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);
    Color textColor = Colors.black87;

    if (_isReviewing) {
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
      final bool isSelected = _selectedOptionIndex == index;
      if (isSelected) {
        cardBgColor = const Color(0xFF0A5C36).withOpacity(0.1);
        borderColor = const Color(0xFF0A5C36);
        textColor = const Color(0xFF0A5C36);
      }
    }

    final bool isManagerIncorrectMatch = _isReviewing && 
        _currentQuestionIndex == 0 && 
        index == 0 && 
        _userAnswers[0] == 0; 

    if (isManagerIncorrectMatch) {
      cardBgColor = const Color(0xFFF87171); 
      borderColor = Colors.red;
      textColor = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
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
        hoverColor: const Color(0xFF0A5C36).withValues(alpha: 0.04),
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

  Widget _buildResultScreen({Key? key}) {
    final double percentage = (_score / 10.0) * 100;
    return Container(
      key: key,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A5C36).withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0A5C36).withOpacity(0.12),
                          width: 4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_score',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0A5C36),
                            ),
                          ),
                          Text(
                            'of 10',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _score >= 8
                        ? 'Outstanding!'
                        : _score >= 5
                            ? 'Good Job!'
                            : 'Nice Try!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A5C36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You scored ${percentage.toInt()}% correct answers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5C36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isReviewing = true;
                        });
                      },
                      label: const Text(
                        'Review Quiz',
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
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Assignments',
                        style: TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildReviewScreen({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quiz Review',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A5C36),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Score: $_score/10',
                style: const TextStyle(
                  color: Color(0xFF0A5C36),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...List.generate(_questions.length, (qIndex) {
          final question = _questions[qIndex];
          final String questionText = question['question'];
          final List<String> options = List<String>.from(question['options']);
          final int correctIndex = question['correctIndex'];
          final int? userAns = _userAnswers[qIndex];
          final bool isCorrect = userAns == correctIndex;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${qIndex + 1} of 10',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCorrect ? 'Correct' : 'Incorrect',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  questionText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.asMap().entries.map((optionEntry) {
                  final int optIndex = optionEntry.key;
                  final String optText = optionEntry.value;

                  Color cardBgColor = Colors.white;
                  Color borderColor = const Color(0xFFE0E0E0);
                  Color textColor = Colors.black87;
                  Widget? statusIcon;

                  if (optIndex == correctIndex) {
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
                        Expanded(
                          child: Text(
                            optText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                _isReviewing = false;
              });
            },
            child: const Text(
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
}
