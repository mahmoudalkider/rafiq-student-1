
import 'package:flutter/material.dart';
import '../models/course_model.dart';

class LessonContentScreen extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onMarkAsCompleted;

  const LessonContentScreen({
    Key? key,
    required this.lesson,
    required this.onMarkAsCompleted,
  }) : super(key: key);

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  int _currentQuestionIndex = 0;
  bool _showQuiz = false;
  int _quizScore = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
      ),
      body: _showQuiz ? _buildQuizView() : _buildLessonView(),
    );
  }

  Widget _buildLessonView() {
    return SingleChildScrollView(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lesson.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                widget.lesson.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              if (widget.lesson.sections.isNotEmpty)
                ...widget.lesson.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      section,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),

              if (widget.lesson.quiz != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showQuiz = true;
                        _currentQuestionIndex = 0;
                        _quizScore = 0;
                      });
                    },
                    icon: const Icon(Icons.quiz),
                    label: const Text('بدء الاختبار'),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onMarkAsCompleted();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديد الدرس كمكتمل'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('تحديد كمكتمل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    if (widget.lesson.quiz == null) {
      return const Center(
        child: Text('لا توجد اختبارات'),
      );
    }

    final quiz = widget.lesson.quiz!;
    final questions = quiz.questions;

    if (_currentQuestionIndex >= questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('نتيجة الاختبار'),
        ),
        body: Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '✅ اكتمل الاختبار',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'النتيجة: $_quizScore من ${questions.length}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showQuiz = false;
                      _currentQuestionIndex = 0;
                      _quizScore = 0;
                    });
                  },
                  child: const Text('العودة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'السؤال ${_currentQuestionIndex + 1} من ${questions.length}',
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                question.question,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ...List.generate(
                question.options.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      if (index == question.correctAnswerIndex) {
                        _quizScore++;
                      }

                      setState(() {
                        _currentQuestionIndex++;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      question.options[index],
                      textAlign: TextAlign.center,
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
}
