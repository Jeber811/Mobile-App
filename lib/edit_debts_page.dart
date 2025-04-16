import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'models/debt.dart';
import 'models/id.dart';
import 'debt_page.dart';

class EditDebtPage extends StatefulWidget {
  final Debt debt;

  const EditDebtPage({Key? key, required this.debt}) : super(key: key);

  @override
  _EditDebtPageState createState() => _EditDebtPageState();
}

class _EditDebtPageState extends State<EditDebtPage> {
  late int _id;
  late String _debtName;
  late int _debtAmount;
  late int _paymentProgress;
  late String _paymentDate;
  late int _paymentAmount;

  @override
  void initState() {
    super.initState();
    _id = id.toInt();
    _debtName = widget.debt.name;
    _debtAmount = widget.debt.amount;
    _paymentProgress = widget.debt.progress;
    final date = widget.debt.date;
    _paymentDate = DateFormat('MM/dd/yyyy').format(date);
    _paymentAmount = widget.debt.paymentAmount;
  }

  void _deleteDebt() async {
    try {
      final url = Uri.parse('http://147.182.211.23:5000/api/deletedebt');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _id,
          'debtName': _debtName,
        }),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonDecode(response.body)['success'] == true) {
        await fetchAndPrintDebts(id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DebtPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("Debt deleted")),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("Failed to delete debt")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
        title: Text('Delete Debt'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await fetchAndPrintDebts(id);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => DebtPage()),
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
            mainAxisAlignment: MainAxisAlignment.start,
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
                      Text('📉 $_debtName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('Total Debt: \$$_debtAmount'),
                      Text('Payment Amount: \$$_paymentAmount'),
                      Text('Payment Date: $_paymentDate'),
                      Text('Progress: \$$_paymentProgress'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _deleteDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text('Delete Debt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
