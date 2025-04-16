import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/signup.dart';
import 'models/id.dart';
import 'login.dart';

class VerifyEmailCodePage extends StatefulWidget {
  const VerifyEmailCodePage({super.key});

  @override
  _VerifyEmailCodePageState createState() => _VerifyEmailCodePageState();
}

class _VerifyEmailCodePageState extends State<VerifyEmailCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCodeController = TextEditingController();

  String _statusMessage = '';
  bool _isLoading = false;
  String code = '';

  // Generate a 6-digit code
  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send the email with the verification code
  Future<void> _sendVerificationCode() async {
    code = _generateCode();

    final body = jsonEncode({
      "recipientEmail": email, // Make sure 'email' is a valid variable
      "subject": "Your Verification Code",
      "message": "Your verification code is: $code"
    });

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://147.182.211.23:5000/api/send-email'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final result = jsonDecode(response.body);

      setState(() {
        _statusMessage = result['success']
            ? '✅ Verification code sent to $email'
            : '❌ Failed to send email: ${result['error']}';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Automatically send verification code when the page loads
    _sendVerificationCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SignUp()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                "📧 Verify Your Email",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendVerificationCode,
                icon: _isLoading
                    ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.email),
                label: Text(
                  _isLoading ? 'Sending...' : 'Resend Verification Code',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 20),

              if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusMessage.contains('✅') ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _emailCodeController,
                decoration: InputDecoration(
                  labelText: 'Email Confirmation Code',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the confirmation code';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (_emailCodeController.text != code) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❗ Invalid verification code!'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    // Proceed with any actions after successful code validation
                    doSignup(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ User Created!')),
                    );

                    // You can navigate to another page after successful code verification
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                          (Route<dynamic> route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("Verify Code"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void doSignup(BuildContext context) async {
    print('doSignup called');
    try {
      const signupUrl = 'http://147.182.211.23:5000/api/signup';
      final signupUri = Uri.parse(signupUrl);

      final Map<String, dynamic> requestBody = {
        'login': username,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

      final signupResponse = await http.post(
        signupUri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (signupResponse.statusCode == 200 || signupResponse.statusCode == 201) {
        final resJson = jsonDecode(signupResponse.body);
        final success = resJson['success'];
        final userId = resJson['userId']; // <-- Extract userId here
        print('Signup API Response: $resJson');

        if (success == true && userId != null) {
          // Now initialize the user data
          const datainitUrl = 'http://147.182.211.23:5000/api/datainit';
          final datainitUri = Uri.parse(datainitUrl);

          final initResponse = await http.post(
            datainitUri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({'userId': userId}),
          );

          final initJson = jsonDecode(initResponse.body);
          print('Datainit API Response: $initJson');

          if (initResponse.statusCode == 200 && initJson['success'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VerifyEmailCodePage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User created, but failed to initialize data'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resJson['error'] ?? 'Signup failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('Signup failed. Status code: ${signupResponse.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User already created"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}
