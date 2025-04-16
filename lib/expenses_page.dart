import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'login.dart';
import 'signup.dart';
import 'change_password.dart';
import 'cards.dart';
import 'models/expense.dart';
import 'models/id.dart';
import 'edit_expenses_page.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _formKey = GlobalKey<FormState>();

  String _expensename = '';
  String _expensecost = '';
  DateTime? _expensedate;
  String _expensecategory = '';

  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expensedate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expensedate = picked;
        _dateController.text = "${picked.month}/${picked.day}/${picked.year}";
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newExpense = {
        'userId': id.toInt(),
        'expenseName': _expensename,
        'expenseCost': int.parse(_expensecost),
        'expenseCategory': _expensecategory,
        'expenseDate': DateFormat('yyyy-MM-dd').format(_expensedate!),
      };

      print('new expense: $newExpense');

      try {
        final url = Uri.parse('http://147.182.211.23:5000/api/addexpense');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(newExpense),
        );

        print(jsonEncode(newExpense));

        print("Response code: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {

          _formKey.currentState!.reset();
          _dateController.clear();
          setState(() {
            _expensedate = null;
          });
          await fetchAndPrintExpenses(id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExpensesPage()),
          );
          if (jsonDecode(response.body)['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Expense successfully added!"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Expense with this name already exists"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print("API Error: ${response.statusCode}");
          print("Response: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to add expense"),
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
        title: Text('Add Expense'),
        automaticallyImplyLeading: false,  // Remove default back button
        leading: IconButton(  // Add custom back button
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await fetchAndPrintExpenses(id);
            // Navigate back to CardsPage
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Cards()),
                  (Route<dynamic> route) => false,  // This will pop all routes and prevent any from staying in the stack
            );
          },
        ),
      ),
      body: SingleChildScrollView(  // Wrap everything in a SingleChildScrollView to make the page scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // The form for adding a new expense
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Expense Name'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter an expense name' : null,
                      onSaved: (value) => _expensename = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Expense Cost'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter an expense cost' : null,
                      onSaved: (value) => _expensecost = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Expense Category'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter an expense category' : null,
                      onSaved: (value) => _expensecategory = value!,
                    ),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Expense Date (mm/dd/yyyy)',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) =>
                      value!.isEmpty ? 'Please select an expense date' : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Add Expense'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Display the list of existing expenses from ExpenseStore
              if (ExpenseStore.expenses.isNotEmpty) ...[
                Text(
                  'Your Expenses:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                // Wrap the ListView.builder in a Container to control the width
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,  // 80% width of the screen
                    child: ListView.builder(
                      shrinkWrap: true, // Ensures the list takes only necessary space
                      itemCount: ExpenseStore.expenses.length,
                      itemBuilder: (context, index) {
                        final expense = ExpenseStore.expenses[index];

                        return GestureDetector(
                          onTap: () async {
                            // Push to an edit screen passing the selected expense
                            await Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditExpensePage(expense: expense),
                              ),
                            );
                            // After editing, refresh the list
                            setState(() {});
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
                                    Text('💸 ${expense.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Cost: \$${expense.cost}'),
                                    Text('Category: ${expense.category}'),
                                    Text('Date: ${expense.date.month}/${expense.date.day}/${expense.date.year}'),
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
                  'You have no expenses yet.',
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

