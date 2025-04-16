import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'models/goal.dart';
import 'models/id.dart';
import 'goals_page.dart';
import 'cards.dart';

class EditGoalPage extends StatefulWidget {
  final Goal goal;

  const EditGoalPage({Key? key, required this.goal}) : super(key: key);

  @override
  _EditGoalPageState createState() => _EditGoalPageState();
}

class _EditGoalPageState extends State<EditGoalPage> {
  late String _goalname;
  late String _goalcost;
  late String _paymentAmount;
  late String _progress;
  late String _targetDate;

  @override
  void initState() {
    super.initState();
    _goalname = widget.goal.name;
    _goalcost = widget.goal.cost;
    _paymentAmount = widget.goal.paymentAmount;
    _progress = widget.goal.progress;
    _targetDate = DateFormat('MM/dd/yyyy').format(widget.goal.targetDate);
  }

  void _deleteGoal() async {
    try {
      final url = Uri.parse('http://147.182.211.23:5000/api/removegoal');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': id.toInt(),
          'goalName': _goalname,
        }),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonDecode(response.body)['success'] == true) {
        await fetchAndPrintGoals(id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GoalsPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("Goal deleted")),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print("API Error: ${response.statusCode}");
        print("Response: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("Failed to delete goal")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Exception occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text("Something went wrong")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Goal'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await fetchAndPrintGoals(id);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => GoalsPage()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start, // Align to top
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎯 $_goalname', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('Cost: \$$_goalcost'),
                      Text('Payment Amount: \$$_paymentAmount'),
                      Text('Target Date: $_targetDate'),
                      Text('Progress: \$$_progress'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _deleteGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text('Delete Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
