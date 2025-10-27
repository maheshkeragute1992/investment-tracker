import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/investment.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/refresh_notifier.dart';

class AddInvestmentScreen extends StatefulWidget {
  final Investment? investment;
  final VoidCallback? onInvestmentAdded;

  const AddInvestmentScreen({super.key, this.investment, this.onInvestmentAdded});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _friendNameController = TextEditingController();
  
  String _selectedType = AppConstants.fixedDeposit;
  DateTime _startDate = DateTime.now();
  DateTime? _maturityDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setDefaultMaturityDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Investment'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Investment Type',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.investmentTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? AppConstants.fixedDeposit;
                    _setDefaultMaturityDate();
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Investment Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter investment name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Investment Start Date
              InkWell(
                onTap: () => _selectStartDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Investment Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Maturity Date (optional)
              InkWell(
                onTap: () => _selectMaturityDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Maturity Date (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _maturityDate != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => setState(() => _maturityDate = null),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          )
                        : const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _maturityDate != null
                        ? '${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}'
                        : 'Select maturity date',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _maturityDate != null 
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Interest Rate
              TextFormField(
                controller: _interestRateController,
                decoration: InputDecoration(
                  labelText: _isInterestRateRequired() 
                      ? 'Interest Rate *' 
                      : 'Interest Rate (Optional)',
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                  helperText: _getInterestRateHelperText(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_isInterestRateRequired()) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Interest rate is required for ${_selectedType}';
                    }
                  }
                  if (value != null && value.trim().isNotEmpty) {
                    final rate = double.tryParse(value);
                    if (rate == null || rate < 0 || rate > 100) {
                      return 'Please enter a valid interest rate (0-100)';
                    }
                  }
                  return null;
                },
              ),
              
              // Investment Type Specific Fields
              if (_selectedType == AppConstants.fixedDeposit) ..._buildFDFields(),
              if (_selectedType == AppConstants.sip) ..._buildSIPFields(),
              if (_selectedType == AppConstants.ppf) ..._buildPPFFields(),
              if (_selectedType == AppConstants.recurringDeposit) ..._buildRDFields(),
              if (_selectedType == AppConstants.sgb) ..._buildSGBFields(),
              if (_selectedType == AppConstants.nps) ..._buildNPSFields(),
              if (_selectedType == AppConstants.loanToFriend) ..._buildLoanFields(),
              
              // Calculation Preview
              if (_shouldShowCalculation()) _buildCalculationPreview(),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveInvestment,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add Investment'),
                ),
              ),
              const SizedBox(height: 120), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final interestRate = _interestRateController.text.trim().isNotEmpty
          ? double.parse(_interestRateController.text)
          : null;
      
      final investment = Investment(
        type: _selectedType,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        startDate: _startDate,
        maturityDate: _maturityDate,
        interestRate: interestRate,
        additionalData: _selectedType == AppConstants.loanToFriend ? {
          'friend_name': _friendNameController.text.trim(),
          'original_amount': _amountController.text,
          'outstanding_amount': _amountController.text,
          'repayments': '',
        } : null,
      );

      final result = await _databaseService.insertInvestment(investment);
      print('Investment added with ID: $result');
      print('Investment details: ${investment.name} - ${investment.type} - ${investment.amount}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment added successfully')),
        );
        // Clear the form
        _nameController.clear();
        _amountController.clear();
        _interestRateController.clear();
        _friendNameController.clear();
        // Notify about data change
        RefreshNotifier().notifyDataChanged();
        widget.onInvestmentAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Investment Date',
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Reset maturity date if it's before start date
        if (_maturityDate != null && _maturityDate!.isBefore(_startDate)) {
          _maturityDate = null;
        }
      });
    }
  }

  Future<void> _selectMaturityDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _maturityDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime(2050),
      helpText: 'Select Maturity Date',
    );
    if (picked != null) {
      setState(() {
        _maturityDate = picked;
      });
    }
  }

  List<Widget> _buildFDFields() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.fdColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.fdColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.fdColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Fixed Deposits offer guaranteed returns. Interest rate is crucial for accurate maturity calculation.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSIPFields() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.sipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.sipColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.sipColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'SIP investments are ongoing. Enter total invested amount so far.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPPFFields() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.ppfColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.ppfColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.ppfColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'PPF: 15-year lock-in, tax-free returns. Current rate: 7.1% p.a. (compounded annually).',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildRDFields() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.rdColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.rdColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.rdColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'RD: Monthly deposits with guaranteed returns. Interest rate needed for maturity calculation.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSGBFields() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.sgbColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.sgbColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.sgbColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'SGB: 8-year tenure, 2.5% p.a. interest + gold price appreciation. Tax-free on maturity.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildNPSFields() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.npsColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.npsColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.npsColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'NPS: Retirement savings with tax benefits. Expected returns: 8-12% p.a. based on fund choice.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _setDefaultMaturityDate() {
    switch (_selectedType) {
      case AppConstants.fixedDeposit:
        _maturityDate = _startDate.add(const Duration(days: 365)); // 1 year
        _interestRateController.text = '6.5'; // Typical FD rate
        break;
      case AppConstants.recurringDeposit:
        _maturityDate = _startDate.add(const Duration(days: 365)); // 1 year
        _interestRateController.text = '6.0'; // Typical RD rate
        break;
      case AppConstants.ppf:
        _maturityDate = _startDate.add(const Duration(days: 365 * 15)); // 15 years
        _interestRateController.text = '7.1'; // Current PPF rate
        break;
      case AppConstants.sgb:
        _maturityDate = _startDate.add(const Duration(days: 365 * 8)); // 8 years
        _interestRateController.text = '2.5'; // SGB interest rate
        break;
      case AppConstants.nps:
        _maturityDate = null; // No fixed maturity
        _interestRateController.text = '10.0'; // Expected returns
        break;
      case AppConstants.sip:
        _maturityDate = null; // No fixed maturity
        _interestRateController.text = '12.0'; // Expected returns
        break;
      case AppConstants.loanToFriend:
        _maturityDate = null; // No fixed maturity
        _interestRateController.text = '12.0'; // Monthly interest rate
        break;
      default:
        _maturityDate = null;
        _interestRateController.clear();
    }
  }

  bool _isInterestRateRequired() {
    return [
      AppConstants.fixedDeposit,
      AppConstants.recurringDeposit,
      AppConstants.ppf,
      AppConstants.sgb,
    ].contains(_selectedType);
  }

  String _getInterestRateHelperText() {
    switch (_selectedType) {
      case AppConstants.fixedDeposit:
        return 'Current FD rates: 6.0% - 7.5% p.a.';
      case AppConstants.recurringDeposit:
        return 'Current RD rates: 5.5% - 7.0% p.a.';
      case AppConstants.ppf:
        return 'Current PPF rate: 7.1% p.a. (Govt. rate)';
      case AppConstants.sgb:
        return 'SGB interest: 2.5% p.a. + gold price appreciation';
      case AppConstants.nps:
        return 'Expected returns: 8% - 12% p.a.';
      case AppConstants.sip:
        return 'Expected returns: 10% - 15% p.a.';
      case AppConstants.loanToFriend:
        return 'Monthly interest rate: 1% - 3% per month';
      default:
        return 'Annual interest/return rate';
    }
  }

  bool _shouldShowCalculation() {
    return _amountController.text.isNotEmpty &&
           _interestRateController.text.isNotEmpty &&
           _maturityDate != null &&
           double.tryParse(_amountController.text) != null &&
           double.tryParse(_interestRateController.text) != null;
  }

  Widget _buildCalculationPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = double.tryParse(_interestRateController.text) ?? 0;
    
    if (amount <= 0 || rate <= 0 || _maturityDate == null) {
      return const SizedBox.shrink();
    }

    final years = _maturityDate!.difference(_startDate).inDays / 365.25;
    double maturityValue = 0;
    String calculationType = '';

    switch (_selectedType) {
      case AppConstants.fixedDeposit:
        // Compound Interest: A = P(1 + r/100)^t
        maturityValue = amount * math.pow(1 + (rate / 100), years);
        calculationType = 'FD Maturity Value';
        break;
      case AppConstants.recurringDeposit:
        // RD calculation: Monthly deposits compounded
        final monthlyRate = rate / 1200; // Monthly rate
        final months = years * 12;
        final monthlyAmount = amount / months; // Assuming equal monthly deposits
        maturityValue = monthlyAmount * ((math.pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);
        calculationType = 'RD Maturity Value';
        break;
      case AppConstants.ppf:
        // PPF calculation (annual compounding)
        maturityValue = amount * math.pow(1 + (rate / 100), years);
        calculationType = 'PPF Maturity (Tax-Free)';
        break;
      case AppConstants.sgb:
        // SGB: Interest + potential gold appreciation
        final interestValue = amount * math.pow(1 + (rate / 100), years);
        maturityValue = interestValue; // Not including gold price appreciation
        calculationType = 'SGB Interest Only';
        break;
      case AppConstants.nps:
      case AppConstants.sip:
        // Market-linked returns
        maturityValue = amount * math.pow(1 + (rate / 100), years);
        calculationType = 'Projected Value';
        break;
      default:
        maturityValue = amount * math.pow(1 + (rate / 100), years);
        calculationType = 'Estimated Value';
    }

    final returns = maturityValue - amount;
    final returnPercentage = (returns / amount) * 100;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                calculationType,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invested', style: TextStyle(fontSize: 11)),
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Maturity', style: TextStyle(fontSize: 11)),
                        Text(
                          '₹${maturityValue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Returns', style: TextStyle(fontSize: 11)),
                        Text(
                          '₹${returns.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: ${years.toStringAsFixed(1)} years • Return: ${returnPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
            ),
          ),
          if (_selectedType == AppConstants.sgb)
            const Text(
              'Note: Excludes gold price appreciation',
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            ),
          if ([AppConstants.sip, AppConstants.nps].contains(_selectedType))
            const Text(
              'Note: Market-linked returns may vary',
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildLoanFields() {
    return [
      const SizedBox(height: 16),
      TextFormField(
        controller: _friendNameController,
        decoration: const InputDecoration(
          labelText: 'Friend Name *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter friend name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.loanColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.loanColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.loanColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Track money lent to friends. Interest rate is monthly. You can record repayments later.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _friendNameController.dispose();
    super.dispose();
  }
}