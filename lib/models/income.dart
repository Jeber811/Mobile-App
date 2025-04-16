import 'dart:convert';
import 'package:http/http.dart' as http;

class Income {
  int amount;

  // Constructor
  Income({
    required this.amount,
  });

  @override
  String toString() {
    return '''
Income:
  Amount: \$${amount.toString()}
''';
  }
}

class IncomeStore {
  static int income = 0;  // Initialize as 0, or use a value from the API
}

Future<void> fetchAndUpdateIncome(double id) async {
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
      print('Full API Response: $data');  // Debug log

      final userData = data['userData'];
      if (userData != null && userData['income'] != null) {
        IncomeStore.income = userData['income'];

        print("User ID: $id");
        print("Total Incomes: \$${IncomeStore.income}");

        // Ensure UI reflects this change
        // If using a state management solution like Provider, notify listeners here:
        // notifyListeners();  // This is for if you're using ChangeNotifier or similar

      } else {
        print("No incomes found for user ID: $id");
      }
    } else {
      print("Failed to fetch user data. Status: ${response.statusCode}");
    }

  } catch (e) {
    print("Error: $e");
  }
}
