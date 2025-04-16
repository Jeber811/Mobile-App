import 'dart:convert';
import 'package:http/http.dart' as http;

class Goal {
  String name;
  String cost;
  String paymentAmount;
  DateTime targetDate;
  String progress;

  // Constructor
  Goal({
    required this.name,
    required this.cost,
    required this.paymentAmount,
    required this.targetDate,
    required this.progress,
  });

  // Getter for progress to cost ratio as a percentage
  String get progressToCostRatio {
    final progressValue = double.tryParse(progress);
    final costValue = double.tryParse(cost);

    if (progressValue == null || costValue == null || costValue == 0) {
      return '0.00'; // fallback if data is missing or invalid
    }

    double ratio = (progressValue / costValue) * 100;
    return ratio.toStringAsFixed(2);
  }

}

class GoalStore {
  static List<Goal> goals = [];
}

Future<void> fetchAndPrintGoals(double id) async {
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

      if (userData != null && userData['goals'] != null) {
        List<dynamic> goalsData = userData['goals'];
        GoalStore.goals.clear();

        for (var goalData in goalsData) {
          final goal = Goal(
            name: goalData['name'] ?? 'Unnamed',
            cost: goalData['cost']?.toString() ?? '0',
            paymentAmount: goalData['paymentAmount']?.toString() ?? '0',
            targetDate: goalData['date'] != null
                ? DateTime.parse(goalData['date'])
                : DateTime.now(), // or use a fallback
            progress: goalData['progress']?.toString() ?? '0',
          );
          GoalStore.goals.add(goal);
        }

        print("User ID: $id");
        print("Total Goals: ${GoalStore.goals.length}");
        for (var goal in GoalStore.goals) {
          print(goal); // Will print the progress to cost ratio as well
        }
      } else {
        print("No goals found for user ID: $id");
      }
    } else {
      print("Failed to fetch user data. Status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
