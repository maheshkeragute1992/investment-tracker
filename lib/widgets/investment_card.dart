import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../utils/date_helpers.dart';

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
}