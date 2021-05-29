import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'list.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final uid = FirebaseAuth.instance.currentUser!.uid.toString();
  final Stream<QuerySnapshot> _todoStream = FirebaseFirestore.instance.collection('todo').doc(uid).collection('lists').snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _todoStream,
        builder: (BuildContext contextStream, AsyncSnapshot<QuerySnapshot> snapshot){
          if(snapshot.hasError) return Text('Something went wrong');
          if(snapshot.connectionState == ConnectionState.waiting) return Text('Loading');
          return Scaffold(
            appBar: AppBar(
              title: new Text('Home'),
            ),
            body: ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document){
                String documentId = document.id;
                String todoListName = (document.data() as Map)['name'];
                return new ListTile(
                    title: new Text(todoListName),
                    onTap: (){Navigator.pushNamed(context, '/list', arguments: ListScreenArguments(documentId));},
                );
              }).toList()
              // .data()!.entries.map((e) => new ListTile(title: Text(e.value),)).toList(),
            ),
          );
        }
    );
  }
}
