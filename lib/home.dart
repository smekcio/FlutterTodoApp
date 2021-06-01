import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'list.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid.toString();
    Stream<QuerySnapshot> _todoStream = FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').snapshots();
    return StreamBuilder(
        stream: _todoStream,
        builder: (BuildContext contextStream, AsyncSnapshot<QuerySnapshot> snapshot){
          if(snapshot.hasError) return Text('Something went wrong');
          if(snapshot.connectionState == ConnectionState.waiting) return Text('Loading');

          final List<ListObject> taskLists = List.from(snapshot.data!.docs).map((taskList){
            var id = taskList.id;
            var name = taskList['name'] ?? "";
            List<TaskObject> tasks = [];
            if(taskList['tasks'].length > 0){
              var taskIndex = 0;
              tasks = List.from(taskList['tasks']).map((task){
                var text = task['text'] ?? "";
                var done = task['done'] ?? "";
                return new TaskObject(id: taskIndex++, text: text, done: done);
              }).toList();
            }
            return new ListObject(id: id,name: name, tasks: tasks);
          }).toList();

          return Scaffold(
            appBar: AppBar(
              title: new Text('Home'),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
            body: ReorderableListView(
              onReorder: (int oldIndex, int newIndex) {

              },
              children: taskLists.map((ListObject list){
                return Slidable(
                  key: UniqueKey(),
                  actionPane: SlidableDrawerActionPane(),
                  actionExtentRatio: 0.25,
                  child: Container(
                    color: Colors.white,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: ListTile(
                          onTap: (){Navigator.pushNamed(context, '/list', arguments: ListScreenArguments(list.id));},
                          title: Text(list.name),
                        ),
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    IconSlideAction(
                      caption: 'Edit',
                      color: Colors.blue,
                      icon: Icons.drive_file_rename_outline,
                      onTap: (){
                        TextEditingController _editNameController = TextEditingController();
                        _editNameController.text = list.name;
                        showDialog(
                            context: context,
                            builder: (_) => new AlertDialog(
                              title: new Text("Edit list name"),
                              content: TextField(
                                autofocus: true,
                                controller: _editNameController,
                                maxLines: null,
                              ),
                              actions: <Widget>[
                                TextButton(
                                  style: TextButton.styleFrom(
                                    primary: Colors.white,
                                    backgroundColor: Colors.blue,
                                    onSurface: Colors.grey,
                                  ),
                                  child: Text('Rename'),
                                  onPressed: () {
                                    list.renameList(_editNameController.text);
                                    FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(list.id).update({'name': _editNameController.text});
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
                      onTap: () async {
                        taskLists.removeWhere((element) => element.id == list.id);
                        DocumentReference listReference = FirebaseFirestore.instance.collection('todo').doc(uid);
                        await FirebaseFirestore.instance.runTransaction((Transaction myTransaction) async {
                          await myTransaction.delete(FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').doc(list.id));
                        });
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
                      title: new Text("New list"),
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
                          onPressed: () async {
                            CollectionReference listsReference = FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists');
                            DocumentReference newList = await listsReference.add({
                              'name': _newTaskController.text,
                              'tasks': []
                            });
                            taskLists.add(new ListObject(id: newList.id, name: _newTaskController.text, tasks: []));
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
            // body: ListView(
            //   children: snapshot.data!.docs.map((DocumentSnapshot document){
            //     String documentId = document.id;
            //     String todoListName = (document.data() as Map)['name'];
            //     return new ListTile(
            //         title: new Text(todoListName),
            //         onTap: (){Navigator.pushNamed(context, '/list', arguments: ListScreenArguments(documentId));},
            //     );
            //   }).toList()
            //   // .data()!.entries.map((e) => new ListTile(title: Text(e.value),)).toList(),
            // ),
          );
        }
    );
  }
}
