import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'login.dart';
import 'signup.dart';
import 'change_password.dart';
import 'cards.dart';
import 'models/goal.dart';
import 'models/id.dart';
import 'edit_goals_page.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final _formKey = GlobalKey<FormState>();

  String _goalname = '';
  String _goalcost = '';
  String _goalpaymentamount = '';
  DateTime? _targetdate;
  String _progress = '';

  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetdate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _targetdate = picked;
        _dateController.text = "${picked.month}/${picked.day}/${picked.year}";
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newGoal = {
        'userId': id.toInt(),
        'goalName': _goalname,
        'goalCost': int.parse(_goalcost),
        'paymentAmount': int.parse(_goalpaymentamount),
        'paymentProgress': int.parse(_progress),
        'payDate': DateFormat('yyyy-MM-dd').format(_targetdate!),
      };

      print('new goal: $newGoal');

      try {
        final url = Uri.parse('http://147.182.211.23:5000/api/addgoal');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(newGoal),
        );

        print(jsonEncode(newGoal));

        print("Response code: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {

          _formKey.currentState!.reset();
          _dateController.clear();
          setState(() {
            _targetdate = null;
          });
          await fetchAndPrintGoals(id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GoalsPage()),
          );
          if (jsonDecode(response.body)['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Goal successfully added!"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Goal with this name already exists"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print("API Error: ${response.statusCode}");
          print("Response: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to add goal"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("Exception occurred: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Something went wrong"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Goal'),
        automaticallyImplyLeading: false,  // Remove default back button
        leading: IconButton(  // Add custom back button
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await fetchAndPrintGoals(id);
            // Navigate back to CardsPage
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Cards()),
                  (Route<dynamic> route) => false,  // This will pop all routes and prevent any from staying in the stack
            );
          },
        ),
      ),
      body: SingleChildScrollView(  // Wrap everything in SingleChildScrollView to ensure scrolling
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // The form for adding a new goal
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Goal Name'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a goal name' : null,
                      onSaved: (value) => _goalname = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Goal Cost'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a goal cost' : null,
                      onSaved: (value) => _goalcost = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Goal Payment Amount'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a goal payment amount' : null,
                      onSaved: (value) => _goalpaymentamount = value!,
                    ),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Target Date (mm/dd/yyyy)',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) =>
                      value!.isEmpty ? 'Please select a target date' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Progress'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter progress' : null,
                      onSaved: (value) => _progress = value!,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Add Goal'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Display the list of existing goals from GoalStore
              if (GoalStore.goals.isNotEmpty) ...[
                Text(
                  'Your Goals:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                // Wrap the ListView.builder in a Container to control the width
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,  // 80% width of the screen
                    child: ListView.builder(
                      shrinkWrap: true, // Ensures the list takes only necessary space
                      itemCount: GoalStore.goals.length,
                      itemBuilder: (context, index) {
                        final goal = GoalStore.goals[index];

                        double widthFactor = 0.0;
                        try {
                          final ratio = double.parse(goal.progressToCostRatio);
                          if (ratio > 0 && ratio <= 100) {
                            widthFactor = ratio / 100;
                          }
                        } catch (e) {
                          widthFactor = 0.0;
                        }

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditGoalPage(goal: goal),
                              ),
                            );
                            setState(() {}); // Refresh UI after editing
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🎯 ${goal.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Cost: \$${goal.cost}'),
                                    Text('Payment Amount: \$${goal.paymentAmount}'),
                                    Text('Target: ${goal.targetDate.month}/${goal.targetDate.day}/${goal.targetDate.year}'),
                                    Text('Progress: \$${goal.progress}'),
                                    SizedBox(height: 6),
                                    // Progress bar
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor: widthFactor,
                                                child: Container(
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${goal.progressToCostRatio}%',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Divider(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },

                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'You have no goals yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
