import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TriviaShowdownApp());
}

class TriviaShowdownApp extends StatelessWidget {
  const TriviaShowdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trivia Showdown',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6558D3),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F4FC),
        fontFamily: 'Roboto',
      ),
      home: const TriviaHomePage(),
    );
  }
}

class TriviaQuestion {
  final String question;
  final String correctAnswer;
  final List<String> answers;

  TriviaQuestion({
    required this.question,
    required this.correctAnswer,
    required this.answers,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    final correct = decodeHtmlEntities(json['correct_answer'].toString());

    final incorrect = (json['incorrect_answers'] as List)
        .map((answer) => decodeHtmlEntities(answer.toString()))
        .toList();

    final allAnswers = [...incorrect, correct];
    allAnswers.shuffle(Random());

    return TriviaQuestion(
      question: decodeHtmlEntities(json['question'].toString()),
      correctAnswer: correct,
      answers: allAnswers,
    );
  }
}

// Converts common HTML entities returned by Open Trivia DB into readable text.
String decodeHtmlEntities(String input) {
  const entities = {
    '&quot;': '"',
    '&#039;': "'",
    '&apos;': "'",
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&nbsp;': ' ',
    '&eacute;': 'é',
    '&ndash;': '–',
    '&mdash;': '—',
  };

  var result = input;

  entities.forEach((key, value) {
    result = result.replaceAll(key, value);
  });

  result = result.replaceAllMapped(
    RegExp(r'&#(\d+);'),
        (match) => String.fromCharCode(int.parse(match.group(1)!)),
  );

  result = result.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
        (match) => String.fromCharCode(
      int.parse(match.group(1)!, radix: 16),
    ),
  );

  return result;
}

class TriviaHomePage extends StatefulWidget {
  const TriviaHomePage({super.key});

  @override
  State<TriviaHomePage> createState() => _TriviaHomePageState();
}

class _TriviaHomePageState extends State<TriviaHomePage> {
  static const String apiUrl =
      'https://opentdb.com/api.php'
      '?amount=5&category=9&difficulty=easy&type=multiple';

  List<TriviaQuestion> questions = [];

  bool isLoading = true;
  bool hasError = false;
  bool isFinished = false;
  bool isSyncing = false;
  bool syncComplete = false;

  int currentQuestionIndex = 0;
  int score = 0;

  String? selectedAnswer;
  bool hasAnswered = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    setState(() {
      isLoading = true;
      hasError = false;
      isFinished = false;
      isSyncing = false;
      syncComplete = false;
      questions = [];
      currentQuestionIndex = 0;
      score = 0;
      selectedAnswer = null;
      hasAnswered = false;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('The server returned an error. Please try again.');
      }

      final data = jsonDecode(response.body);

      if (data['response_code'] != 0) {
        throw Exception(
          'The trivia service could not provide questions. Please retry.',
        );
      }

      final results = data['results'] as List;

      if (results.length < 5) {
        throw Exception('Not enough questions were returned. Please retry.');
      }

      final loadedQuestions = results
          .map(
            (item) => TriviaQuestion.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        questions = loadedQuestions;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void selectAnswer(String answer) {
    if (hasAnswered) return;

    final currentQuestion = questions[currentQuestionIndex];

    setState(() {
      selectedAnswer = answer;
      hasAnswered = true;

      if (answer == currentQuestion.correctAnswer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        hasAnswered = false;
      });
    } else {
      setState(() {
        isFinished = true;
      });
    }
  }

  Future<void> simulateScoreSync() async {
    setState(() {
      isSyncing = true;
    });

    // This is only a demonstration. No cloud request is made.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      isSyncing = false;
      syncComplete = true;
    });
  }

  Color answerColor(String answer, TriviaQuestion question) {
    if (!hasAnswered) {
      return Colors.white;
    }

    if (answer == question.correctAnswer) {
      return const Color(0xFFD9F5E2);
    }

    if (answer == selectedAnswer) {
      return const Color(0xFFFFDFDF);
    }

    return Colors.white;
  }

  Color answerBorderColor(String answer, TriviaQuestion question) {
    if (!hasAnswered) {
      return const Color(0xFFE1DFF0);
    }

    if (answer == question.correctAnswer) {
      return Colors.green;
    }

    if (answer == selectedAnswer) {
      return Colors.red;
    }

    return const Color(0xFFE1DFF0);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return buildLoadingScreen();
    }

    if (hasError) {
      return buildErrorScreen();
    }

    if (isFinished) {
      return buildResultsScreen();
    }

    if (questions.isEmpty) {
      return buildErrorScreen();
    }

    return buildQuizScreen();
  }

  Widget buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.quiz_rounded,
                size: 75,
                color: Color(0xFF6558D3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Trivia Showdown',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Getting your questions ready...',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 70,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'Unable to Load Questions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQuizScreen() {
    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TRIVIA SHOWDOWN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F4FC),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score: $score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF6558D3),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUESTION ${currentQuestionIndex + 1} OF ${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6558D3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE2E0F0),
                  color: const Color(0xFF6558D3),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 35,
                      color: Color(0xFF6558D3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose your answer:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...question.answers.map((answer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: hasAnswered ? null : () => selectAnswer(answer),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: answerColor(answer, question),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: answerBorderColor(answer, question),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              answer,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (hasAnswered &&
                              answer == question.correctAnswer)
                            const Icon(Icons.check_circle, color: Colors.green),
                          if (hasAnswered &&
                              answer == selectedAnswer &&
                              answer != question.correctAnswer)
                            const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              if (hasAnswered) ...[
                Text(
                  selectedAnswer == question.correctAnswer
                      ? 'Correct! Great job.'
                      : 'Not quite! The correct answer is ${question.correctAnswer}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: selectedAnswer == question.correctAnswer
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: nextQuestion,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6558D3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    currentQuestionIndex == questions.length - 1
                        ? 'See My Results'
                        : 'Next Question',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildResultsScreen() {
    final percentage = ((score / questions.length) * 100).round();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 95,
                  color: Color(0xFFFFB938),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Round Complete!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Here is how you did:',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score / ${questions.length}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6558D3),
                        ),
                      ),
                      const Text(
                        'YOUR SCORE',
                        style: TextStyle(
                          letterSpacing: 2,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '$percentage% correct',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (!syncComplete)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isSyncing ? null : simulateScoreSync,
                      icon: isSyncing
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        isSyncing ? 'Simulating Sync...' : 'Sync Score',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Demo sync complete. No real cloud request was sent.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loadQuestions,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Play Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6558D3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}