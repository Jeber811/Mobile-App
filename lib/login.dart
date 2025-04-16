import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_app/recover_password.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'signup.dart';
import 'change_password.dart';
import 'cards.dart';
import 'goals_page.dart';
import 'models/id.dart';
import 'models/goal.dart';
import 'models/expense.dart';
import 'models/income.dart';
import 'models/debt.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final _loginFormGlobalKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/777.png',
              fit: BoxFit.contain,
              height: 32,
            ),
            SizedBox(width: 10),
            Text(
              '777Finances',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Please Log In',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            Form(
              key: _loginFormGlobalKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Username
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if(value == null || value.isEmpty) {
                        return 'Enter a username';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _username = value!;
                    },
                  ),
                  SizedBox(height: 15.0),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if(value == null || value.isEmpty) {
                        return 'Enter a password';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                  ),
                  SizedBox(height: 15.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_loginFormGlobalKey.currentState!.validate()) {
                        _loginFormGlobalKey.currentState!.save();
                        doLogin(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text('Do It'),
                  ),
                  SizedBox(height: 10.0),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SignUp()),
                        );
                      },
                      child: const Text('Sign up'),
                    ),
                    const Text(' here.'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Forgot Password? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => RecoverPasswordWidget()),
                        );
                      },
                      child: const Text('Recover Password'),
                    ),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
  void doLogin(BuildContext context) async {
    try {
      const url = 'http://147.182.211.23:5000/api/login';
      final uri = Uri.parse(url);

      final Map<String, dynamic> requestBody = {
        'login': _username,
        'password': _password,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('id')) {
          id = jsonResponse['id'].toDouble();
          print('Login successful: $jsonResponse');

          if (id > 0) {
            _loginFormGlobalKey.currentState!.reset();

            // Fetch user info using the id
            final userInfo = await fetchUserInfo(id);
            if (userInfo != null) {
              email = userInfo['Email'] ?? 'No email';
              firstName = userInfo['FirstName'] ?? 'No first name';
              lastName = userInfo['LastName'] ?? 'No last name';
              username = userInfo['Login'] ?? 'No username';

              print('User Email: $email');
              print('User First Name: $firstName');
              print('User Last Name: $lastName');

              // You can store these in your state or pass them to the next page as needed
            }

            await fetchAndPrintGoals(id);
            await fetchAndPrintExpenses(id);
            await fetchAndUpdateIncome(id);
            await fetchAndPrintDebts(id);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Cards()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Center(child: Text("Incorrect username/password")),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('Error: Failed to fetch data. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }



  Future<Map<String, dynamic>?> fetchUserInfo(double userId) async {
    const url = 'http://147.182.211.23:5000/api/getinfo'; // Your API endpoint
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['user'] != null) {
          return jsonResponse['user']; // Will contain email, firstname, lastname
        } else {
          print('Error: ${jsonResponse['error']}');
        }
      } else {
        print('Error: Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }

    return null;
  }

}