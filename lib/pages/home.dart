// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global/global.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> todos = [Todo(title: "")];
  List<Reminder> reminders = [];
  List<Note> notes = [];
  TextEditingController todoControler = TextEditingController();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Widget todoTile(String task, bool isCompleted) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            width: 10,
          ),
          Icon(isCompleted ? Icons.check : Icons.rectangle_outlined),
          SizedBox(
            width: 15,
          ),
          Text(
            task,
            style: TextStyle(
              decoration: isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget remindTile(String remind) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            width: 10,
          ),
          Icon(Icons.check),
          SizedBox(
            width: 15,
          ),
          Text(
            remind,
          ),
        ],
      ),
    );
  }

  Widget noteTile(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    checkNotificationPermission();
    _loadTodos();
    _loadReminders();
    _loadNotes();
    initializeNotifications();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  void initializeNotifications() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> checkNotificationPermission() async {
    // Check if the notification permission is already granted.
    PermissionStatus status = await Permission.notification.status;

    if (!status.isGranted) {
      // If the permission is not granted, ask the user for permission.
      await Permission.notification.request();
    }
  }

  _loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      final todoList = prefs.getStringList('todos');
      todos = todoList != null
          ? todoList
              .map((item) =>
                  Todo.fromMap(Map<String, dynamic>.from(jsonDecode(item))))
              .toList()
          : [];
    });
  }

  _saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todoStrings =
        todos.map((todo) => jsonEncode(todo.toMap())).toList();
    prefs.setStringList('todos', todoStrings);
  }

  _addTodo() {
    setState(() {
      final newTodo = Todo(
        title: todoControler.text,
      );
      todos.add(newTodo);
      todoControler.clear();
      _saveTodos();
    });
  }

  _toggleTodoCompleted(int index) {
    setState(() {
      todos[index].isCompleted = !todos[index].isCompleted;
      _saveTodos();
    });
  }

  _removeTodo(int index) {
    setState(() {
      todos.removeAt(index);
      _saveTodos();
    });
  }

  _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor:
              Colors.greenAccent.shade100, // Set the desired background color
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: todoControler,
                  decoration: InputDecoration(
                    hintText: 'Enter a task',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Add'),
                      onPressed: () {
                        _addTodo();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      final reminderList = prefs.getStringList('reminders');
      reminders = reminderList != null
          ? reminderList
              .map((item) =>
                  Reminder.fromMap(Map<String, dynamic>.from(jsonDecode(item))))
              .toList()
          : [];
    });
  }

  _saveReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> reminderStrings =
        reminders.map((reminder) => jsonEncode(reminder.toMap())).toList();
    prefs.setStringList('reminders', reminderStrings);
  }

  _removeReminder(int index) {
    setState(() {
      reminders.removeAt(index);
      _saveReminders();
    });
  }

  _showAddReminderDialog(BuildContext context) async {
    TimeOfDay selectedTime = TimeOfDay.now();
    TextEditingController titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orangeAccent.shade100,
          title: Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (time != null) {
                    setState(() {
                      selectedTime = time;
                    });
                  }
                },
                child: Text('Select Time'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Reminder Title'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  _saveReminders();
                  _addReminder(titleController.text.trim(), selectedTime);

                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addReminder(String title, TimeOfDay time) async {
    final now = DateTime.now();
    DateTime reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    tz.TZDateTime scheduledDateTime = tz.TZDateTime(
      tz.getLocation("Asia/Kolkata"),
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(Duration(days: 1));
    }

    setState(() {
      final newReminder = Reminder(
        title: title,
        time: time,
      );
      reminders.add(newReminder);
      _saveReminders();
      _scheduleNotification(title, scheduledDateTime);
    });
  }

  Future<void> _scheduleNotification(String title, tz.TZDateTime time) async {
    final notificationId = reminders.length; // Unique ID for each notification

    final now = DateTime.now();
    DateTime reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(Duration(days: 1));
    }

    // Define the notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'my_app_channel_01', // Use the same channel ID here
      'My App Notifications', // Replace with your channel name
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      "",
      time,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(Reminder reminder) async {
    await flutterLocalNotificationsPlugin.cancel(reminder.hashCode);
  }

  _showAddNoteDialog(BuildContext context) {
    String newNoteTitle = '';
    String newNoteBody = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.redAccent.shade100,
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  onChanged: (value) {
                    newNoteTitle = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter a title',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  onChanged: (value) {
                    newNoteBody = value;
                  },
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter the note',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Add'),
                      onPressed: () {
                        _addNote(newNoteTitle, newNoteBody);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _addNote(String title, String body) {
    setState(() {
      final newNote = Note(
        title: title,
        body: body,
      );
      notes.add(newNote);
      _saveNotes();
    });
  }

  _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      final noteList = prefs.getStringList('notes');
      notes = noteList != null
          ? noteList
              .map((item) =>
                  Note.fromMap(Map<String, dynamic>.from(jsonDecode(item))))
              .toList()
          : [];
    });
  }

  _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> noteStrings =
        notes.map((note) => jsonEncode(note.toMap())).toList();
    prefs.setStringList('notes', noteStrings);
  }

  _showNoteDetailsDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.redAccent.shade100,
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.0),
                SelectableText(
                  body,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _removeNote(int index) {
    setState(() {
      notes.removeAt(index);
      _saveTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent.shade100.withOpacity(0.5),
        title: Text("Daily Dose"),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.50,
                  width: MediaQuery.of(context).size.width * 0.47,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                        "TO-DO",
                      ),
                    ),
                    body: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.greenAccent.shade100.withOpacity(0.5),
                      ),
                      child: ListView.builder(
                        itemCount: todos.length,
                        itemBuilder: (BuildContext context, int index) {
                          final todo = todos[index];
                          return ListTile(
                            visualDensity:
                                VisualDensity(horizontal: 0, vertical: -4),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: Dismissible(
                              key: Key(todo.title),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                color: Colors.red,
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                _removeTodo(index);
                              },
                              child: Checkbox(
                                activeColor: Colors.green,
                                value: todo.isCompleted,
                                onChanged: (value) =>
                                    _toggleTodoCompleted(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerFloat,
                    floatingActionButton: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      height: 35,
                      width: double.infinity,
                      child: FloatingActionButton(
                        onPressed: () {
                          _showAddTaskDialog(context);
                        },
                        child: Text(
                          "Add task",
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width * 0.47,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                        "Reminders",
                      ),
                    ),
                    body: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.orange,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.orangeAccent.shade100.withOpacity(0.5),
                      ),
                      child: ListView.builder(
                        itemCount: reminders.length,
                        itemBuilder: (BuildContext context, int index) {
                          final reminder = reminders[index];
                          return ListTile(
                            splashColor: Colors.red,
                            visualDensity:
                                VisualDensity(horizontal: 0, vertical: -4),
                            title: Text(
                              reminder.title,
                              style: TextStyle(fontSize: 18),
                            ),
                            trailing: Dismissible(
                              key: Key(
                                reminder.title,
                              ),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                color: Colors.red,
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                _removeReminder(index);
                              },
                              child: Container(
                                height: 25,
                                padding: EdgeInsets.only(right: 10),
                                child: Text(
                                  '${reminder.time.hourOfPeriod.toString()}:${reminder.time.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerFloat,
                    floatingActionButton: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      height: 35,
                      width: double.infinity,
                      child: FloatingActionButton(
                        onPressed: () {
                          _showAddReminderDialog(context);
                        },
                        child: Text(
                          "Add reminder",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              width: MediaQuery.of(context).size.width,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    "Notes",
                  ),
                ),
                body: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.redAccent.shade100.withOpacity(0.5),
                  ),
                  child: ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (BuildContext context, int index) {
                      final note = notes[index];
                      return ListTile(
                        onTap: () {
                          _showNoteDetailsDialog(
                              context, note.title, note.body);
                        },
                        visualDensity:
                            VisualDensity(horizontal: 0, vertical: -4),
                        title: Text(
                          note.title,
                          style: TextStyle(fontSize: 18),
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            _removeNote(index);
                          },
                          child: Container(
                            width: 48, // Set a fixed width for the container
                            alignment: Alignment.center,
                            child: Icon(Icons.delete),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
                floatingActionButton: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  height: 35,
                  width: double.infinity,
                  child: FloatingActionButton(
                    onPressed: () {
                      _showAddNoteDialog(context);
                    },
                    child: Text(
                      "Add New Note",
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
