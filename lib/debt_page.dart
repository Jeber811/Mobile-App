import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'cards.dart';
import 'models/debt.dart';
import 'models/id.dart';
import 'edit_debts_page.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});

  @override
  _DebtPageState createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  final _formKey = GlobalKey<FormState>();

  final int _id = id.toInt();
  String _debtName = '';
  int _debtAmount = 0;
  int _paymentProgress = 0;
  DateTime? _paymentDate;
  int _paymentAmount = 0;

  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
        _dateController.text = "${picked.month}/${picked.day}/${picked.year}";
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newDebt = {
        'userId': _id,
        'debtName': _debtName,
        'debtAmount': _debtAmount,
        'paymentProgress': _paymentProgress,
        'paymentDate': DateFormat('yyyy-MM-dd').format(_paymentDate!),
        'paymentAmount': _paymentAmount,
      };

      // Rest of your code...


      try {
        final url = Uri.parse('http://147.182.211.23:5000/api/adddebt');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(newDebt),
        );

        print(jsonEncode(newDebt));
        print("Response code: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          _formKey.currentState!.reset();
          _dateController.clear();
          setState(() {
            _paymentDate = null;
          });
          await fetchAndPrintDebts(id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DebtPage()),
          );

          final responseBody = jsonDecode(response.body);
          final success = responseBody['success'] ?? false;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? "Debt successfully added!"
                  : "Debt with this name already exists"),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to add debt"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
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
        title: Text('Add Debt'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await fetchAndPrintDebts(id);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Cards()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Debt Name'),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter a debt name' : null,
                    onSaved: (value) => _debtName = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Debt Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a debt amount';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) => _debtAmount = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Payment Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a payment amount';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) => _paymentAmount = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Payment Progress'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty
                        ? 'Please enter a payment Progress'
                        : null,
                    onSaved: (value) => _paymentProgress = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Payment Date (mm/dd/yyyy)',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) =>
                    value!.isEmpty ? 'Please select a payment date' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Add Debt'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (DebtStore.debts.isNotEmpty) ...[
              Text(
                'Your Debts:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: DebtStore.debts.map((debt) {
                  return GestureDetector(
                    onTap: () async {
                      await fetchAndPrintDebts(id);
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditDebtPage(debt: debt),
                        ),
                      );
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📉 ${debt.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Debt Amount: \$${debt.amount}'),
                              Text('Payment Amount: \$${debt.paymentAmount}'),
                              Text('Payment Progress: ${debt.progress}%'),
                              Text('Payment Date: ${debt.date.month}/${debt.date.day}/${debt.date.year}'),
                              SizedBox(height: 6),
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
                                          widthFactor: debt.amount > 0 ? (debt.progress / debt.amount).clamp(0.0, 1.0) : 0.0,
                                          child: Container(
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    debt.amount > 0
                                        ? '${((debt.progress / debt.amount) * 100).toStringAsFixed(1)}%'
                                        : '0%',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                }).toList(),
              ),

            ] else ...[
              Text(
                'You have no debts yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
