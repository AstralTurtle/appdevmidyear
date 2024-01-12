import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:async';

import 'package:path/path.dart';

import 'package:sqflite/sqflite.dart';

import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

// ...

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TodoList(title: 'Todo List'),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<Todo> _todos = [];
  DatabaseHelper dbHelper = DatabaseHelper();
  APIHelper apiHelper = APIHelper();
  @override
  void initState() {
    // apiHelper.gsi.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
    //   apiHelper.getCourseWork();
    //   print(account);
    // });

    dbHelper = DatabaseHelper()
      ..initDB().whenComplete(() => print("DB initalized"));
    apiHelper = APIHelper();

    dbHelper.initDB().whenComplete(() async {
      apiHelper.loadTestData().whenComplete(() {
        setState(() {});
      });
      dbHelper.retrieveTasks().then((value) {
        setState(() {
          _todos.addAll(value);
        });
      });
    });

    apiHelper.auth().whenComplete(() async {
      setState(() {});
    });

    // DatabaseHelper.instance.retrieveUsers().then((value) {
    //   setState(() {
    //     _todos.addAll(value);
    //   });
    // });
    super.initState();
  }

  final TextEditingController _textFieldController = TextEditingController();

  void _addTodoItem(String name) {
    Todo newTodo = Todo(
      name: name,
      completed: false,
    );
    DatabaseHelper.instance.insertTask(newTodo).then((value) {
      newTodo.setID(value);
      _todos.add(newTodo);
      setState(
        () {},
      );
    });

    _textFieldController.clear();
  }

  Future<void> _displayDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a todo'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Type your todo'),
            autofocus: true,
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _addTodoItem(_textFieldController.text);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _handleTodoChange(Todo todo) {
    setState(() {
      todo.completed = !todo.completed;
      DatabaseHelper.instance.updateTask(todo);
    });
  }

  void _deleteTodo(Todo todo) {
    setState(() {
      _todos.removeWhere((element) => element.name == todo.name);
      DatabaseHelper.instance.deleteTask(todo.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: _todos.map((Todo todo) {
            return TodoItem(
                todo: todo,
                onTodoChanged: _handleTodoChange,
                removeTodo: _deleteTodo);
          }).toList(),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        // onPressed: () => _displayDialog(context),
        onPressed: () {
          _displayDialog(context).whenComplete(() => setState(() {}));
        },
        tooltip: 'Make ToDo',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Todo {
  Todo({required this.name, required this.completed});

  Todo.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        name = res["name"],
        completed = (res["completed"] == 1);

  int? id;
  String name;
  bool completed;

  void setID(int id) {
    this.id = id;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'completed': completed ? 1 : 0,
    };
  }

  Map<String, dynamic> toMapWithID() {
    return {
      'id': id,
      'name': name,
      'completed': completed ? 1 : 0,
    };
  }
}

class TodoItem extends StatelessWidget {
  TodoItem(
      {required this.todo,
      required this.onTodoChanged,
      required this.removeTodo})
      : super(key: ObjectKey(todo));

  final void Function(Todo todo) onTodoChanged;
  final void Function(Todo todo) removeTodo;

  final Todo todo;

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTodoChanged(todo);
      },
      leading: Checkbox(
        checkColor: Colors.greenAccent,
        activeColor: Colors.red,
        value: todo.completed,
        onChanged: (value) {
          onTodoChanged(todo);
        },
      ),
      title: Row(children: <Widget>[
        Expanded(
          child: Text(todo.name, style: _getTextStyle(todo.completed)),
        ),
        IconButton(
          iconSize: 30,
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          alignment: Alignment.centerRight,
          onPressed: () {
            removeTodo(todo);
          },
        ),
      ]),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init() {}

  late Database db;

  factory DatabaseHelper() => instance;

  Future<void> initDB() async {
    String path = await getDatabasesPath();
    db = await openDatabase(
      join(path, 'tasks.db'),
      onCreate: (database, version) async {
        await database.execute(
          """
            CREATE TABLE tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              name TEXT NOT NULL,
              completed INTEGER NOT NULL
            )
          """,
        );
      },
      version: 1,
    );
  }

  Future<int> insertTask(Todo task) async {
    int result = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> updateTask(Todo task) async {
    int result = await db.update(
      'tasks',
      task.toMap(),
      where: "id = ?",
      whereArgs: [task.id],
    );
    return result;
  }

  Future<List<Todo>> retrieveTasks() async {
    final List<Map<String, Object?>> queryResult = await db.query('tasks');
    return queryResult.map((e) => Todo.fromMap(e)).toList();
  }

  Future<void> deleteTask(int id) async {
    await db.delete(
      'tasks',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> deleteDB() async {
    await deleteDatabase(join(await getDatabasesPath(), 'tasks.db'));
  }
}

class APIHelper {
  // I've spent 22 hours over 3 days trying to get this to work my teacher said i can use test data from api explorer
  // load test data from local json files
  loadTestData() async {
    rootBundle.loadString('assets/json/testAssignments.json').then((value) {
      JsonDecoder decoder = JsonDecoder();
      // convert internal maps

      Map<String, dynamic> assignments = decoder.convert(value);
      List<Map<String, dynamic>> temp = [];

      // Accessing the "courseWork" array
      List<dynamic> courseWorkList = assignments['courseWork'];

      // Convert the "courseWork" array to a list of maps

      for (Map<String, dynamic> courseWork in courseWorkList) {
        // Add each courseWork object to the list
        temp.add(courseWork);
      }

      // print(temp);
      List<Todo> todos = makeTodos(temp);
      for (var todo in todos) {
        DatabaseHelper.instance.insertTask(todo).then((value) {
          todo.setID(value);
        });
      }
    });
    // rootBundle.loadString('assets/json/testCourses.json').then((value) {
    //   print(value);
    // });
  }

  List<Todo> makeTodos(List<Map<String, dynamic>> assignments) {
    List<Todo> todos = [];
    // JsonDecoder decoder = JsonDecoder();
    for (var assignment in assignments) {
      if (assignment["dueTime"]["hours"] < 168) {
        // if due in a week or less
        todos.add(Todo(
          name: assignment["title"],
          completed: false,
        ));
      }
    }
    return todos;
  }

  // should be a secret but this ain't production
  static String clientID =
      "550994012595-3eoa3vv5v9car4qsnm9kli5843kmvkt5.apps.googleusercontent.com";

  static final APIHelper instance = APIHelper._init();

  static const List<String> scopes = [
    // ClassroomApi.classroomCoursesReadonlyScope,
    // ClassroomApi.classroomCourseworkMeReadonlyScope,
    "https://www.googleapis.com/auth/classroom.courses.readonly",
    "https://www.googleapis.com/auth/classroom.course-work.readonly",
    "https://www.googleapis.com/auth/classroom.student-submissions.students.readonly",
    "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly"
  ];

  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: scopes, clientId: clientID);
  AuthClient? _client;

  get gsi => _googleSignIn;

  APIHelper._init();

  factory APIHelper() => instance;

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> auth() async {
    try {
      _googleSignIn = GoogleSignIn(scopes: scopes, serverClientId: clientID);
      _handleSignIn();
      _client = await _googleSignIn.authenticatedClient();
    } catch (err) {
      print(err);
    }
  }

  getCourses() async {
    // use https bc googleapis sucks ig idk

    // Uri uri = Uri.https("classroom.googleapis.com", "/v1/courses", {
    //   "courseStates": "ACTIVE",
    //   "studentId": " aaronj104@nyctudents.net",
    //   "Authorization": "Bearer ${} "
    // });
    // http.get(uri).then((value) => print(value.body));
  }

  getCourseWork() async {
    assert(_client != null, 'Authenticated client missing!');
    final ClassroomApi classroomApi = ClassroomApi(_client!);
    final ListCoursesResponse response = await classroomApi.courses.list();
    print(response.toString());
  }
}
