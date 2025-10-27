import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../utils/date_helpers.dart';
import '../utils/constants.dart';
import '../screens/loan_details_screen.dart';

class InvestmentCard extends StatelessWidget {
  final Investment investment;
  final VoidCallback? onTap;

  const InvestmentCard({
    super.key,
    required this.investment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (investment.type == AppConstants.loanToFriend) {
      return _buildLoanCard(context);
    }
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(investment.name),
        subtitle: Text(investment.type),
        trailing: Text(DateHelpers.formatCurrency(investment.amount)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context) {
    final friendName = investment.additionalData?['friend_name'] ?? '';
    final originalAmount = double.parse(investment.additionalData?['original_amount'] ?? '0');
    final outstandingAmount = investment.amount;
    final daysLent = DateTime.now().difference(investment.startDate).inDays;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LoanDetailsScreen(loan: investment),
            ),
          );
          if (onTap != null) {
            onTap!();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppConstants.loanColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Loan to $friendName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: investment.status == 'Completed' 
                          ? Colors.green.withValues(alpha: 0.2)
                          : AppConstants.loanColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      investment.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: investment.status == 'Completed' 
                            ? Colors.green[700]
                            : AppConstants.loanColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateHelpers.formatCurrency(outstandingAmount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppConstants.loanColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Days Lent',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$daysLent days',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Original: ${DateHelpers.formatCurrency(originalAmount)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}