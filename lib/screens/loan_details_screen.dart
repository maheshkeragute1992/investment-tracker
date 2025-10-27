import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class LoanDetailsScreen extends StatefulWidget {
  final Investment loan;

  const LoanDetailsScreen({super.key, required this.loan});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _repaymentController = TextEditingController();
  late Investment _currentLoan;
  List<Map<String, dynamic>> _repayments = [];

  @override
  void initState() {
    super.initState();
    _currentLoan = widget.loan;
    _loadLatestLoanData();
  }

  Future<void> _loadLatestLoanData() async {
    try {
      final latestLoan = await _databaseService.getInvestmentById(_currentLoan.id!);
      if (latestLoan != null && mounted) {
        setState(() {
          _currentLoan = latestLoan;
          _loadRepayments();
        });
      }
    } catch (e) {
      print('Error loading latest loan data: $e');
      _loadRepayments(); // Fallback to current data
    }
  }

  void _loadRepayments() {
    final repaymentData = _currentLoan.additionalData?['repayments'] ?? '';
    _repayments = [];
    if (repaymentData.isNotEmpty) {
      final repaymentList = repaymentData.split('|');
      for (final r in repaymentList) {
        if (r.isNotEmpty) {
          final parts = r.split(':');
          if (parts.length >= 2) {
            try {
              _repayments.add({
                'date': DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
                'amount': double.parse(parts[1]),
              });
            } catch (e) {
              print('Error parsing repayment: $r, Error: $e');
            }
          }
        }
      }
    }
  }

  double get _originalAmount => double.parse(_currentLoan.additionalData?['original_amount'] ?? '0');
  double get _outstandingAmount => _currentLoan.amount;
  String get _friendName => _currentLoan.additionalData?['friend_name'] ?? '';
  
  int get _daysLent {
    return DateTime.now().difference(_currentLoan.startDate).inDays;
  }

  double get _totalRepaid {
    return _repayments.fold(0.0, (sum, repayment) => sum + repayment['amount']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan to $_friendName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanSummary(),
            const SizedBox(height: 24),
            _buildRepaymentSection(),
            const SizedBox(height: 24),
            _buildRepaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppConstants.loanColor),
                const SizedBox(width: 8),
                Text(
                  _friendName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Original Amount',
                    '₹${_originalAmount.toStringAsFixed(0)}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Outstanding',
                    '₹${_outstandingAmount.toStringAsFixed(0)}',
                    AppConstants.loanColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Repaid',
                    '₹${_totalRepaid.toStringAsFixed(0)}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Days Lent',
                    '$_daysLent days',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (_currentLoan.interestRate != null) ...[
              const SizedBox(height: 12),
              _buildSummaryItem(
                'Interest Rate',
                '${_currentLoan.interestRate}% per month',
                Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRepaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Repayment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _repaymentController,
              decoration: const InputDecoration(
                labelText: 'Repayment Amount',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _recordRepaymentFromField,
                child: const Text('Record Repayment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepaymentHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repayment History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_repayments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No repayments recorded yet'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _repayments.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final repayment = _repayments[index];
                  return ListTile(
                    leading: const Icon(Icons.payment, color: Colors.green),
                    title: Text('₹${repayment['amount'].toStringAsFixed(0)}'),
                    subtitle: Text(
                      '${repayment['date'].day}/${repayment['date'].month}/${repayment['date'].year}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRepayment(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _recordRepaymentFromField() {
    final amountText = _repaymentController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter repayment amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > _outstandingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount cannot exceed outstanding balance')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _RepaymentDialog(
        outstandingAmount: _outstandingAmount,
        prefilledAmount: amount,
        onRepaymentRecorded: (finalAmount, date) => _recordRepayment(finalAmount, date),
      ),
    );
  }

  Future<void> _recordRepayment(double amount, DateTime date) async {
    final newRepayment = {
      'date': date,
      'amount': amount,
    };

    _repayments.add(newRepayment);
    final newOutstanding = _originalAmount - _repayments.fold(0.0, (sum, r) => sum + r['amount']);

    final updatedRepaymentData = _repayments
        .map((r) => '${r['date'].millisecondsSinceEpoch}:${r['amount']}')
        .join('|');

    final updatedLoan = _currentLoan.copyWith(
      amount: newOutstanding.clamp(0.0, double.infinity),
      status: newOutstanding <= 0 ? 'Completed' : 'Active',
      additionalData: {
        ..._currentLoan.additionalData!,
        'outstanding_amount': newOutstanding.toString(),
        'repayments': updatedRepaymentData,
      },
    );

    try {
      await _databaseService.updateInvestment(updatedLoan);
      setState(() {
        _currentLoan = updatedLoan;
        _loadRepayments();
        _repaymentController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repayment recorded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteRepayment(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repayment'),
        content: const Text('Are you sure you want to delete this repayment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _repayments.removeAt(index);
      
      final newOutstanding = _originalAmount - _repayments.fold(0.0, (sum, r) => sum + r['amount']);
      final updatedRepaymentData = _repayments
          .map((r) => '${r['date'].millisecondsSinceEpoch}:${r['amount']}')
          .join('|');

      final updatedLoan = _currentLoan.copyWith(
        amount: newOutstanding.clamp(0.0, double.infinity),
        status: newOutstanding <= 0 ? 'Completed' : 'Active',
        additionalData: {
          ..._currentLoan.additionalData!,
          'outstanding_amount': newOutstanding.toString(),
          'repayments': updatedRepaymentData,
        },
      );

      try {
        await _databaseService.updateInvestment(updatedLoan);
        setState(() {
          _currentLoan = updatedLoan;
          _loadRepayments();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showEditDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  @override
  void dispose() {
    _repaymentController.dispose();
    super.dispose();
  }
}

class _RepaymentDialog extends StatefulWidget {
  final double outstandingAmount;
  final double? prefilledAmount;
  final Function(double, DateTime) onRepaymentRecorded;

  const _RepaymentDialog({
    required this.outstandingAmount,
    this.prefilledAmount,
    required this.onRepaymentRecorded,
  });

  @override
  State<_RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends State<_RepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _repaymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Repayment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Repayment Amount',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Required';
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) return 'Invalid amount';
                if (amount > widget.outstandingAmount) {
                  return 'Cannot exceed outstanding balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectRepaymentDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Repayment Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_repaymentDate.day.toString().padLeft(2, '0')}/${_repaymentDate.month.toString().padLeft(2, '0')}/${_repaymentDate.year}',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _recordRepayment,
          child: const Text('Record'),
        ),
      ],
    );
  }

  Future<void> _selectRepaymentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _repaymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _repaymentDate = date);
    }
  }

  void _recordRepayment() {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.parse(_amountController.text);
    widget.onRepaymentRecorded(amount, _repaymentDate);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}