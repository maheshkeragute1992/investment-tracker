import 'package:intl/intl.dart';
import 'constants.dart';

class DateHelpers {
  static final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);
  static final DateFormat _dateTimeFormat = DateFormat(AppConstants.dateTimeFormat);
  
  // Format date to Indian format (DD/MM/YYYY)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  // Format datetime to Indian format
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  // Parse date from string
  static DateTime? parseDate(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  // Calculate days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  // Calculate years between two dates
  static double yearsBetween(DateTime from, DateTime to) {
    return daysBetween(from, to) / 365.25;
  }
  
  // Calculate months between two dates
  static int monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }
  
  // Add months to a date
  static DateTime addMonths(DateTime date, int months) {
    int newMonth = date.month + months;
    int newYear = date.year;
    
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    
    return DateTime(newYear, newMonth, date.day);
  }
  
  // Add years to a date
  static DateTime addYears(DateTime date, int years) {
    return DateTime(date.year + years, date.month, date.day);
  }
  
  // Check if date is within notification range
  static bool isWithinNotificationRange(DateTime maturityDate, int daysBefore) {
    final now = DateTime.now();
    final notificationDate = maturityDate.subtract(Duration(days: daysBefore));
    return now.isAfter(notificationDate) && now.isBefore(maturityDate);
  }
  
  // Get financial year from date
  static String getFinancialYear(DateTime date) {
    if (date.month >= 4) {
      return '${date.year}-${(date.year + 1).toString().substring(2)}';
    } else {
      return '${date.year - 1}-${date.year.toString().substring(2)}';
    }
  }
  
  // Format currency in Indian format (Lakhs/Crores)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );
    
    if (amount >= 10000000) { // 1 Crore
      return '${AppConstants.currencySymbol}${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) { // 1 Lakh
      return '${AppConstants.currencySymbol}${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return formatter.format(amount);
    }
  }
  
  // Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(2)}%';
  }
}