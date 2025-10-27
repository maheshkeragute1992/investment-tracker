import 'dart:math';
import '../models/investment.dart';
import '../utils/date_helpers.dart';
import '../utils/constants.dart';

class CalculationService {
  // Fixed Deposit Maturity Calculation
  // Formula: A = P(1 + r/n)^(nt)
  static double calculateFDMaturity({
    required double principal,
    required double interestRate,
    required DateTime startDate,
    required DateTime maturityDate,
    int compoundingFrequency = 4, // Quarterly compounding
  }) {
    final years = DateHelpers.yearsBetween(startDate, maturityDate);
    final rate = interestRate / 100;
    final n = compoundingFrequency;
    
    return principal * pow(1 + rate / n, n * years);
  }

  // Recurring Deposit Maturity Calculation
  // Formula: M = P × [(1 + r/n)^(nt) - 1] / (r/n) × (1 + r/n)
  static double calculateRDMaturity({
    required double monthlyAmount,
    required double interestRate,
    required int tenureMonths,
    int compoundingFrequency = 4, // Quarterly compounding
  }) {
    final rate = interestRate / 100;
    final n = compoundingFrequency;
    final t = tenureMonths / 12.0; // Convert months to years
    
    final ratePerPeriod = rate / n;
    final totalPeriods = n * t;
    
    return monthlyAmount * 12 * 
           ((pow(1 + ratePerPeriod, totalPeriods) - 1) / ratePerPeriod) * 
           (1 + ratePerPeriod);
  }

  // SIP Future Value Calculation
  // Formula: FV = PMT × [((1 + r)^n - 1) / r] × (1 + r)
  static double calculateSIPFutureValue({
    required double monthlyAmount,
    required double expectedReturn,
    required int months,
  }) {
    final monthlyRate = expectedReturn / 100 / 12;
    
    if (monthlyRate == 0) {
      return monthlyAmount * months;
    }
    
    return monthlyAmount * 
           ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * 
           (1 + monthlyRate);
  }

  // PPF Maturity Calculation
  // 15-year lock-in with annual compounding
  static double calculatePPFMaturity({
    required double annualContribution,
    required int years,
    double interestRate = AppConstants.ppfInterestRate,
  }) {
    final rate = interestRate / 100;
    double maturityAmount = 0;
    
    // Calculate year by year as contributions are made at the beginning of each year
    for (int i = 0; i < years; i++) {
      final yearsRemaining = years - i;
      maturityAmount += annualContribution * pow(1 + rate, yearsRemaining);
    }
    
    return maturityAmount;
  }

  // NPS Expected Corpus Calculation
  // Assumes 60% equity, 40% debt allocation
  static double calculateNPSCorpus({
    required double monthlyContribution,
    required int ageAtStart,
    required int retirementAge,
    double equityReturn = 12.0, // Expected equity return
    double debtReturn = 8.0,    // Expected debt return
    double equityAllocation = 0.6,
  }) {
    final years = retirementAge - ageAtStart;
    final months = years * 12;
    
    // Blended return rate
    final blendedReturn = (equityReturn * equityAllocation) + 
                         (debtReturn * (1 - equityAllocation));
    
    return calculateSIPFutureValue(
      monthlyAmount: monthlyContribution,
      expectedReturn: blendedReturn,
      months: months,
    );
  }

  // CAGR Calculation
  // Formula: [(Ending Value / Beginning Value)^(1/years)] - 1
  static double calculateCAGR({
    required double beginningValue,
    required double endingValue,
    required double years,
  }) {
    if (beginningValue <= 0 || endingValue <= 0 || years <= 0) {
      return 0.0;
    }
    
    return (pow(endingValue / beginningValue, 1 / years) - 1) * 100;
  }

  // Simple Interest Calculation
  static double calculateSimpleInterest({
    required double principal,
    required double rate,
    required double time,
  }) {
    return (principal * rate * time) / 100;
  }

  // Compound Interest Calculation
  static double calculateCompoundInterest({
    required double principal,
    required double rate,
    required double time,
    int compoundingFrequency = 1,
  }) {
    final r = rate / 100;
    final n = compoundingFrequency;
    return principal * pow(1 + r / n, n * time) - principal;
  }

  // EMI Calculation for loans
  static double calculateEMI({
    required double principal,
    required double rate,
    required int tenureMonths,
  }) {
    final monthlyRate = rate / 100 / 12;
    
    if (monthlyRate == 0) {
      return principal / tenureMonths;
    }
    
    return principal * 
           (monthlyRate * pow(1 + monthlyRate, tenureMonths)) / 
           (pow(1 + monthlyRate, tenureMonths) - 1);
  }

  // Calculate current value of investment based on type
  static double calculateCurrentValue(Investment investment) {
    final now = DateTime.now();
    
    switch (investment.type) {
      case AppConstants.fixedDeposit:
        if (investment.maturityDate != null && investment.interestRate != null) {
          final elapsed = DateHelpers.yearsBetween(investment.startDate, now);
          final total = DateHelpers.yearsBetween(investment.startDate, investment.maturityDate!);
          
          if (elapsed >= total) {
            return calculateFDMaturity(
              principal: investment.amount,
              interestRate: investment.interestRate!,
              startDate: investment.startDate,
              maturityDate: investment.maturityDate!,
            );
          } else {
            return calculateFDMaturity(
              principal: investment.amount,
              interestRate: investment.interestRate!,
              startDate: investment.startDate,
              maturityDate: now,
            );
          }
        }
        break;
        
      case AppConstants.recurringDeposit:
        if (investment.additionalData != null && investment.interestRate != null) {
          final monthlyAmount = double.tryParse(
            investment.additionalData!['monthly_amount'] ?? '0'
          ) ?? 0;
          final tenureMonths = int.tryParse(
            investment.additionalData!['tenure_months'] ?? '0'
          ) ?? 0;
          
          final elapsedMonths = DateHelpers.monthsBetween(investment.startDate, now);
          final completedMonths = elapsedMonths.clamp(0, tenureMonths);
          
          if (completedMonths > 0) {
            return calculateRDMaturity(
              monthlyAmount: monthlyAmount,
              interestRate: investment.interestRate!,
              tenureMonths: completedMonths,
            );
          }
        }
        break;
        
      case AppConstants.sip:
        if (investment.additionalData != null) {
          final monthlyAmount = double.tryParse(
            investment.additionalData!['monthly_amount'] ?? '0'
          ) ?? 0;
          final elapsedMonths = DateHelpers.monthsBetween(investment.startDate, now);
          
          // Assume 12% annual return for SIP if not specified
          return calculateSIPFutureValue(
            monthlyAmount: monthlyAmount,
            expectedReturn: 12.0,
            months: elapsedMonths,
          );
        }
        break;
        
      case AppConstants.ppf:
        if (investment.additionalData != null) {
          final annualContribution = double.tryParse(
            investment.additionalData!['annual_contribution'] ?? '0'
          ) ?? 0;
          final elapsedYears = DateHelpers.yearsBetween(investment.startDate, now).floor();
          
          return calculatePPFMaturity(
            annualContribution: annualContribution,
            years: elapsedYears.clamp(1, 15),
          );
        }
        break;
    }
    
    return investment.amount; // Return principal if calculation not possible
  }

  // Calculate projected maturity value
  static double calculateProjectedMaturity(Investment investment) {
    switch (investment.type) {
      case AppConstants.fixedDeposit:
        if (investment.maturityDate != null && investment.interestRate != null) {
          return calculateFDMaturity(
            principal: investment.amount,
            interestRate: investment.interestRate!,
            startDate: investment.startDate,
            maturityDate: investment.maturityDate!,
          );
        }
        break;
        
      case AppConstants.recurringDeposit:
        if (investment.additionalData != null && investment.interestRate != null) {
          final monthlyAmount = double.tryParse(
            investment.additionalData!['monthly_amount'] ?? '0'
          ) ?? 0;
          final tenureMonths = int.tryParse(
            investment.additionalData!['tenure_months'] ?? '0'
          ) ?? 0;
          
          return calculateRDMaturity(
            monthlyAmount: monthlyAmount,
            interestRate: investment.interestRate!,
            tenureMonths: tenureMonths,
          );
        }
        break;
        
      case AppConstants.ppf:
        if (investment.additionalData != null) {
          final annualContribution = double.tryParse(
            investment.additionalData!['annual_contribution'] ?? '0'
          ) ?? 0;
          
          return calculatePPFMaturity(
            annualContribution: annualContribution,
            years: AppConstants.ppfTenure,
          );
        }
        break;
    }
    
    return investment.amount;
  }

  // Calculate total returns
  static double calculateTotalReturns(Investment investment) {
    return calculateCurrentValue(investment) - investment.amount;
  }

  // Calculate annualized return percentage
  static double calculateAnnualizedReturn(Investment investment) {
    final currentValue = calculateCurrentValue(investment);
    final years = DateHelpers.yearsBetween(investment.startDate, DateTime.now());
    
    if (years <= 0) return 0.0;
    
    return calculateCAGR(
      beginningValue: investment.amount,
      endingValue: currentValue,
      years: years,
    );
  }
}