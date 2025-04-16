import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/income.dart';  // Import your Income model
import 'models/id.dart';  // Import user ID model
import 'cards.dart';  // Import your Cards page

class EditIncomePage extends StatefulWidget {
  const EditIncomePage({super.key});

  @override
  _EditIncomePageState createState() => _EditIncomePageState();
}

class _EditIncomePageState extends State<EditIncomePage> {
  final _formKey = GlobalKey<FormState>();
  late int _incomeamount; // Declare income as an int

  @override
  void initState() {
    super.initState();
    _incomeamount = IncomeStore.income;  // Default income value
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedIncome = {
        'userId': id.toInt(),
        'newIncomeAmount': _incomeamount,
      };

      print('Updated income: $updatedIncome');

      try {
        final url = Uri.parse('http://147.182.211.23:5000/api/editincome');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedIncome),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(child: Text("Income edited")),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print("API Error: ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(child: Text("Failed to update income")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Income'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await fetchAndUpdateIncome(id);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Cards()),
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
                  initialValue: _incomeamount.toString(),
                  decoration: InputDecoration(labelText: 'Income Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an income amount';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _incomeamount = int.parse(value!); // Save as int
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
