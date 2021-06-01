import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
          final ListObject taskList = ListObject(id: listId, name: snapshot.data!.get('name'), tasks: tasks);

          return Scaffold(
            appBar: AppBar(
              title: new Text(taskList.name),
              actions: [
                IconButton(onPressed: () async {
                  final _newNameController = TextEditingController();
                  _newNameController.text = taskList.name;
                  return showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Set a new list name'),
                          content: TextField(
                            autofocus: true,
                            controller: _newNameController,
                          ),
                          actions: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 16, bottom: 8),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor: Colors.blue,
                                  onSurface: Colors.grey,
                                ),
                                child: Text('Rename'),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).update({'name': _newNameController.text});
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        );
                      });
                }, icon: Icon(Icons.drive_file_rename_outline))
              ],
            ),
            body: ReorderableListView(
              onReorder: (int oldIndex, int newIndex) {
                taskList.taskMove(oldIndex, newIndex);
                FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).update({'tasks': taskList.toUpdate()});
              },
              children: tasks.map((TaskObject task){
                return Slidable(
                  key: UniqueKey(),
                  actionPane: SlidableDrawerActionPane(),
                  actionExtentRatio: 0.25,
                  child: Container(
                    color: Colors.white,
                    child: Card(
                      child: CheckboxListTile(
                        title: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(task.text),
                        ),
                        value: task.done,
                        onChanged: (bool? newValue) async {
                          // print(taskList);
                          taskList.taskDone(task.id);
                          FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).update({'tasks': taskList.toUpdate()});
                        },
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    IconSlideAction(
                      caption: 'Edit',
                      color: Colors.blue,
                      icon: Icons.drive_file_rename_outline,
                      onTap: (){
                        TextEditingController _editTaskController = TextEditingController();
                        _editTaskController.text = task.text;
                        showDialog(
                            context: context,
                            builder: (_) => new AlertDialog(
                              title: new Text("Edit task"),
                              content: TextField(
                                autofocus: true,
                                controller: _editTaskController,
                                maxLines: null,
                              ),
                              actions: <Widget>[
                                TextButton(
                                  style: TextButton.styleFrom(
                                    primary: Colors.white,
                                    backgroundColor: Colors.blue,
                                    onSurface: Colors.grey,
                                  ),
                                  child: Text('Edit'),
                                  onPressed: () {
                                    taskList.taskEdit(task.id, _editTaskController.text);
                                    FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).update({'tasks': taskList.toUpdate()});
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            )
                        );
                      },
                    ),
                  ],
                  secondaryActions: <Widget>[
                    IconSlideAction(
                      caption: 'Delete',
                      color: Colors.red,
                      icon: Icons.delete,
                      onTap: (){
                        taskList.taskDelete(task.id);
                        FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).update({'tasks': taskList.toUpdate()});
                      },
                    ),
                  ],
                );

              }).toList()
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: (){
                TextEditingController _newTaskController = TextEditingController();
                showDialog(
                  context: context,
                  builder: (_) => new AlertDialog(
                    title: new Text("New task"),
                    content: TextField(
                      autofocus: true,
                      controller: _newTaskController,
                    ),
                    actions: <Widget>[
                      TextButton(
                        style: TextButton.styleFrom(
                          primary: Colors.white,
                          backgroundColor: Colors.blue,
                          onSurface: Colors.grey,
                        ),
                        child: Text('Add'),
                        onPressed: () {
                          taskList.taskInsert(_newTaskController.text);
                          FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(listId).update({'tasks': taskList.toUpdate()});
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  )
                );
              },
              tooltip: 'Add a new task',
              child: const Icon(Icons.add),
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
  ListObject({required this.id, required this.name, required this.tasks});

  ListObject.fromJson(Map<String, Object?> json)
      : this(
    id: json['id']! as String,
    name: json['name']! as String,
    tasks: json['tasks']! as List<TaskObject>,
  );

  String name;
  List<TaskObject> tasks;
  String id;

  List<Map<String, dynamic>> toUpdate(){
    return tasks.map((task){
      return {'done': task.done, 'text': task.text};
    }).toList();
  }

  int get done{
    int done = 0;
    tasks.forEach((element){if(element.done) done++;});
    return done;
  }

  int get sum{
    return tasks.length;
  }

  void taskDone(int id){
    tasks[id].done = !tasks[id].done;
  }

  void taskEdit(int id, String text){
    tasks[id].text = text;
  }

  void taskDelete(int id){
    tasks.removeAt(id);
  }

  void taskMove(int indexOld, int indexNew){
    if(indexNew > tasks.length-1) indexNew = tasks.length-1;
    else if(indexNew < 0) indexNew = 0;
    tasks.insert(indexNew, tasks.removeAt(indexOld));
  }

  void renameList(String newName){
    name = newName;
  }
  
  void taskInsert(String text){
    tasks.add(TaskObject(id: tasks.length-1, text: text, done: false));
  }

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

  String text;
  bool done;
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
