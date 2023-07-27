import 'package:flutter/material.dart';

class Todo {
  final String title;
  bool isCompleted;

  Todo({
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  static Todo fromMap(Map<String, dynamic> map) {
    return Todo(
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class Reminder {
  String title;
  TimeOfDay time;

  Reminder({required this.title, required this.time});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      title: map['title'],
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
    );
  }
}

class Note {
  String title;
  String body;

  Note({
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'],
      body: map['body'],
    );
  }
}
