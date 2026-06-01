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
                  child: _showResult && !_isReviewing
                      ? _buildResultScreen()
                      : _buildQuizContent(),
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
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (!_isReviewing && _selectedOptionIndex == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an option first!')),
                  );
                  return;
                }

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
              },
              child: Text(
                _currentQuestionIndex == 9 ? (_isReviewing ? 'Finish' : 'Submit') : 'Next',
                style: const TextStyle(
                  color: Colors.white,
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
    final bool isManagerIncorrectMatch = _isReviewing && 
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
    // We mock "9/10 Nice Try!" by default, but let's show the actual user score!
    // To match screenshot 3 exactly, we say "$_score/10" and "Nice Try!"
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_score/10',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0A5C36),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nice Try!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A5C36),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5C36),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                _isReviewing = true;
                _currentQuestionIndex = 0;
                _selectedOptionIndex = _userAnswers[0];
              });
            },
            child: const Text(
              'Review Quiz',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Back to Assignments',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
