import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../utils/date_helpers.dart';

class GoalProgressWidget extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalProgressWidget({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = goal.progressPercentage;
    final isCompleted = goal.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
            ],
          ),
        ),
      ),
    );
  }
}