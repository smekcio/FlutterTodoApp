import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'login.dart';
import 'home.dart';
import 'list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(
    MaterialApp(
      title: 'Flutter App',
      initialRoute: '/',
      routes: {
        '/': (context) => MainScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/list': (context) => ListScreen(),
      },
    ),
  );
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    if(auth.currentUser != null) return HomeScreen();
    else return LoginScreen();
  }
}


Future<void> init() async {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final SharedPreferences prefs = await _prefs;
  final keepSignedIn = prefs.getBool('keepSignedIn') ?? true;

  await Firebase.initializeApp();
  if(!keepSignedIn) await FirebaseAuth.instance.signOut();

  FirebaseAuth.instance
      .authStateChanges()
      .listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('$user is signed in!');
    }
  });
}