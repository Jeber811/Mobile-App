import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_app/account_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'login.dart';
import 'signup.dart';
import 'cards.dart';
import 'models/id.dart';

class SendVerificationWidget extends StatefulWidget {
  const SendVerificationWidget({super.key});

  @override
  State<SendVerificationWidget> createState() => _SendVerificationWidgetState();
}

class _SendVerificationWidgetState extends State<SendVerificationWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _statusMessage = '';
  bool _isLoading = false;
  String code = '';

  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _sendVerificationCode() async {
    code = _generateCode();

    final body = jsonEncode({
      "recipientEmail": email,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 26),
          onPressed: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AccountSettings()),
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
                "🔒 Update Your Password",
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
                  _isLoading ? 'Sending...' : 'Send Verification Code',
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

              _buildTextField(
                controller: _passwordController,
                label: 'New Password',
                isPassword: true,
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                isPassword: true,
              ),

              const SizedBox(height: 30),

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

                    bool success = await updatePassword(id, _passwordController.text);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Password changed successfully!')),
                      );
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _emailCodeController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Failed to change password!'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("Submit New Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return label.contains('Confirm')
              ? 'Please confirm your password'
              : 'Please enter a password';
        }

        if (label.contains('Confirm')) {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
        } else if (label.contains('New Password')) {
          final passwordRegex = RegExp(
            r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$',
          );

          if (!passwordRegex.hasMatch(value)) {
            return '''
Password must meet the following criteria:
- At least 8 characters long
- Contain at least 1 number
- Contain at least 1 special character
- Contain at least 1 uppercase letter
''';
          }
        }

        return null;
      },
    );
  }


  Future<bool> updatePassword(double userId, String newPassword) async {
    final url = Uri.parse('http://147.182.211.23:5000/api/updatepassword');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }
}
