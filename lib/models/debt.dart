import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/edit_debts_page.dart';
import 'package:mobile_app/debt_page.dart';
import 'id.dart';

class Debt {
  String name;
  int amount;
  int paymentAmount;      // ✅ NEW FIELD
  int progress;
  DateTime date;
  int userId = id.toInt();

  Debt({
    required this.userId,
    required this.name,
    required this.amount,
    required this.paymentAmount,   // ✅ Include in constructor
    required this.progress,
    required this.date,
  });

  @override
  String toString() {
    return 'Debt(userId: $userId, name: $name, amount: $amount, paymentAmount: $paymentAmount, progress: $progress, date: $date)';
  }
}

class DebtStore {
  static List<Debt> debts = [];
}

Future<void> fetchAndPrintDebts(double id) async {
  //printAllDebts();
  try {
    final response = await http.post(
      Uri.parse("http://147.182.211.23:5000/api/getdata"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({'userId': id}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Full API Response: $data');

      final userData = data['userData'];

      if (userData != null && userData['debt'] != null) {
        List<dynamic> debtsData = userData['debt'];
        DebtStore.debts.clear();

        for (var debtData in debtsData) {
          final debt = Debt(
            userId: id.toInt(),
            name: debtData['name'] ?? 'name',
            amount: int.tryParse(debtData['amount'].toString()) ?? 0,
            paymentAmount: int.tryParse(debtData['paymentAmount'].toString()) ?? 0, // ✅ NEW
            progress: int.tryParse(debtData['progress'].toString()) ?? 0,
            date: debtData['date'] != null
                ? DateTime.parse(debtData['date'])
                : DateTime.now(),
          );
          print('Debt Name: ${debt.name}');
          DebtStore.debts.add(debt);
        }

        print("User ID: $id");
        print("Total Debts: ${DebtStore.debts.length}");
        for (var debt in DebtStore.debts) {
          print(debt);
        }
      } else {
        print("No debts found for user ID: $id");
      }
    } else {
      print("Failed to fetch user data. Status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error: $e");
  }
}

void printAllDebts() {
  if (DebtStore.debts.isEmpty) {
    print("No debts to display.");
    return;
  }

  print("Printing all stored debts:");
  for (var debt in DebtStore.debts) {
    print(debt.toString());
  }
}
