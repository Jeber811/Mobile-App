import 'dart:convert';
import 'package:http/http.dart' as http;

class Expense {
  String name;
  String cost;
  DateTime date;
  String category;

  // Constructor
  Expense({
    required this.name,
    required this.cost,
    required this.date,
    required this.category,
  });

}

class ExpenseStore {
  static List<Expense> expenses = [];

}

Future<void> fetchAndPrintExpenses(double id) async {
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

      if (userData != null && userData['expenses'] != null) {
        List<dynamic> expensesData = userData['expenses'];
        ExpenseStore.expenses.clear();

        for (var expenseData in expensesData) {
          final expense = Expense(
            name: expenseData['name'] ?? 'Unnamed',
            cost: expenseData['cost']?.toString() ?? '0',
            date: expenseData['date'] != null
                ? DateTime.parse(expenseData['date'])
                : DateTime.now(), // or use a fallback
            category: expenseData['category'] ?? 'Uncategorized',
          );
          ExpenseStore.expenses.add(expense);
        }

        print("User ID: $id");
        print("Total Expenses: ${ExpenseStore.expenses.length}");
        for (var expense in ExpenseStore.expenses) {
          print(expense); // Will print the expense details
        }
      } else {
        print("No expenses found for user ID: $id");
      }
    } else {
      print("Failed to fetch user data. Status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
