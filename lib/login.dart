import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String _authError = "";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.vpn_key,
              color: Colors.amber,
              size: 170.0,
              semanticLabel: 'Text to announce in accessibility modes',
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: 'Enter email'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter password'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () async {
                      if(_validateTextFields()){
                        await _login(_emailController.text, _passwordController.text);
                        if(auth.currentUser != null){
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_authError)));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_authError)));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 18
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Colors.blue,
                      onSurface: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if(_validateTextFields()){
                        await _register(_emailController.text, _passwordController.text);
                        if(auth.currentUser != null){
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_authError)));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_authError)));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Register',
                        style: TextStyle(
                            fontSize: 18
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      primary: Colors.black45,
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateTextFields(){
    _authError = "";
    if(_emailController.text.isEmpty)
      _authError = "Empty email";
    else if(!RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$").hasMatch(_emailController.text))
      _authError = "Invalid email";
    else if(_passwordController.text.isEmpty)
      _authError = "Empty password";
    else if(_passwordController.text.length < 8)
      _authError = "Insecure password (minimum 8 characters)";
    return _authError.isEmpty;
  }

  Future<void> _register(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _authError = 'The password provided is too weak.';
        print(_authError);
      } else if (e.code == 'email-already-in-use') {
        _authError = 'The account already exists for that email.';
        print(_authError);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _login(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _authError = 'No user found for that email.';
        print(_authError);
      } else if (e.code == 'wrong-password') {
        _authError = 'Wrong password provided for that user.';
        print(_authError);
      }
    }
  }
}