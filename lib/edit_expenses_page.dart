import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'models/expense.dart';
import 'models/id.dart';
import 'expenses_page.dart';

class EditExpensePage extends StatefulWidget {
  final Expense expense;

  const EditExpensePage({Key? key, required this.expense}) : super(key: key);

  @override
  _EditExpensePageState createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late String _expensename;
  late String _expensecost;

  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expensename = widget.expense.name;
    _expensecost = widget.expense.cost;
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedExpense = {
        'userId': id.toInt(),
        'expenseName': _expensename,
        'newExpenseCost': int.parse(_expensecost),
      };

      print('Updated expense: $updatedExpense');

      try {
        final url = Uri.parse('http://147.182.211.23:5000/api/updateexpense');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedExpense),
        );

        print(jsonEncode(updatedExpense));
        print("Response code: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(child: Text("Expense edited")),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print("API Error: ${response.statusCode}");
          print("Response: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(child: Text("Failed to update expense")),
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
  }

  // Function to delete the expense
  void _deleteExpense() async {
    try {
      final url = Uri.parse('http://147.182.211.23:5000/api/removeexpense'); // You need to create this endpoint
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': id.toInt(),
          'expenseName': _expensename,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201 && jsonDecode(response.body)['success'] == true) {
          await fetchAndPrintExpenses(id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>
                ExpensesPage()), // Navigate back to the expenses list
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(child: Text("Expense deleted")),
              backgroundColor: Colors.red,
            ),
          );
      } else {
        print("API Error: ${response.statusCode}");
        print("Response: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("Failed to delete expense")),
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
        title: Text('Edit Expense'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await fetchAndPrintExpenses(id);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ExpensesPage()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: _expensename,
                  decoration: InputDecoration(labelText: 'Expense Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter an expense name' : null,
                  onSaved: (value) => _expensename = value!,
                  readOnly: true,  // Make the field read-only (not editable)
                ),
                TextFormField(
                  initialValue: _expensecost,
                  decoration: InputDecoration(labelText: 'Expense Cost'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter an expense cost' : null,
                  onSaved: (value) => _expensecost = value!,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Save Changes'),
                ),
                SizedBox(height: 30),  // Space between buttons
                ElevatedButton(
                  onPressed: _deleteExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,  // Red background
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),  // Make it big
                    textStyle: TextStyle(fontSize: 18),  // Font size
                  ),
                  child: Text(
                    'Delete Expense',
                    style: TextStyle(color: Colors.white),  // White text color
                  ),
                )


              ],
            ),
          ),
        ),
      ),
    );
  }
}
