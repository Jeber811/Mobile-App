import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'login.dart';
import 'signup.dart';
import 'change_password.dart';
import 'goals_page.dart';
import 'models/goal.dart';
import 'models/id.dart';
import 'models/expense.dart';
import 'expenses_page.dart';
import 'models/income.dart';
import 'income_page.dart';
import 'debt_page.dart';
import 'models/debt.dart';
import 'account_settings.dart';

class Cards extends StatefulWidget {
  const Cards({super.key});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  List<Expense> expensesList = ExpenseStore.expenses;

  // Function to filter expenses within the next 7 days, including today
  List<Expense> getUpcomingExpenses() {
    DateTime now = DateTime.now();
    DateTime sevenDaysFromNow = now.add(Duration(days: 7));

    // Filter expenses with a date within the next 7 days, including today
    List<Expense> upcomingExpenses = expensesList.where((expense) {
      return expense.date.isAfter(now.subtract(Duration(days: 1))) && expense.date.isBefore(sevenDaysFromNow);
    }).toList();

    // Sort the expenses by due date (ascending order)
    upcomingExpenses.sort((a, b) => a.date.compareTo(b.date));

    return upcomingExpenses;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/777.png',
              fit: BoxFit.contain,
              height: 32,
            ),
            SizedBox(width: 10),
            Text(
              '777Finances',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await fetchAndPrintGoals(id);
              await fetchAndPrintExpenses(id);
              await fetchAndPrintDebts(id);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AccountSettings()),
              );

            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Upcoming Expenses - Display filtered and sorted expenses
            List<Expense> upcomingExpenses = getUpcomingExpenses();
            return _buildUpcomingExpensesCard(upcomingExpenses);
          } else if (index == 1) {
            // Goals
            return GestureDetector(
              onTap: () async {
                await fetchAndPrintGoals(id);
                await Navigator.push<Goal>(
                  context,
                  MaterialPageRoute(builder: (context) => GoalsPage()),
                );
              },
              child: _buildGoalsCard(),
            );
          } else if (index == 2) {
            // Income
            return GestureDetector(
              onTap: () async {
                await fetchAndUpdateIncome(id);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditIncomePage()),
                );
              },
              child: _buildGenericCard(
                "Income",
                IncomeStore.income == 0 ? "No Income" : "\$${IncomeStore.income}.",
              ),
            );
          } else if (index == 3) {
              // Debt
              return GestureDetector(
                onTap: () async {
                  await fetchAndPrintDebts(id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DebtPage()),
                  );
                },
                child: _buildDebtsCard(),
              );
          } else if (index == 4) {
            // Expenses Card
            return GestureDetector(
              onTap: () async {
                await fetchAndPrintExpenses(id);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpensesPage()),
                );
              },
              child: _buildExpenseCard(),
            );
          } else if (index == 5) {
            return _buildRemainingBalanceCard();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: ()
    {
      id = -1;
      GoalStore.goals.clear();
      ExpenseStore.expenses.clear();
      IncomeStore.income = 0;
      DebtStore.debts.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login()),
        (route) => false,
      );
    },
          backgroundColor: Color(0xFF051E3A),
          child: Center(child: Text('Log Out')),
      ),
    );
  }

  // Build the Upcoming Expenses card
  Widget _buildUpcomingExpensesCard(List<Expense> upcomingExpenses) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            upcomingExpenses.isEmpty
                ? Text('You have no upcoming expenses in the next 7 days.')
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: upcomingExpenses.map((expense) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💸 ${expense.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Cost: \$${expense.cost}'),
                      Text('Category: ${expense.category}'),
                      Text('Due Date: ${expense.date.month}/${expense.date.day}/${expense.date.year}'),
                      SizedBox(height: 10),
                      Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Generic card widget used in other parts
  Widget _buildGenericCard(String title, String description) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard() {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ExpenseStore.expenses.isEmpty
                ? Text('You have no expenses yet.')
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ExpenseStore.expenses.map((expense) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
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
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            GoalStore.goals.isEmpty
                ? Text('You have no goals yet.')
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: GoalStore.goals.map((goal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎯 ${goal.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Cost: \$${goal.cost}'),
                      Text('Payment Amount: \$${goal.paymentAmount}'),
                      Text('Target: ${goal.targetDate.month}/${goal.targetDate.day}/${goal.targetDate.year}'),
                      Text('Progress: \$${goal.progress}'),
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
                                  widthFactor: double.parse(goal.progressToCostRatio) / 100,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${goal.progressToCostRatio}%',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  int calculateRemainingBalance() {
    int totalExpenses = ExpenseStore.expenses.fold(0, (sum, item) => sum + int.parse(item.cost));
    return IncomeStore.income - totalExpenses;
  }

  Widget _buildRemainingBalanceCard() {
    int remainingBalance = calculateRemainingBalance();

    return Card(
      margin: EdgeInsets.all(12),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remaining Balance 💵', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('\$$remainingBalance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }


  Widget _buildDebtsCard() {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            DebtStore.debts.isEmpty
                ? Text('You have no debts yet.')
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: DebtStore.debts.map((debt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📉 ${debt.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Debt Amount: \$${debt.amount}'),
                      Text('Payment Amount: \$${debt.paymentAmount}'),
                      Text(
                        'Payment Progress: ${debt.amount > 0 ? ((debt.progress / debt.amount) * 100).toStringAsFixed(1) : '0'}%',
                      ),
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
                                  widthFactor: debt.amount > 0 ? (debt.progress / debt.amount).clamp(0.0, 1.0) : 0,
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
                            '${debt.amount > 0 ? ((debt.progress / debt.amount) * 100).toStringAsFixed(1) : '0'}%',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

}
