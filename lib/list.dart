import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid.toString();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ListScreenArguments;
    final listId = args.listId;
    final Stream<DocumentSnapshot> _listStream = FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).snapshots();

    return StreamBuilder(
        stream: _listStream,
        builder: (BuildContext contextStream, AsyncSnapshot<DocumentSnapshot> snapshot){
          if(snapshot.hasError) return Text('Something went wrong');
          if(snapshot.connectionState == ConnectionState.waiting) return Text('Loading');
          var taskIndex = 0;
          final List<TaskObject> tasks = List.from(snapshot.data!.get('tasks')).map((task){
            var text = task['text'] ?? "";
            var done = task['done'] ?? "";
            return new TaskObject(id: taskIndex++, text: text, done: done);
          }).toList();

          return Scaffold(
            appBar: AppBar(
              title: new Text((snapshot.data!.data() as Map)['name']),
            ),
            body: ListView(
              children: tasks.map((TaskObject task){
                return Card(
                  child: CheckboxListTile(
                    title: Text(task.text),
                    subtitle: Text('test'),
                    value: task.done,
                    onChanged: (bool? newValue) async {
                      print(tasks);
                      // List<dynamic> list = List.from(snapshot.data!.get('tasks') as List);
                      // list.add(uid);
                      // FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).update({'t': 't'});
                    },
                  ),
                );
              }).toList()
            ),
          );
        }
    );
  }
}

class ListScreenArguments{
  final String listId;

  ListScreenArguments(this.listId);
}

class ListObject {
  ListObject({required this.name, required this.tasks});

  ListObject.fromJson(Map<String, Object?> json)
      : this(
    name: json['name']! as String,
    tasks: json['tasks']! as List<TaskObject>,
  );

  final String name;
  final List<TaskObject> tasks;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'tasks': tasks,
    };
  }
}

class TaskObject {
  TaskObject({required this.id, required this.text, required this.done});

  TaskObject.fromJson(Map<String, Object?> json)
      : this(
    text: json['text']! as String,
    done: json['done']! as bool,
    id: json['id']! as int,
  );

  final String text;
  late final bool done;
  final int id;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'text': text,
      'done': done,
    };
  }

  String toString(){
    return '[' + id.toString() + ']' + text + (done ? ' ✓' : ' -');
  }
}
