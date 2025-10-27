import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../utils/date_helpers.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    
    try {
      final goals = await _databaseService.getAllGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goals: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Financial Goals Set',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set financial goals to track your savings progress',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddGoalDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First Goal'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final progressPercentage = goal.progressPercentage;
                    final isCompleted = goal.isCompleted;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? Colors.green : Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    goal.category,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Target: ${DateHelpers.formatCurrency(goal.targetAmount)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        'Progress: ${DateHelpers.formatCurrency(goal.currentProgress)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${progressPercentage.toStringAsFixed(1)}%',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: progressPercentage >= 100 ? Colors.green : Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      DateHelpers.formatDate(goal.targetDate),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: (progressPercentage / 100).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressPercentage >= 100 ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _showGoalDetails(goal),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Tap to update progress',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add New Goal',
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetAmountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 365));
    String selectedCategory = 'House';
    
    final categories = ['House', 'Retirement', 'Education', 'Emergency', 'Travel', 'Car', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Financial Goal'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: targetAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) setState(() => targetDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text('${targetDate.day}/${targetDate.month}/${targetDate.year}'),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || targetAmountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }
                
                final goal = Goal(
                  name: nameController.text.trim(),
                  targetAmount: double.parse(targetAmountController.text),
                  targetDate: targetDate,
                  category: selectedCategory,
                  description: descriptionController.text.trim().isEmpty ? '' : descriptionController.text.trim(),
                );
                
                try {
                  await _databaseService.insertGoal(goal);
                  Navigator.of(context).pop();
                  _loadGoals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Add Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDetails(Goal goal) {
    final progressController = TextEditingController(
      text: goal.currentProgress.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.name),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${goal.category}'),
              const SizedBox(height: 8),
              Text('Target: ${DateHelpers.formatCurrency(goal.targetAmount)}'),
              Text('Progress: ${DateHelpers.formatCurrency(goal.currentProgress)}'),
              Text('Remaining: ${DateHelpers.formatCurrency(goal.remainingAmount)}'),
              Text('Days left: ${goal.daysRemaining}'),
              Text('Progress: ${goal.progressPercentage.toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: goal.progressPercentage / 100,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: progressController,
                decoration: const InputDecoration(
                  labelText: 'Update Progress',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newProgress = double.tryParse(progressController.text);
              if (newProgress != null) {
                final updatedGoal = goal.copyWith(currentProgress: newProgress);
                try {
                  await _databaseService.updateGoal(updatedGoal);
                  Navigator.of(context).pop();
                  _loadGoals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}