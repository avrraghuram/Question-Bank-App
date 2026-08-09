import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'web_protection.dart';
import 'widgets/ai_chat_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installWebProtection();
  runApp(const QuestionBankApp());
}

enum AppMode { practice, quiz, examPractice, aiHelp, videoSearch }

class Question {
  final String text;
  final String hintBase64;
  final String idealAnswerBase64;
  final String imageUrl;

  const Question({
    required this.text,
    required this.hintBase64,
    required this.idealAnswerBase64,
    required this.imageUrl,
  });

  String get hint => utf8.decode(base64Decode(hintBase64));
  String get idealAnswer => utf8.decode(base64Decode(idealAnswerBase64));
}

String _b64(String input) => base64Encode(utf8.encode(input));

const List<String> titles = [
  'Study Star',
  'Exam Champ',
  'Revision Hero',
  'GCSE Guru',
  'Learning Leader',
];

const List<IconData> avatarIcons = [
  Icons.school,
  Icons.verified,
  Icons.auto_stories,
  Icons.lightbulb,
  Icons.workspace_premium,
];

const List<String> subjects = [
  'Math',
  'English',
  'Science',
  'History',
  'Geography',
  'Computer Science',
  'Biology',
  'Chemistry',
  'Physics',
  'French',
  'Spanish',
  'Art',
  'Music',
  'PE',
  'Business',
  'Economics',
  'Psychology',
  'Religious Studies',
  'Design Tech',
  'Drama',
];

const int questionsPerSubject = 1000;

const Map<String, Color> subjectColors = {
  'Math': Colors.blue,
  'English': Colors.purple,
  'Science': Colors.teal,
  'History': Colors.orange,
  'Geography': Colors.green,
  'Computer Science': Colors.indigo,
  'Biology': Colors.lightGreen,
  'Chemistry': Colors.deepPurple,
  'Physics': Colors.cyan,
  'French': Colors.pink,
  'Spanish': Colors.deepOrange,
  'Art': Colors.amber,
  'Music': Colors.lime,
  'PE': Colors.red,
  'Business': Colors.brown,
  'Economics': Colors.indigoAccent,
  'Psychology': Colors.pinkAccent,
  'Religious Studies': Colors.blueGrey,
  'Design Tech': Colors.tealAccent,
  'Drama': Colors.deepOrangeAccent,
};

const Map<int, int> examDurationQuestionMap = {
  5: 3,
  10: 5,
  15: 7,
  20: 8,
  30: 10,
  45: 12,
  60: 15,
};

const Map<String, String> subjectMarkingSchemes = {
  'Math':
      'Marks are awarded for clear method, correct working, and a correct final answer.',
  'English':
      'Marks focus on clear explanation, correct use of terms, and written expression.',
  'Science':
      'Marks reward accurate facts, clear terminology, and a correct conclusion.',
  'History':
      'Marks reward accurate facts, developed explanation, and use of dates or events.',
  'Geography':
      'Marks reward correct terminology, explanation of processes, and real-world examples.',
  'Computer Science':
      'Marks focus on correct concepts, clear logic, and technical accuracy.',
  'Biology':
      'Marks reward correct biological terms, clear explanation, and linked examples.',
  'Chemistry':
      'Marks focus on chemical accuracy, correct ideas, and balanced explanations.',
  'Physics':
      'Marks reward correct terminology, explanation of forces or energy, and examples.',
  'French':
      'Marks focus on correct meaning, vocabulary, and language use in the example.',
  'Spanish':
      'Marks focus on correct meaning, vocabulary, and language use in the example.',
  'Art':
      'Marks reward understanding of art ideas, clear descriptions, and creative examples.',
  'Music': 'Marks focus on musical terms, clear explanation, and example use.',
  'PE':
      'Marks reward understanding of skills, correct terminology, and fitness ideas.',
  'Business':
      'Marks focus on business terms, clear explanation, and real-world context.',
  'Economics':
      'Marks reward economic terms, clear explanation, and simple examples.',
  'Psychology':
      'Marks focus on psychological ideas, clear explanation, and examples.',
  'Religious Studies':
      'Marks reward understanding of beliefs, clear explanation, and respectful examples.',
  'Design Tech':
      'Marks focus on design terms, clear explanation, and practical examples.',
  'Drama':
      'Marks reward understanding of drama terms, character ideas, and clear examples.',
};

const Map<String, List<String>> gcseKeywordLibrary = {
  'Math': [
    'algebra',
    'equation',
    'function',
    'gradient',
    'percentage',
    'ratio',
    'probability',
    'factor',
    'variable',
    'geometry',
  ],
  'English': [
    'metaphor',
    'simile',
    'tone',
    'theme',
    'imagery',
    'context',
    'inference',
    'structure',
    'audience',
    'perspective',
  ],
  'Science': [
    'photosynthesis',
    'cell',
    'energy',
    'force',
    'reaction',
    'ecosystem',
    'genetics',
    'compound',
    'acid',
    'cellular respiration',
  ],
  'History': [
    'empire',
    'revolution',
    'chronology',
    'cause',
    'consequence',
    'interpretation',
    'evidence',
    'monarchy',
    'constitution',
    'protest',
  ],
  'Geography': [
    'climate',
    'erosion',
    'sustainability',
    'urbanisation',
    'development',
    'hazard',
    'water cycle',
    'population',
    'ecosystem',
    'resource',
  ],
  'Computer Science': [
    'algorithm',
    'binary',
    'variable',
    'loop',
    'function',
    'network',
    'database',
    'cybersecurity',
    'programming',
    'logic',
  ],
  'Biology': [
    'DNA',
    'cell',
    'enzyme',
    'genetics',
    'ecosystem',
    'adaptation',
    'homeostasis',
    'respiration',
    'photosynthesis',
    'organism',
  ],
  'Chemistry': [
    'atom',
    'molecule',
    'reaction',
    'periodic table',
    'acid',
    'base',
    'compound',
    'catalyst',
    'mass',
    'concentration',
  ],
  'Physics': [
    'force',
    'motion',
    'energy',
    'power',
    'gravity',
    'momentum',
    'electricity',
    'magnetism',
    'wave',
    'speed',
  ],
  'French': [
    'bonjour',
    'merci',
    'vocabulaire',
    'grammaire',
    'profil',
    'conjugaison',
    'phrase',
    'traduction',
    'expression',
    'prononciation',
  ],
  'Spanish': [
    'hola',
    'gracias',
    'vocabulario',
    'gramática',
    'frase',
    'traducción',
    'expresión',
    'verbo',
    'sustantivo',
    'pronunciación',
  ],
  'Art': [
    'composition',
    'perspective',
    'texture',
    'medium',
    'colour',
    'form',
    'contrast',
    'style',
    'critique',
    'concept',
  ],
  'Music': [
    'rhythm',
    'tempo',
    'melody',
    'harmony',
    'dynamics',
    'pitch',
    'texture',
    'structure',
    'notation',
    'timbre',
  ],
  'PE': [
    'fitness',
    'skill',
    'stamina',
    'strength',
    'agility',
    'technique',
    'training',
    'teamwork',
    'strategy',
    'health',
  ],
  'Business': [
    'market',
    'profit',
    'supply',
    'demand',
    'entrepreneur',
    'stakeholder',
    'revenue',
    'cost',
    'brand',
    'customer',
  ],
  'Economics': [
    'inflation',
    'scarcity',
    'GDP',
    'consumer',
    'cost',
    'resources',
    'growth',
    'unemployment',
    'demand',
    'market',
  ],
  'Psychology': [
    'behaviour',
    'cognition',
    'memory',
    'emotion',
    'development',
    'perception',
    'learning',
    'conditioning',
    'personality',
    'social',
  ],
  'Religious Studies': [
    'belief',
    'faith',
    'ethics',
    'worship',
    'sacred',
    'scripture',
    'ritual',
    'pilgrimage',
    'morality',
    'religion',
  ],
  'Design Tech': [
    'prototype',
    'material',
    'innovation',
    'function',
    'structure',
    'sustainability',
    'design',
    'model',
    'specification',
    'user',
  ],
  'Drama': [
    'character',
    'dialogue',
    'staging',
    'tension',
    'conflict',
    'atmosphere',
    'performance',
    'script',
    'improvisation',
    'monologue',
  ],
};

final Map<String, List<Question>> questionBank = {
  for (final subject in subjects)
    subject: _generateQuestionsForSubject(subject),
};

List<Question> _generateQuestionsForSubject(String subject) {
  return List.generate(questionsPerSubject, (index) {
    final questionNumber = index + 1;
    switch (subject) {
      case 'Math':
        return _buildMathQuestion(index, questionNumber);
      case 'English':
        return _buildEnglishQuestion(index, questionNumber);
      case 'Science':
        return _buildScienceQuestion(index, questionNumber);
      case 'History':
        return _buildHistoryQuestion(index, questionNumber);
      case 'Geography':
        return _buildGeographyQuestion(index, questionNumber);
      case 'Computer Science':
        return _buildComputerScienceQuestion(index, questionNumber);
      case 'Biology':
        return _buildBiologyQuestion(index, questionNumber);
      case 'Chemistry':
        return _buildChemistryQuestion(index, questionNumber);
      case 'Physics':
        return _buildPhysicsQuestion(index, questionNumber);
      case 'French':
        return _buildFrenchQuestion(index, questionNumber);
      case 'Spanish':
        return _buildSpanishQuestion(index, questionNumber);
      case 'Art':
        return _buildArtQuestion(index, questionNumber);
      case 'Music':
        return _buildMusicQuestion(index, questionNumber);
      case 'PE':
        return _buildPeQuestion(index, questionNumber);
      case 'Business':
        return _buildBusinessQuestion(index, questionNumber);
      case 'Economics':
        return _buildEconomicsQuestion(index, questionNumber);
      case 'Psychology':
        return _buildPsychologyQuestion(index, questionNumber);
      case 'Religious Studies':
        return _buildReligiousStudiesQuestion(index, questionNumber);
      case 'Design Tech':
        return _buildDesignTechQuestion(index, questionNumber);
      case 'Drama':
        return _buildDramaQuestion(index, questionNumber);
      default:
        return Question(
          text: 'Explore this question about $subject.',
          hintBase64: _b64('Think about the main idea and key vocabulary.'),
          idealAnswerBase64:
              _b64('Answer the question clearly using the subject terms.'),
          imageUrl:
              'https://picsum.photos/seed/${subject.replaceAll(' ', '').toLowerCase()}$questionNumber/600/320',
        );
    }
  });
}

Question _buildMathQuestion(int index, int questionNumber) {
  final type = index % 5;
  final a = 2 + (index % 8);
  final b = 3 + (index % 7);
  final c = a * (index % 10 + 2) + b;
  if (type == 0) {
    return Question(
      text: 'Solve for x: ${a}x + $b = $c.',
      hintBase64: _b64('Subtract $b then divide by $a.'),
      idealAnswerBase64: _b64('x = ${(c - b) ~/ a}.'),
      imageUrl: 'https://picsum.photos/seed/math$questionNumber/600/320',
    );
  }
  if (type == 1) {
    final percentage = 5 + (index % 20) * 2;
    final value = 50 + (index % 10) * 10;
    return Question(
      text: 'What is $percentage% of $value?',
      hintBase64: _b64('Convert $percentage% to a decimal before multiplying.'),
      idealAnswerBase64: _b64('${(percentage / 100 * value).round()}.'),
      imageUrl: 'https://picsum.photos/seed/math$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is the area of a rectangle with sides ${a + 1} and ${b + 2}?',
      hintBase64: _b64('Multiply the two side lengths to get area.'),
      idealAnswerBase64: _b64('Area = ${(a + 1) * (b + 2)}.'),
      imageUrl: 'https://picsum.photos/seed/math$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'Find the value of ${a} + ${b} × ${index % 5 + 2}.',
      hintBase64: _b64('Multiply before adding according to BIDMAS.'),
      idealAnswerBase64: _b64('Value = ${a + b * (index % 5 + 2)}.'),
      imageUrl: 'https://picsum.photos/seed/math$questionNumber/600/320',
    );
  }
  return Question(
    text:
        'Write the next number in the sequence: ${a}, ${a + b}, ${a + b * 2}, ...',
    hintBase64: _b64('Look for the difference between terms.'),
    idealAnswerBase64: _b64('The next number is ${a + b * 3}.'),
    imageUrl: 'https://picsum.photos/seed/math$questionNumber/600/320',
  );
}

Question _buildEnglishQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'What is the function of an adjective in a sentence?',
      hintBase64: _b64('It describes or modifies a noun.'),
      idealAnswerBase64:
          _b64('An adjective gives more detail about a noun or pronoun.'),
      imageUrl: 'https://picsum.photos/seed/english$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is personification?',
      hintBase64: _b64('It gives human qualities to non-human things.'),
      idealAnswerBase64: _b64(
          'Personification describes something non-human as if it were human.'),
      imageUrl: 'https://picsum.photos/seed/english$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What does the word "persuade" mean in writing?',
      hintBase64: _b64('It encourages someone to agree or act.'),
      idealAnswerBase64: _b64(
          'To persuade means to convince the reader by giving reasons or emotions.'),
      imageUrl: 'https://picsum.photos/seed/english$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What is the purpose of a conclusion in an essay?',
      hintBase64: _b64('It brings the ideas together and ends the piece.'),
      idealAnswerBase64: _b64(
          'A conclusion summarises the main points and closes the argument.'),
      imageUrl: 'https://picsum.photos/seed/english$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is a simile?',
    hintBase64: _b64('It compares two things using "like" or "as".'),
    idealAnswerBase64: _b64(
        'A simile is a comparison using like or as to describe something.'),
    imageUrl: 'https://picsum.photos/seed/english$questionNumber/600/320',
  );
}

Question _buildScienceQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'What is H₂O?',
      hintBase64: _b64('It is a common chemical with two elements.'),
      idealAnswerBase64: _b64('H₂O is the chemical formula for water.'),
      imageUrl: 'https://picsum.photos/seed/science$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'Which planet is known as the Red Planet?',
      hintBase64: _b64('It is the fourth planet from the Sun.'),
      idealAnswerBase64: _b64('Mars is called the Red Planet.'),
      imageUrl: 'https://picsum.photos/seed/science$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What gas do plants need for photosynthesis?',
      hintBase64: _b64('Plants take it from the air.'),
      idealAnswerBase64: _b64('Plants need carbon dioxide for photosynthesis.'),
      imageUrl: 'https://picsum.photos/seed/science$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What is the centre of a cell called?',
      hintBase64: _b64('It contains the genetic material.'),
      idealAnswerBase64: _b64('The nucleus is the centre of a cell.'),
      imageUrl: 'https://picsum.photos/seed/science$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What do we call an organism made of one cell?',
    hintBase64: _b64('It is the simplest living unit.'),
    idealAnswerBase64: _b64('A single-celled organism is called unicellular.'),
    imageUrl: 'https://picsum.photos/seed/science$questionNumber/600/320',
  );
}

Question _buildHistoryQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'Who was the first Roman emperor?',
      hintBase64: _b64('He was first called Octavian.'),
      idealAnswerBase64: _b64('The first Roman emperor was Augustus.'),
      imageUrl: 'https://picsum.photos/seed/history$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'In what year did World War I begin?',
      hintBase64: _b64('It began in the early 1900s.'),
      idealAnswerBase64: _b64('World War I began in 1914.'),
      imageUrl: 'https://picsum.photos/seed/history$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What was signed in 1215 that limited royal power?',
      hintBase64: _b64('It is an early document of rights.'),
      idealAnswerBase64: _b64('The Magna Carta was signed in 1215.'),
      imageUrl: 'https://picsum.photos/seed/history$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What was the Industrial Revolution about?',
      hintBase64: _b64('It changed how goods were made.'),
      idealAnswerBase64:
          _b64('It was the shift to machine-based manufacturing.'),
      imageUrl: 'https://picsum.photos/seed/history$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What period included powerful kings and knights?',
    hintBase64: _b64('It was before the modern era.'),
    idealAnswerBase64: _b64('This period was the Middle Ages or medieval era.'),
    imageUrl: 'https://picsum.photos/seed/history$questionNumber/600/320',
  );
}

Question _buildGeographyQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'What is the capital city of England?',
      hintBase64: _b64('It is also the largest city in the UK.'),
      idealAnswerBase64: _b64('The capital city of England is London.'),
      imageUrl: 'https://picsum.photos/seed/geography$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'Which continent is Brazil in?',
      hintBase64: _b64('It is the largest continent by area.'),
      idealAnswerBase64: _b64('Brazil is in South America.'),
      imageUrl: 'https://picsum.photos/seed/geography$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is a peninsula?',
      hintBase64: _b64('It is land surrounded by water on three sides.'),
      idealAnswerBase64:
          _b64('A peninsula is a piece of land nearly surrounded by water.'),
      imageUrl: 'https://picsum.photos/seed/geography$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What type of climate is dry and hot with little rain?',
      hintBase64: _b64('It is often found in deserts.'),
      idealAnswerBase64: _b64('That is a desert climate.'),
      imageUrl: 'https://picsum.photos/seed/geography$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is the name of the longest river in the world?',
    hintBase64: _b64('It flows through Egypt.'),
    idealAnswerBase64: _b64('The Nile is the longest river in the world.'),
    imageUrl: 'https://picsum.photos/seed/geography$questionNumber/600/320',
  );
}

Question _buildComputerScienceQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'What is a computer program?',
      hintBase64: _b64('It is a set of instructions the computer follows.'),
      idealAnswerBase64: _b64(
          'A computer program is a sequence of instructions that tells a computer what to do.'),
      imageUrl: 'https://picsum.photos/seed/compsci$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What does CPU stand for?',
      hintBase64: _b64('It is the computer&#39;s main chip.'),
      idealAnswerBase64: _b64('CPU stands for Central Processing Unit.'),
      imageUrl: 'https://picsum.photos/seed/compsci$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is an algorithm?',
      hintBase64: _b64('It is a plan of steps to solve a problem.'),
      idealAnswerBase64:
          _b64('An algorithm is a step-by-step method for solving a task.'),
      imageUrl: 'https://picsum.photos/seed/compsci$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What does RAM do in a computer?',
      hintBase64: _b64('It stores temporary data while the computer runs.'),
      idealAnswerBase64: _b64(
          'RAM holds data and programs temporarily while the computer is on.'),
      imageUrl: 'https://picsum.photos/seed/compsci$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is the purpose of a network?',
    hintBase64: _b64('It lets computers share data and devices.'),
    idealAnswerBase64: _b64(
        'A network connects computers so they can communicate and share resources.'),
    imageUrl: 'https://picsum.photos/seed/compsci$questionNumber/600/320',
  );
}

Question _buildBiologyQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'What are cells?',
      hintBase64: _b64('They are the basic building blocks of life.'),
      idealAnswerBase64:
          _b64('Cells are the smallest units of living organisms.'),
      imageUrl: 'https://picsum.photos/seed/biology$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What do plants use to make food?',
      hintBase64: _b64('They use sunlight, water, and carbon dioxide.'),
      idealAnswerBase64:
          _b64('Plants use photosynthesis to make food from sunlight.'),
      imageUrl: 'https://picsum.photos/seed/biology$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is DNA?',
      hintBase64: _b64('It carries genetic instructions.'),
      idealAnswerBase64:
          _b64('DNA contains the genetic code for living organisms.'),
      imageUrl: 'https://picsum.photos/seed/biology$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What is the role of the heart?',
      hintBase64: _b64('It pumps blood around the body.'),
      idealAnswerBase64:
          _b64('The heart circulates blood to deliver oxygen and nutrients.'),
      imageUrl: 'https://picsum.photos/seed/biology$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is an ecosystem?',
    hintBase64:
        _b64('It is a community of living things and their environment.'),
    idealAnswerBase64: _b64(
        'An ecosystem is a system formed by living organisms and their surroundings.'),
    imageUrl: 'https://picsum.photos/seed/biology$questionNumber/600/320',
  );
}

Question _buildChemistryQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'What is an element?',
      hintBase64: _b64('It is a pure substance made of one kind of atom.'),
      idealAnswerBase64:
          _b64('An element is a substance consisting of one type of atom.'),
      imageUrl: 'https://picsum.photos/seed/chemistry$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is an atom?',
      hintBase64: _b64('It is the smallest part of an element.'),
      idealAnswerBase64: _b64(
          'An atom is the smallest unit of matter that keeps the identity of an element.'),
      imageUrl: 'https://picsum.photos/seed/chemistry$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is a chemical reaction?',
      hintBase64: _b64('It changes substances into new ones.'),
      idealAnswerBase64: _b64(
          'A chemical reaction is when substances interact and form new substances.'),
      imageUrl: 'https://picsum.photos/seed/chemistry$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What is the pH of an acid?',
      hintBase64: _b64('It is below 7.'),
      idealAnswerBase64: _b64('An acid has a pH value below 7.'),
      imageUrl: 'https://picsum.photos/seed/chemistry$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is a mixture?',
    hintBase64: _b64(
        'It is two or more substances combined without a chemical reaction.'),
    idealAnswerBase64: _b64(
        'A mixture is a combination of substances that can be separated by physical means.'),
    imageUrl: 'https://picsum.photos/seed/chemistry$questionNumber/600/320',
  );
}

Question _buildPhysicsQuestion(int index, int questionNumber) {
  final type = index % 5;
  if (type == 0) {
    return Question(
      text: 'What is force?',
      hintBase64: _b64('It changes the motion of an object.'),
      idealAnswerBase64: _b64('Force is a push or pull on an object.'),
      imageUrl: 'https://picsum.photos/seed/physics$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is speed?',
      hintBase64: _b64('It is distance covered in a certain time.'),
      idealAnswerBase64: _b64('Speed tells how fast something moves.'),
      imageUrl: 'https://picsum.photos/seed/physics$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What does gravity do?',
      hintBase64: _b64('It pulls objects toward each other.'),
      idealAnswerBase64:
          _b64('Gravity attracts objects toward the Earth or each other.'),
      imageUrl: 'https://picsum.photos/seed/physics$questionNumber/600/320',
    );
  }
  if (type == 3) {
    return Question(
      text: 'What is energy?',
      hintBase64: _b64('It is needed to do work or cause change.'),
      idealAnswerBase64:
          _b64('Energy is the ability to do work or cause a change.'),
      imageUrl: 'https://picsum.photos/seed/physics$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is the term for motion in a straight line?',
    hintBase64: _b64('It is travel in one direction without turning.'),
    idealAnswerBase64: _b64('This is called linear motion.'),
    imageUrl: 'https://picsum.photos/seed/physics$questionNumber/600/320',
  );
}

Question _buildFrenchQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is "Bonjour"?',
      hintBase64: _b64('It is a greeting in the morning.'),
      idealAnswerBase64:
          _b64('"Bonjour" means "Hello" or "Good morning" in French.'),
      imageUrl: 'https://picsum.photos/seed/french$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'How do you say "thank you" in French?',
      hintBase64: _b64('It starts with merci.'),
      idealAnswerBase64: _b64('"Thank you" in French is "merci".'),
      imageUrl: 'https://picsum.photos/seed/french$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What does "au revoir" mean?',
      hintBase64: _b64('It is used when leaving.'),
      idealAnswerBase64: _b64('"Au revoir" means "Goodbye".'),
      imageUrl: 'https://picsum.photos/seed/french$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is the French word for "please"?',
    hintBase64: _b64('It is used in polite requests.'),
    idealAnswerBase64: _b64('"Please" in French is "s\'il vous plaît".'),
    imageUrl: 'https://picsum.photos/seed/french$questionNumber/600/320',
  );
}

Question _buildSpanishQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What does "Hola" mean?',
      hintBase64: _b64('It is a common Spanish greeting.'),
      idealAnswerBase64: _b64('"Hola" means "Hello" in Spanish.'),
      imageUrl: 'https://picsum.photos/seed/spanish$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'How do you say "goodbye" in Spanish?',
      hintBase64: _b64('It starts with adiós.'),
      idealAnswerBase64: _b64('"Goodbye" in Spanish is "adiós".'),
      imageUrl: 'https://picsum.photos/seed/spanish$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is "gracias"?',
      hintBase64: _b64('It expresses gratitude.'),
      idealAnswerBase64: _b64('"Gracias" means "Thank you" in Spanish.'),
      imageUrl: 'https://picsum.photos/seed/spanish$questionNumber/600/320',
    );
  }
  return Question(
    text: 'How do you ask "How are you?" in Spanish?',
    hintBase64: _b64('It begins with "Cómo".'),
    idealAnswerBase64: _b64('"How are you?" in Spanish is "¿Cómo estás?".'),
    imageUrl: 'https://picsum.photos/seed/spanish$questionNumber/600/320',
  );
}

Question _buildArtQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is sketching?',
      hintBase64: _b64('It is a quick drawing used to plan art.'),
      idealAnswerBase64: _b64(
          'Sketching is making a simple drawing to capture ideas or shapes.'),
      imageUrl: 'https://picsum.photos/seed/art$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is colour mixing?',
      hintBase64: _b64('It combines two or more colours.'),
      idealAnswerBase64:
          _b64('Colour mixing is blending pigments to make new colours.'),
      imageUrl: 'https://picsum.photos/seed/art$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What makes an object look three-dimensional?',
      hintBase64: _b64('Use light, shadow, and perspective.'),
      idealAnswerBase64:
          _b64('Shading, highlights and perspective make a drawing look 3D.'),
      imageUrl: 'https://picsum.photos/seed/art$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is tone in art?',
    hintBase64: _b64('It is how light or dark something appears.'),
    idealAnswerBase64: _b64('Tone is the lightness or darkness of a colour.'),
    imageUrl: 'https://picsum.photos/seed/art$questionNumber/600/320',
  );
}

Question _buildMusicQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is tempo?',
      hintBase64: _b64('It is the speed of the music.'),
      idealAnswerBase64:
          _b64('Tempo is how fast or slow a piece of music is played.'),
      imageUrl: 'https://picsum.photos/seed/music$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What does pitch show?',
      hintBase64: _b64('It shows how high or low a note sounds.'),
      idealAnswerBase64: _b64('Pitch tells us whether a note is high or low.'),
      imageUrl: 'https://picsum.photos/seed/music$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is rhythm?',
      hintBase64: _b64('It is the pattern of beats.'),
      idealAnswerBase64:
          _b64('Rhythm is the pattern of sounds and silences in music.'),
      imageUrl: 'https://picsum.photos/seed/music$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is a melody?',
    hintBase64: _b64('It is a sequence of musical notes.'),
    idealAnswerBase64:
        _b64('A melody is a series of notes that make a musical phrase.'),
    imageUrl: 'https://picsum.photos/seed/music$questionNumber/600/320',
  );
}

Question _buildPeQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is warm-up?',
      hintBase64: _b64('It prepares your body before exercise.'),
      idealAnswerBase64: _b64(
          'A warm-up is a short activity that prepares muscles for exercise.'),
      imageUrl: 'https://picsum.photos/seed/pe$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'Why is teamwork important in sport?',
      hintBase64: _b64('Teams work together to win.'),
      idealAnswerBase64: _b64(
          'Teamwork helps players cooperate and support each other in sport.'),
      imageUrl: 'https://picsum.photos/seed/pe$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What does agility mean?',
      hintBase64: _b64('It is being quick and balanced.'),
      idealAnswerBase64: _b64(
          'Agility is the ability to move quickly and change direction safely.'),
      imageUrl: 'https://picsum.photos/seed/pe$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is strength?',
    hintBase64: _b64('It is how much force your muscles can apply.'),
    idealAnswerBase64:
        _b64('Strength is the ability to lift, push, or carry heavy loads.'),
    imageUrl: 'https://picsum.photos/seed/pe$questionNumber/600/320',
  );
}

Question _buildBusinessQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is revenue?',
      hintBase64: _b64('It is the income from selling products or services.'),
      idealAnswerBase64:
          _b64('Revenue is the total money a business earns from sales.'),
      imageUrl: 'https://picsum.photos/seed/business$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is profit?',
      hintBase64: _b64('It is what remains after costs are deducted.'),
      idealAnswerBase64: _b64(
          'Profit is the money left after expenses are taken from revenue.'),
      imageUrl: 'https://picsum.photos/seed/business$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is a customer?',
      hintBase64: _b64('They buy goods or services.'),
      idealAnswerBase64:
          _b64('A customer is someone who purchases from a business.'),
      imageUrl: 'https://picsum.photos/seed/business$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is advertising?',
    hintBase64: _b64('It tells people about a product or service.'),
    idealAnswerBase64:
        _b64('Advertising is a way to promote a product to customers.'),
    imageUrl: 'https://picsum.photos/seed/business$questionNumber/600/320',
  );
}

Question _buildEconomicsQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is supply?',
      hintBase64: _b64('It is how much of a product is available.'),
      idealAnswerBase64: _b64(
          'Supply is the amount of a good or service sellers are willing to offer.'),
      imageUrl: 'https://picsum.photos/seed/economics$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is demand?',
      hintBase64: _b64('It is how much people want a product.'),
      idealAnswerBase64:
          _b64('Demand is the desire of buyers for a product or service.'),
      imageUrl: 'https://picsum.photos/seed/economics$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is a budget?',
      hintBase64: _b64('It is a plan for spending money.'),
      idealAnswerBase64:
          _b64('A budget is a plan showing how money should be used.'),
      imageUrl: 'https://picsum.photos/seed/economics$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is a market?',
    hintBase64: _b64('It is where buyers and sellers meet.'),
    idealAnswerBase64:
        _b64('A market is any place where goods and services are traded.'),
    imageUrl: 'https://picsum.photos/seed/economics$questionNumber/600/320',
  );
}

Question _buildPsychologyQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is learning?',
      hintBase64: _b64('It is gaining knowledge or skills.'),
      idealAnswerBase64:
          _b64('Learning is acquiring new knowledge, behaviour, or skills.'),
      imageUrl: 'https://picsum.photos/seed/psychology$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is emotion?',
      hintBase64: _b64('It is a feeling like joy or fear.'),
      idealAnswerBase64:
          _b64('Emotion is a strong feeling often linked to events.'),
      imageUrl: 'https://picsum.photos/seed/psychology$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is behaviour?',
      hintBase64: _b64('It is how someone acts.'),
      idealAnswerBase64: _b64(
          'Behaviour is the way a person or animal acts in response to the environment.'),
      imageUrl: 'https://picsum.photos/seed/psychology$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is memory?',
    hintBase64: _b64('It is how you recall information.'),
    idealAnswerBase64:
        _b64('Memory is the ability to retain and recall information.'),
    imageUrl: 'https://picsum.photos/seed/psychology$questionNumber/600/320',
  );
}

Question _buildReligiousStudiesQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is a belief?',
      hintBase64: _b64('It is an idea accepted as true.'),
      idealAnswerBase64:
          _b64('A belief is something a person accepts as true or real.'),
      imageUrl: 'https://picsum.photos/seed/religion$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is worship?',
      hintBase64: _b64('It is showing respect for something sacred.'),
      idealAnswerBase64:
          _b64('Worship is showing reverence and devotion to a deity or idea.'),
      imageUrl: 'https://picsum.photos/seed/religion$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is a moral?',
      hintBase64: _b64('It is a rule about right and wrong.'),
      idealAnswerBase64: _b64('A moral is a principle about good behaviour.'),
      imageUrl: 'https://picsum.photos/seed/religion$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is prayer?',
    hintBase64: _b64('It is talking to a higher power.'),
    idealAnswerBase64:
        _b64('Prayer is speaking or thinking to a deity or spiritual force.'),
    imageUrl: 'https://picsum.photos/seed/religion$questionNumber/600/320',
  );
}

Question _buildDesignTechQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is a prototype?',
      hintBase64: _b64('It is a first version used for testing.'),
      idealAnswerBase64: _b64(
          'A prototype is an early model of a product used to test ideas.'),
      imageUrl: 'https://picsum.photos/seed/design$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is CAD?',
      hintBase64: _b64('It is design software used by engineers.'),
      idealAnswerBase64: _b64(
          'CAD is Computer-Aided Design software used to create drawings and models.'),
      imageUrl: 'https://picsum.photos/seed/design$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is sustainability?',
      hintBase64:
          _b64('It means using resources without harming the environment.'),
      idealAnswerBase64: _b64(
          'Sustainability is using resources in a way that does not damage the environment.'),
      imageUrl: 'https://picsum.photos/seed/design$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is ergonomics?',
    hintBase64:
        _b64('It is about making products comfortable and easy to use.'),
    idealAnswerBase64: _b64(
        'Ergonomics is designing products so they are safe, comfortable, and efficient to use.'),
    imageUrl: 'https://picsum.photos/seed/design$questionNumber/600/320',
  );
}

Question _buildDramaQuestion(int index, int questionNumber) {
  final type = index % 4;
  if (type == 0) {
    return Question(
      text: 'What is a script?',
      hintBase64: _b64('It is the written text of a play.'),
      idealAnswerBase64: _b64(
          'A script is the dialogue and directions actors follow in a play.'),
      imageUrl: 'https://picsum.photos/seed/drama$questionNumber/600/320',
    );
  }
  if (type == 1) {
    return Question(
      text: 'What is stage direction?',
      hintBase64: _b64('It tells actors where to move.'),
      idealAnswerBase64: _b64(
          'Stage directions describe actions, movement, and positioning in a play.'),
      imageUrl: 'https://picsum.photos/seed/drama$questionNumber/600/320',
    );
  }
  if (type == 2) {
    return Question(
      text: 'What is characterisation?',
      hintBase64: _b64('It describes how a character thinks and behaves.'),
      idealAnswerBase64: _b64(
          'Characterisation is the way a character is presented through actions and speech.'),
      imageUrl: 'https://picsum.photos/seed/drama$questionNumber/600/320',
    );
  }
  return Question(
    text: 'What is mood in drama?',
    hintBase64: _b64('It helps show emotions and meaning.'),
    idealAnswerBase64:
        _b64('Mood is the emotional feeling created in a scene or play.'),
    imageUrl: 'https://picsum.photos/seed/drama$questionNumber/600/320',
  );
}

class QuestionBankApp extends StatelessWidget {
  const QuestionBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GCSE Question Bank',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const QuestionBankPage(),
    );
  }
}

class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  String selectedSubject = subjects.first;
  int currentQuestionIndex = 0;
  bool showHint = false;
  bool showAnswer = false;
  int totalAsked = 0;
  int hintsUsed = 0;
  int answersViewed = 0;
  int correctCount = 0;
  int incorrectCount = 0;
  SharedPreferences? prefs;
  final Map<String, int> subjectAttempts = {
    for (final subject in subjects) subject: 0,
  };
  AppMode appMode = AppMode.practice;
  String userName = '';
  String userTitle = titles.first;
  int selectedAvatarIndex = 0;
  String userAnswer = '';
  String quizFeedback = '';
  bool quizAnsweredCorrectly = false;
  bool examStarted = false;
  int examQuestionCount = 4;
  int examCorrect = 0;
  String examAnswer = '';
  String examResultMessage = '';
  final List<Map<String, String>> aiMessages = [];
  final Map<String, String> savedAnswers = {};
  final TextEditingController userAnswerController = TextEditingController();
  final TextEditingController aiController = TextEditingController();
  final TextEditingController videoSearchController = TextEditingController();
  String videoSearchQuery = '';
  bool aiEnabled = true;
  String aiModeMessage = 'AI mode is enabled. Ask any GCSE question safely.';
  List<String> aiSuggestions = [];
  int lastAnswerScore = 0;
  int examDurationMinutes = 10;
  int examQuestionIndex = 0;
  List<Question> examQuestions = [];
  List<String> examStudentAnswers = [];
  List<int> examScores = [];
  bool showExamReview = false;
  String lastAnswerStars = '';
  String lastAnswerFeedback = '';
  final TextEditingController examAnswerController = TextEditingController();
  Timer? examTimer;
  int examSecondsRemaining = 120;

  @override
  void initState() {
    super.initState();
    _loadPreferences().whenComplete(_chooseRandomQuestion);
  }

  @override
  void dispose() {
    userAnswerController.dispose();
    aiController.dispose();
    videoSearchController.dispose();
    examAnswerController.dispose();
    examTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      totalAsked = prefs?.getInt('totalAsked') ?? 0;
      hintsUsed = prefs?.getInt('hintsUsed') ?? 0;
      answersViewed = prefs?.getInt('answersViewed') ?? 0;
      correctCount = prefs?.getInt('correctCount') ?? 0;
      incorrectCount = prefs?.getInt('incorrectCount') ?? 0;
      userName = prefs?.getString('userName') ?? '';
      userTitle = prefs?.getString('userTitle') ?? titles.first;
      selectedAvatarIndex = prefs?.getInt('avatarIndex') ?? 0;
      for (final subject in subjects) {
        subjectAttempts[subject] = prefs?.getInt('subject_$subject') ?? 0;
      }
    });
  }

  Future<void> _savePreferences() async {
    if (prefs == null) return;
    await prefs!.setInt('totalAsked', totalAsked);
    await prefs!.setInt('hintsUsed', hintsUsed);
    await prefs!.setInt('answersViewed', answersViewed);
    await prefs!.setInt('correctCount', correctCount);
    await prefs!.setInt('incorrectCount', incorrectCount);
    await prefs!.setString('userName', userName);
    await prefs!.setString('userTitle', userTitle);
    await prefs!.setInt('avatarIndex', selectedAvatarIndex);
    for (final subject in subjects) {
      await prefs!.setInt('subject_$subject', subjectAttempts[subject] ?? 0);
    }
  }

  Question get _currentQuestion =>
      questionBank[selectedSubject]![currentQuestionIndex];
  String get _questionId => '$selectedSubject-$currentQuestionIndex';

  void _chooseRandomQuestion() {
    final questions = questionBank[selectedSubject]!;
    final random = Random();
    setState(() {
      currentQuestionIndex = random.nextInt(questions.length);
      showHint = false;
      showAnswer = false;
      userAnswer = '';
      userAnswerController.text = '';
      quizFeedback = '';
      totalAsked += 1;
      subjectAttempts[selectedSubject] =
          (subjectAttempts[selectedSubject] ?? 0) + 1;
    });
    _savePreferences();
  }

  void _showHint() {
    setState(() {
      showHint = true;
      hintsUsed += 1;
    });
    _savePreferences();
  }

  void _showAnswer() {
    setState(() {
      showAnswer = true;
      answersViewed += 1;
    });
    _savePreferences();
  }

  void _markCorrect() {
    setState(() {
      correctCount += 1;
      quizFeedback = 'Nice work! Marked as correct.';
    });
    _savePreferences();
  }

  void _markIncorrect() {
    setState(() {
      incorrectCount += 1;
      quizFeedback = 'Keep practising and review the ideal answer.';
    });
    _savePreferences();
  }

  void _selectSubject(String subject) {
    if (selectedSubject == subject) return;
    setState(() {
      selectedSubject = subject;
      showHint = false;
      showAnswer = false;
      currentQuestionIndex = Random().nextInt(questionBank[subject]!.length);
      userAnswer = '';
      userAnswerController.text = '';
      quizFeedback = '';
      examStarted = false;
      examResultMessage = '';
    });
  }

  void _setAppMode(AppMode mode) {
    setState(() {
      appMode = mode;
      quizFeedback = '';
      if (mode != AppMode.examPractice) {
        examStarted = false;
        examTimer?.cancel();
      }
    });
  }

  void _showProfileEditor() {
    final nameController = TextEditingController(text: userName);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 14),
              const Text('Choose title',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: titles.map((title) {
                  return ChoiceChip(
                    label: Text(title),
                    selected: userTitle == title,
                    onSelected: (_) => setState(() => userTitle = title),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Pick avatar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: List.generate(avatarIcons.length, (index) {
                  return ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: selectedAvatarIndex == index
                          ? Colors.deepPurple
                          : Colors.grey,
                      child: Icon(avatarIcons[index],
                          color: Colors.white, size: 18),
                    ),
                    label: Text('A${index + 1}'),
                    selected: selectedAvatarIndex == index,
                    onSelected: (_) =>
                        setState(() => selectedAvatarIndex = index),
                  );
                }),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          userName = nameController.text.trim();
                          if (userName.isEmpty) {
                            userName = 'Student';
                          }
                          _savePreferences();
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }

  void _showQuestionBrowser() {
    final questions = questionBank[selectedSubject]!;
    final searchController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final query = searchController.text.toLowerCase();
          final filteredEntries = questions.asMap().entries.where((entry) {
            final text =
                '${entry.value.text} ${entry.value.hint} ${entry.value.idealAnswer}'
                    .toLowerCase();
            return query.isEmpty || text.contains(query);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Browse Questions',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: searchController,
                  onChanged: (_) => setModalState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search question text or answer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: filteredEntries.isEmpty
                      ? const Center(
                          child: Text('No questions match your search.'))
                      : ListView.builder(
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            return ListTile(
                              title: Text('Question ${entry.key + 1}'),
                              subtitle: Text(entry.value.text,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                setState(() {
                                  currentQuestionIndex = entry.key;
                                  showHint = false;
                                  showAnswer = false;
                                  userAnswer = '';
                                  userAnswerController.clear();
                                  quizFeedback = '';
                                  examStarted = false;
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildQuestionPickerRow(Color subjectColor) {
    final total = questionBank[selectedSubject]!.length;
    return Row(
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.list),
          label: const Text('Browse questions'),
          onPressed: _showQuestionBrowser,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Question ${currentQuestionIndex + 1} of $total',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _submitQuizAnswer() {
    final answer = userAnswer.trim();
    final ideal = _currentQuestion.idealAnswer;
    final score = _gradeAnswer(answer, ideal);
    final stars = _starsForScore(score);
    setState(() {
      quizAnsweredCorrectly = score >= 3;
      quizFeedback = 'Score: $score/5 $stars';
      lastAnswerScore = score;
      lastAnswerStars = stars;
      lastAnswerFeedback = score >= 4
          ? 'Excellent response!'
          : score >= 2
              ? 'Good attempt, review the ideal answer.'
              : 'Try again and focus on the key terms.';
      if (score >= 3) {
        correctCount += 1;
      } else {
        incorrectCount += 1;
      }
    });
    _savePreferences();
  }

  void _startExam() {
    final count = _questionCountForDuration(examDurationMinutes);
    setState(() {
      examStarted = true;
      examQuestionCount = count;
      examQuestionIndex = 0;
      examCorrect = 0;
      examResultMessage = '';
      examAnswer = '';
      examAnswerController.text = '';
      examSecondsRemaining = examDurationMinutes * 60;
      showExamReview = false;
      examQuestions = _prepareExamQuestions(selectedSubject, examQuestionCount);
      examStudentAnswers = List.filled(examQuestionCount, '');
      examScores = List.filled(examQuestionCount, 0);
    });
    examTimer?.cancel();
    examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (examSecondsRemaining <= 0) {
        timer.cancel();
        _finishExam();
      } else {
        setState(() => examSecondsRemaining -= 1);
      }
    });
  }

  void _submitExamAnswer() {
    final answer = examAnswer.trim();
    final ideal = _currentExamQuestion.idealAnswer;
    final score = _gradeAnswer(answer, ideal);
    setState(() {
      examStudentAnswers[examQuestionIndex] = answer;
      examScores[examQuestionIndex] = score;
      if (score >= 3) examCorrect += 1;
      examResultMessage = 'Score: $score/5 ${_starsForScore(score)}';
      examQuestionIndex += 1;
      examAnswer = '';
      examAnswerController.text = '';
    });
    if (examQuestionIndex >= examQuestionCount) {
      _finishExam();
    }
  }

  void _finishExam() {
    examTimer?.cancel();
    setState(() {
      examStarted = false;
      showExamReview = true;
      examResultMessage =
          'Exam finished. You scored $examCorrect out of $examQuestionCount.';
    });
  }

  int _questionCountForDuration(int minutes) {
    return examDurationQuestionMap[minutes] ?? 5;
  }

  List<Question> _prepareExamQuestions(String subject, int count) {
    final questions = List<Question>.from(questionBank[subject] ?? []);
    questions.shuffle();
    return questions.take(count).toList();
  }

  Question get _currentExamQuestion => examQuestions.isEmpty
      ? _currentQuestion
      : examQuestions[examQuestionIndex];

  void _editExamAnswer(int index) {
    final controller = TextEditingController(text: examStudentAnswers[index]);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Fix your exam answer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Revised answer',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final revised = controller.text.trim();
                  final score =
                      _gradeAnswer(revised, examQuestions[index].idealAnswer);
                  setState(() {
                    examStudentAnswers[index] = revised;
                    examScores[index] = score;
                    examCorrect = examScores.where((s) => s >= 3).length;
                    examResultMessage =
                        'Review saved. Current score: $examCorrect out of $examQuestionCount.';
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save Revision'),
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }

  String _markingSchemeForSubject(String subject) {
    return subjectMarkingSchemes[subject] ??
        'Marks are awarded for clear explanation, correct terms, and good examples.';
  }

  void _toggleAiEnabled(bool enabled) {
    setState(() {
      aiEnabled = enabled;
      aiModeMessage = enabled
          ? 'AI mode is enabled. Ask any GCSE question safely.'
          : 'AI mode is disabled. Turn it on again when you want help.';
      if (!enabled) aiSuggestions = [];
    });
  }

  void _updateAiSuggestions(String value) {
    final prompt = value.trim().toLowerCase();
    if (prompt.isEmpty) {
      setState(() => aiSuggestions = []);
      return;
    }
    final keywordList = gcseKeywordLibrary[selectedSubject] ?? [];
    final matches = keywordList
        .where((keyword) => keyword.toLowerCase().contains(prompt))
        .take(5)
        .toList();
    setState(() => aiSuggestions = matches);
  }

  void _insertAiSuggestion(String suggestion) {
    final current = aiController.text.trim();
    final newText = current.isEmpty ? suggestion : '$current $suggestion';
    aiController.text = newText;
    aiController.selection = TextSelection.fromPosition(
      TextPosition(offset: aiController.text.length),
    );
    _updateAiSuggestions(newText);
  }

  Future<void> _sendAiQuestion() async {
    final prompt = aiController.text.trim();
    if (!aiEnabled || prompt.isEmpty) return;
    setState(() {
      aiMessages.add({'role': 'user', 'text': prompt});
      aiController.clear();
    });
    final response = await _fetchAiResponse(prompt);
    setState(() {
      aiMessages.add({'role': 'assistant', 'text': response});
    });
  }

  Future<String> _fetchAiResponse(String prompt) async {
    if (!_isSafeAiPrompt(prompt)) {
      return 'I can only answer safe GCSE questions. Please ask about school subjects like maths, science, English, or history.';
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/ai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply']?.toString() ?? 'The AI did not return a reply.';
      }

      return 'The AI backend could not reply. ' + _generateAiResponse(prompt);
    } catch (_) {
      return 'The AI backend is unavailable. ' + _generateAiResponse(prompt);
    }
  }

  String _generateAiResponse(String prompt) {
    final normalized = prompt.trim();
    if (normalized.isEmpty) {
      return 'Ask for a GCSE word meaning or concept, and I will explain it with a subject example.';
    }

    final lower = normalized.toLowerCase();
    final term = normalized
        .replaceAll(
            RegExp(r'^(what is|what are|define|explain)\s+',
                caseSensitive: false),
            '')
        .trim();

    final subjectExamples = {
      'Math':
          'For example, in math, "$term" can be used when you show your working clearly in a problem.',
      'English':
          'For example, in English, "$term" can be used when explaining a text or writing about a poem.',
      'Science':
          'For example, in science, "$term" can describe a process or a scientific idea in a report.',
      'History':
          'For example, in history, use "$term" to describe events, dates, or the reasons people acted as they did.',
      'Geography':
          'For example, in geography, "$term" can explain landscapes, weather, or how people use resources.',
      'Computer Science':
          'For example, in computer science, "$term" can describe how a program, system, or data works.',
      'Biology':
          'For example, in biology, "$term" can describe living things, cells, or how organisms behave.',
      'Chemistry':
          'For example, in chemistry, "$term" can describe atoms, reactions, or substances in a lab.',
      'Physics':
          'For example, in physics, "$term" can describe forces, energy, or how objects move.',
      'French':
          'For example, in French, "$term" can be used to explain a word or phrase in a short sentence.',
      'Spanish':
          'For example, in Spanish, "$term" can be used to describe a word or idea in a sentence.',
      'Art':
          'For example, in art, "$term" can describe materials, style, or the feeling behind a picture.',
      'Music':
          'For example, in music, "$term" can describe sound, rhythm, or a performance idea.',
      'PE':
          'For example, in PE, "$term" can describe fitness, skills, or a health idea.',
      'Business':
          'For example, in business, "$term" can describe how companies, money, or customers work together.',
      'Economics':
          'For example, in economics, "$term" can describe money, markets, or choices people make.',
      'Psychology':
          'For example, in psychology, "$term" can describe behaviour, thoughts, or feelings.',
      'Religious Studies':
          'For example, in religious studies, "$term" can describe beliefs, practices, or ethical ideas.',
      'Design Tech':
          'For example, in design technology, "$term" can describe a product, plan, or how something is made.',
      'Drama':
          'For example, in drama, "$term" can describe a character, emotion, or how a scene is performed.',
    };

    final example = subjectExamples[selectedSubject] ??
        'For example, in $selectedSubject, "$term" can be used in a sentence related to the subject.';

    final definitions = {
      'gravity':
          'Gravity is the force that pulls objects toward Earth and keeps planets in orbit.',
      'photosynthesis':
          'Photosynthesis is how plants use sunlight, water, and carbon dioxide to make food.',
      'atom':
          'An atom is the smallest part of an element and is made of protons, neutrons, and electrons.',
      'formula':
          'A formula is a mathematical rule or relationship shown using symbols.',
      'perimeter': 'Perimeter is the distance around the edge of a shape.',
      'area': 'Area is the amount of space inside a shape.',
      'proportion':
          'Proportion compares the relative size of two or more quantities.',
      'percent':
          'Percent is a way to show parts per hundred using the % symbol.',
      'metaphor':
          'A metaphor is a comparison that describes one thing as if it were another.',
      'adjective': 'An adjective is a word that describes a noun.',
      'conclusion':
          'A conclusion is the final part of an answer that sums up the main points.',
      'economics':
          'Economics is the study of how people use resources and make choices.',
      'business':
          'Business is the activity of buying, selling, and managing goods or services.',
      'cell':
          'A cell is the smallest unit of life that makes up plants and animals.',
      'function': 'A function is what something is used for or what it does.',
      'belief': 'A belief is an idea that someone thinks is true.',
      'script': 'A script is the written words actors say in a play.',
    };

    if (definitions.containsKey(term.toLowerCase())) {
      return '${definitions[term.toLowerCase()]} $example';
    }

    if (lower.contains('what is') ||
        lower.contains('what are') ||
        lower.contains('define')) {
      return 'The term "$term" means something important in GCSE work. $example';
    }
    if (lower.contains('how') ||
        lower.contains('why') ||
        lower.contains('explain')) {
      return 'A good answer explains the idea clearly. $example';
    }

    return 'If you want a GCSE word meaning, type a term such as "define proportion" or "what is gravity". $example';
  }

  bool _isSafeAiPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    const blocked = [
      'kill',
      'die',
      'suicide',
      'harm',
      'attack',
      'weapon',
      'gun',
      'bomb',
      'violence',
      'drugs',
      'sex',
      'porn',
      'hate',
      'racist',
      'terror',
    ];
    return !blocked.any(lower.contains);
  }

  int _gradeAnswer(String answer, String ideal) {
    final normalizedAnswer = _normalizeText(answer);
    final normalizedIdeal = _normalizeText(ideal);
    if (normalizedAnswer.isEmpty) return 0;
    final answerWords = normalizedAnswer.split(' ').toSet();
    final idealWords = normalizedIdeal.split(' ').toSet();
    final common = answerWords.intersection(idealWords).length;
    final total = idealWords.isEmpty ? 1 : idealWords.length;
    final overlap = common / total;
    final distance = _normalizedLevenshtein(normalizedAnswer, normalizedIdeal);
    final score = (overlap * 0.6 + (1 - distance) * 0.4) * 5;
    return score.clamp(0, 5).round();
  }

  double _normalizedLevenshtein(String a, String b) {
    if (a == b) return 0.0;
    final n = a.length, m = b.length;
    if (n == 0) return 1.0;
    if (m == 0) return 1.0;
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (var i = 0; i <= n; i++) dp[i][0] = i;
    for (var j = 0; j <= m; j++) dp[0][j] = j;
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost]
            .reduce((v, e) => v < e ? v : e);
      }
    }
    return dp[n][m] / max(n, m);
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _starsForScore(int score) {
    return '★' * score + '☆' * (5 - score);
  }

  String _appModeLabel(AppMode mode) {
    switch (mode) {
      case AppMode.practice:
        return 'Practice';
      case AppMode.quiz:
        return 'Quiz';
      case AppMode.examPractice:
        return 'Exam Practice';
      case AppMode.aiHelp:
        return 'AI Help';
      case AppMode.videoSearch:
        return 'Video Search';
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;
    final subjectColor = subjectColors[selectedSubject] ?? Colors.deepPurple;
    final totalAnswered = correctCount + incorrectCount;
    final accuracy =
        totalAnswered == 0 ? 0 : (correctCount / totalAnswered * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GCSE Question Bank'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [subjectColor.withOpacity(0.08), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileCard(subjectColor),
                    const SizedBox(height: 16),
                    _buildModeSelector(subjectColor),
                    const SizedBox(height: 16),
                    _buildSubjectSelector(),
                    const SizedBox(height: 20),
                    _buildPracticeCard(question, subjectColor),
                    const SizedBox(height: 18),
                    _buildStatsCard(subjectColor, accuracy),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: AiChatWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Color subjectColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: subjectColor.withOpacity(0.16),
              child: Icon(avatarIcons[selectedAvatarIndex],
                  color: subjectColor, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName.isNotEmpty ? userName : 'Student',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(userTitle,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(_appModeLabel(appMode)),
                        backgroundColor: subjectColor.withOpacity(0.14),
                      ),
                      Chip(
                        label: Text(selectedSubject),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showProfileEditor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(Color subjectColor) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppMode.values.map((mode) {
        final selected = appMode == mode;
        return ChoiceChip(
          label: Text(_appModeLabel(mode)),
          selected: selected,
          selectedColor: subjectColor.withOpacity(0.3),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: selected ? subjectColor : Colors.black87,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
          onSelected: (_) => _setAppMode(mode),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      children: subjects.map((subject) {
        final selected = subject == selectedSubject;
        final color = subjectColors[subject] ?? Colors.deepPurple;
        return ChoiceChip(
          label: Text(subject),
          selected: selected,
          selectedColor: color.withOpacity(0.26),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(color: selected ? color : Colors.black87),
          onSelected: (_) => _selectSubject(subject),
        );
      }).toList(),
    );
  }

  Widget _buildPracticeCard(Question question, Color subjectColor) {
    switch (appMode) {
      case AppMode.practice:
        return _buildPracticeMode(question, subjectColor);
      case AppMode.quiz:
        return _buildQuizMode(question, subjectColor);
      case AppMode.examPractice:
        return _buildExamPracticeMode(question, subjectColor);
      case AppMode.aiHelp:
        return _buildAiHelpMode(subjectColor);
      case AppMode.videoSearch:
        return _buildVideoSearchMode(subjectColor);
    }
  }

  Widget _buildPracticeMode(Question question, Color subjectColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Practice Mode', subjectColor),
            const SizedBox(height: 14),
            _buildQuestionPickerRow(subjectColor),
            const SizedBox(height: 14),
            _buildQuestionImage(question.imageUrl),
            const SizedBox(height: 14),
            Text(question.text,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Hint'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: subjectColor),
                  onPressed: _showHint,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Ideal Answer'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: subjectColor),
                  onPressed: _showAnswer,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Question'),
                  onPressed: _chooseRandomQuestion,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (showHint)
              _buildRevealCard('Hint', question.hint, Colors.amber.shade100),
            if (showAnswer)
              _buildRevealCard('Ideal Answer', question.idealAnswer,
                  Colors.lightBlue.shade50),
            if (!showHint && !showAnswer)
              const Text(
                  'Reveal the hint or ideal answer below, then write your own answer to practise.',
                  style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            TextField(
              controller: userAnswerController,
              maxLines: 4,
              onChanged: (value) => setState(() => userAnswer = value),
              decoration: InputDecoration(
                labelText: 'Your answer',
                hintText: 'Type your response here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.assessment),
              label: const Text('Check Answer'),
              onPressed: () {
                final score = _gradeAnswer(userAnswer, question.idealAnswer);
                setState(() {
                  lastAnswerScore = score;
                  lastAnswerStars = _starsForScore(score);
                  lastAnswerFeedback = score >= 4
                      ? 'Great answer!'
                      : score >= 2
                          ? 'Good attempt, refine it.'
                          : 'Keep working on the key terms.';
                  quizFeedback = 'Score: $score/5 $lastAnswerStars';
                });
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Answer'),
                    onPressed: () {
                      setState(() {
                        savedAnswers[_questionId] = userAnswer;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Correct'),
                    onPressed: _markCorrect,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Mark Incorrect'),
              onPressed: _markIncorrect,
            ),
            if (savedAnswers.containsKey(_questionId))
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text('Saved answer: ${savedAnswers[_questionId]}',
                    style: const TextStyle(color: Colors.black87)),
              ),
            if (lastAnswerScore > 0)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _buildRevealCard(
                    'Answer score',
                    'Score: $lastAnswerScore/5 $lastAnswerStars - $lastAnswerFeedback',
                    Colors.green.shade50),
              ),
            if (quizFeedback.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _buildRevealCard(
                    'Feedback', quizFeedback, Colors.green.shade50),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizMode(Question question, Color subjectColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Quiz Mode', subjectColor),
            const SizedBox(height: 14),
            _buildQuestionPickerRow(subjectColor),
            const SizedBox(height: 14),
            _buildQuestionImage(question.imageUrl),
            const SizedBox(height: 14),
            Text(question.text,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            TextField(
              controller: userAnswerController,
              maxLines: 4,
              onChanged: (value) => setState(() => userAnswer = value),
              decoration: InputDecoration(
                labelText: 'Answer for quiz',
                hintText: 'Write your response and submit.',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Submit Answer'),
              style: ElevatedButton.styleFrom(backgroundColor: subjectColor),
              onPressed: _submitQuizAnswer,
            ),
            const SizedBox(height: 12),
            if (quizFeedback.isNotEmpty)
              _buildRevealCard(
                  'Quiz feedback', quizFeedback, Colors.green.shade50),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.skip_next),
              label: const Text('Next Quiz Question'),
              onPressed: () {
                _chooseRandomQuestion();
                setState(() => quizFeedback = '');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamPracticeMode(Question question, Color subjectColor) {
    final currentQuestion = examStarted ? _currentExamQuestion : question;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Exam Practice', subjectColor),
            const SizedBox(height: 14),
            if (!examStarted) ...[
              const Text(
                  'Choose how long your test will be, then start exam practice.',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: examDurationQuestionMap.keys.map((minutes) {
                  final selected = examDurationMinutes == minutes;
                  return ChoiceChip(
                    label: Text('$minutes mins'),
                    selected: selected,
                    selectedColor: subjectColor.withOpacity(0.22),
                    onSelected: (_) =>
                        setState(() => examDurationMinutes = minutes),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Approx ${_questionCountForDuration(examDurationMinutes)} questions for ${examDurationMinutes} minutes.',
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                icon: const Icon(Icons.timer),
                label: const Text('Start Exam Practice'),
                onPressed: _startExam,
              ),
              if (examResultMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRevealCard(
                    'Last exam score', examResultMessage, Colors.blue.shade50),
              ],
              if (showExamReview && examQuestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildExamReviewSheet(subjectColor),
              ],
            ] else ...[
              _buildQuestionImage(currentQuestion.imageUrl),
              const SizedBox(height: 14),
              Text('Question ${examQuestionIndex + 1} of $examQuestionCount',
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 10),
              Text(currentQuestion.text,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Text('Time left: ${examSecondsRemaining}s',
                  style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 14),
              TextField(
                controller: examAnswerController,
                maxLines: 4,
                onChanged: (value) => setState(() => examAnswer = value),
                decoration: InputDecoration(
                  labelText: 'Exam response',
                  hintText: 'Write your exam-style answer here.',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.flag),
                label: Text(examQuestionIndex + 1 < examQuestionCount
                    ? 'Submit and Next'
                    : 'Submit and Finish'),
                style: ElevatedButton.styleFrom(backgroundColor: subjectColor),
                onPressed: _submitExamAnswer,
              ),
              const SizedBox(height: 12),
              if (examResultMessage.isNotEmpty)
                _buildRevealCard(
                    'Exam progress', examResultMessage, Colors.blue.shade50),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiHelpMode(Color subjectColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Word Meaning Helper', subjectColor),
            const SizedBox(height: 10),
            const Text(
              'Ask for a word meaning or GCSE concept and see an example sentence for the selected subject.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Enable AI Mode'),
              subtitle: const Text('Toggle AI help on or off.'),
              value: aiEnabled,
              activeColor: subjectColor,
              onChanged: _toggleAiEnabled,
            ),
            const SizedBox(height: 12),
            Text(
              aiModeMessage,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: aiMessages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Your AI responses will appear here once you submit a question.',
                          style: TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: aiMessages.length,
                      itemBuilder: (context, index) {
                        final message = aiMessages[index];
                        final isUser = message['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? subjectColor.withOpacity(0.18)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(message['text'] ?? '',
                                style: const TextStyle(fontSize: 15)),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: aiController,
              maxLines: 3,
              enabled: aiEnabled,
              onChanged: aiEnabled ? _updateAiSuggestions : null,
              decoration: InputDecoration(
                labelText:
                    aiEnabled ? 'Type a GCSE word or concept' : 'Helper is off',
                hintText: aiEnabled
                    ? 'e.g. define proportion in science'
                    : 'Enable the helper to ask',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (aiSuggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: aiSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _insertAiSuggestion(suggestion),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Submit Question'),
              style: ElevatedButton.styleFrom(backgroundColor: subjectColor),
              onPressed: aiEnabled ? _sendAiQuestion : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamReviewSheet(Color subjectColor) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exam Review Sheet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: subjectColor)),
            const SizedBox(height: 10),
            Text(
              'Subject marking scheme: ${_markingSchemeForSubject(selectedSubject)}',
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: examQuestions.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final question = examQuestions[index];
                  final studentAnswer = examStudentAnswers[index];
                  final score = examScores[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question ${index + 1}:',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(question.text, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 10),
                      Text(
                          'Your answer: ${studentAnswer.isEmpty ? 'No answer provided' : studentAnswer}',
                          style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text('Perfect answer: ${question.idealAnswer}',
                          style: const TextStyle(color: Colors.blueGrey)),
                      const SizedBox(height: 6),
                      Text('Question score: $score/5 ${_starsForScore(score)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => _editExamAnswer(index),
                        child: const Text('Fix this answer'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSearchMode(Color subjectColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Study Video Search', subjectColor),
            const SizedBox(height: 14),
            const Text(
                'Search YouTube for study videos without leaving the app.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            TextField(
              controller: videoSearchController,
              onChanged: (value) => setState(() => videoSearchQuery = value),
              decoration: InputDecoration(
                labelText: 'Video search',
                hintText: 'Enter a topic or subject...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text('Search YouTube'),
              style: ElevatedButton.styleFrom(backgroundColor: subjectColor),
              onPressed: () {
                final query = videoSearchQuery.isEmpty
                    ? '$selectedSubject GCSE study'
                    : videoSearchQuery;
                _openYoutubeSearch(query);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openYoutubeSearch(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final url = 'https://www.youtube.com/results?search_query=$encoded';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
    );
  }

  Widget _buildQuestionImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        imageUrl,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 190,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRevealCard(String title, String content, Color backgroundColor) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Color subjectColor, int accuracy) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lifetime Stats',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: subjectColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                _buildStatTile('Questions seen', totalAsked.toString(),
                    Icons.auto_stories, Colors.indigo),
                _buildStatTile('Hints used', hintsUsed.toString(),
                    Icons.lightbulb, Colors.amber),
                _buildStatTile('Answers viewed', answersViewed.toString(),
                    Icons.visibility, Colors.blue),
                _buildStatTile('Correct', correctCount.toString(),
                    Icons.check_circle, Colors.green),
                _buildStatTile('Incorrect', incorrectCount.toString(),
                    Icons.cancel, Colors.red),
                _buildStatTile('Accuracy', '$accuracy%', Icons.show_chart,
                    Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
                'Save your own answers, switch modes, or ask AI for help when you need it.',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
      String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: color.withOpacity(0.16),
              child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
